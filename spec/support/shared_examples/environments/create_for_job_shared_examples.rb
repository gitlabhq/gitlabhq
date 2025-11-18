# frozen_string_literal: true

RSpec.shared_examples 'create environment for job' do
  let!(:job) { build(factory_type, project: project, pipeline: pipeline, user: user, **attributes) }
  let(:merge_request) {} # rubocop:disable Lint/EmptyBlock

  describe '#execute' do
    subject { service.execute(job) }

    shared_examples_for 'returning a correct environment' do
      let(:expected_auto_stop_in_seconds) do
        ChronicDuration.parse(expected_auto_stop_in).seconds if expected_auto_stop_in
      end

      it 'returns a persisted environment object' do
        freeze_time do
          expect { subject }.to change { Environment.count }.by(1)

          expect(subject).to be_a(Environment)
          expect(subject).to be_persisted
          expect(subject.project).to eq(project)
          expect(subject.name).to eq(expected_environment_name)
          expect(subject.auto_stop_in).to eq(expected_auto_stop_in_seconds)
        end
      end

      it 'creates an associated job environment record' do
        subject

        job.save!

        expect(job.job_environment).to be_valid
        expect(job.job_environment).to have_attributes(
          project: project,
          environment: instance_of(Environment),
          pipeline: job.pipeline,
          expanded_environment_name: job.persisted_environment.name,
          options: job.environment_options_for_permanent_storage
        )
      end

      context 'when environment has already existed' do
        let!(:environment) do
          create(:environment,
            project: project,
            name: expected_environment_name
          ).tap do |env|
            env.auto_stop_in = expected_auto_stop_in
          end
        end

        it 'returns the existing environment object' do
          expect { subject }.not_to change { Environment.count }
          expect { subject }.not_to change { environment.auto_stop_at }

          expect(subject).to be_persisted
          expect(subject).to eq(environment)
        end

        it 'creates an associated job environment record' do
          subject

          job.save!

          expect(job.job_environment).to be_valid
          expect(job.job_environment).to have_attributes(
            project: project,
            environment: environment,
            pipeline: job.pipeline,
            expanded_environment_name: environment.name,
            options: job.environment_options_for_permanent_storage
          )
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { 'create_job_with_environment' }
          let(:category) { described_class.name }
          let(:additional_properties) do
            { label: job.environment_action, value: environment.id, property: environment.tier }
          end
        end
      end
    end

    context 'when job has environment name attribute' do
      let(:environment_name) { 'production' }
      let(:expected_environment_name) { 'production' }
      let(:expected_auto_stop_in) { nil }

      let(:attributes) do
        {
          environment: environment_name,
          options: { environment: { name: environment_name } }
        }
      end

      it_behaves_like 'returning a correct environment'

      context 'and job environment also has an auto_stop_in attribute' do
        let(:environment_auto_stop_in) { '5 minutes' }
        let(:expected_auto_stop_in) { '5 minutes' }

        let(:attributes) do
          {
            environment: environment_name,
            options: {
              environment: {
                name: environment_name,
                auto_stop_in: environment_auto_stop_in
              }
            }
          }
        end

        it_behaves_like 'returning a correct environment'
      end

      context 'and job environment has an auto_stop_in variable attribute' do
        let(:environment_auto_stop_in) { '10 minutes' }
        let(:expected_auto_stop_in) { '10 minutes' }

        let(:attributes) do
          {
            environment: environment_name,
            options: {
              environment: {
                name: environment_name,
                auto_stop_in: '$TTL'
              }
            },
            yaml_variables: [
              { key: "TTL", value: environment_auto_stop_in, public: true }
            ]
          }
        end

        it_behaves_like 'returning a correct environment'
      end
    end

    context 'when job has deployment tier attribute' do
      let(:attributes) do
        {
          environment: environment_name,
          options: {
            environment: {
              name: environment_name,
              deployment_tier: deployment_tier
            }
          }
        }
      end

      let(:environment_name) { 'customer-portal' }
      let(:deployment_tier) { 'production' }

      context 'when environment has not been created yet' do
        it 'sets the specified deployment tier' do
          is_expected.to be_production
        end

        context 'when deployment tier is staging' do
          let(:deployment_tier) { 'staging' }

          it 'sets the specified deployment tier' do
            is_expected.to be_staging
          end
        end

        context 'when deployment tier is unknown' do
          let(:deployment_tier) { 'unknown' }

          it "is not a valid tier" do
            is_expected.not_to be_valid
            expect(subject.errors[:tier].first).to eq('is not included in the list')
          end
        end
      end

      context 'when environment has already been created' do
        before do
          create(:environment, project: project, name: 'customer-portal', tier: :staging)
        end

        it 'does not overwrite the specified deployment tier' do
          # This is to be updated when a deployment succeeded i.e. Deployments::UpdateEnvironmentService.
          is_expected.to be_staging
        end
      end
    end

    context 'when job has a cluster agent attribute' do
      let_it_be(:agent) { create(:cluster_agent, project: project) }

      let(:environment_name) { 'production' }
      let(:expected_environment_name) { 'production' }
      let(:expected_auto_stop_in) { nil }
      let(:agent_path) { "#{project.full_path}:#{agent.name}" }
      let(:attributes) do
        {
          environment: environment_name,
          options: {
            environment: {
              name: environment_name,
              kubernetes: {
                agent: agent_path,
                namespace: 'example-namespace'
              }
            }
          }
        }
      end

      let(:authorizations) { [ci_access_authorization] }
      let(:ci_access_authorization) do
        create(:agent_ci_access_project_authorization,
          resource_management_enabled: true,
          project: project,
          agent: agent
        )
      end

      before do
        allow_next_instance_of(Clusters::Agents::Authorizations::CiAccess::Finder, project) do |finder|
          allow(finder).to receive(:execute).and_return(authorizations)
        end
      end

      it_behaves_like 'returning a correct environment'

      context 'when the agent has resource management enabled' do
        before do
          allow(agent).to receive(:resource_management_enabled?).and_return(true)
        end

        it 'creates an environment with the specified cluster agent' do
          expect { subject }.to change { Environment.count }.by(1)

          expect(subject).to be_a(Environment)
          expect(subject).to be_persisted
          expect(subject.cluster_agent).to eq(agent)
        end

        context 'when the agent is not configured for resource_management' do
          let(:ci_access_authorization) do
            create(:agent_ci_access_project_authorization,
              project: project,
              agent: agent,
              config: {} # resource_management is not enabled
            )
          end

          it 'creates an environment without the specified cluster agent' do
            expect { subject }.to change { Environment.count }.by(1)

            expect(subject).to be_a(Environment)
            expect(subject).to be_persisted
            expect(subject.cluster_agent).to be_nil
          end
        end

        context 'when the agent is not authorized for this project' do
          let(:authorizations) { [] }

          it 'creates an environment without the specified cluster agent' do
            expect { subject }.to change { Environment.count }.by(1)

            expect(subject).to be_a(Environment)
            expect(subject).to be_persisted
            expect(subject.cluster_agent).to be_nil
          end
        end

        context 'when the environment already exists' do
          context 'when the environment does not have a cluster agent' do
            let(:environment) { create(:environment, project: project, name: environment_name) }

            it 'updates the environment with the specified cluster agent' do
              expect { subject }.to change { environment.reload.cluster_agent }.from(nil).to(agent)
            end
          end

          context 'when the environment has a associated cluster agent' do
            let_it_be(:another_agent) { create(:cluster_agent, project: project) }
            let(:environment) do
              create(:environment, project: project, name: environment_name, cluster_agent: another_agent)
            end

            it 'does not update the environment' do
              expect { subject }.not_to change { environment.reload.cluster_agent }
            end
          end
        end
      end

      context 'when the agent does not have resource management enabled' do
        before do
          allow(agent).to receive(:resource_management_enabled).and_return(false)
        end

        it 'creates an environment without the specified cluster agent' do
          expect { subject }.to change { Environment.count }.by(1)

          expect(subject).to be_a(Environment)
          expect(subject).to be_persisted
          expect(subject.cluster_agent).to be_nil
        end
      end
    end

    context 'when job starts a review app' do
      let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }
      let(:expected_environment_name) { "review/#{job.ref}" }
      let(:expected_auto_stop_in) { nil }

      let(:attributes) do
        {
          environment: environment_name,
          options: { environment: { name: environment_name } }
        }
      end

      it_behaves_like 'returning a correct environment'
    end

    context 'when job stops a review app' do
      let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }
      let(:expected_environment_name) { "review/#{job.ref}" }
      let(:expected_auto_stop_in) { nil }

      let(:attributes) do
        {
          environment: environment_name,
          options: { environment: { name: environment_name, action: 'stop' } }
        }
      end

      it_behaves_like 'returning a correct environment'
    end

    context 'when merge_request is provided' do
      let(:pipeline) { create(:ci_pipeline, project: project, merge_request: merge_request) }
      let(:environment_name) { 'development' }
      let(:attributes) { { environment: environment_name, options: { environment: { name: environment_name } } } }
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:seed) { described_class.new(job) }

      context 'and environment does not exist' do
        let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }

        it 'creates an environment associated with the merge request' do
          expect { subject }.to change { Environment.count }.by(1)

          expect(subject.merge_request).to eq(merge_request)
        end
      end

      context 'and environment already exists' do
        before do
          create(:environment, project: project, name: environment_name)
        end

        it 'does not change the merge request associated with the environment' do
          expect { subject }.not_to change { Environment.count }

          expect(subject.merge_request).to be_nil
        end
      end
    end

    context 'when a pipeline contains a deployment job' do
      let(:pipeline) { create(:ci_pipeline, project: project, merge_request: merge_request) }
      let!(:job) { build(factory_type, :start_review_app, project: project, pipeline: pipeline) }

      context 'and the environment does not exist' do
        it 'creates the environment specified by the job' do
          expect { subject }.to change { Environment.count }.by(1)

          expect(environment).to be_present
          expect(job.persisted_environment.name).to eq('review/master')
          expect(job.expanded_environment_name).to eq('review/master')
        end

        context 'and the pipeline is for a merge request' do
          let(:merge_request) { create(:merge_request, source_project: project) }

          it 'associates the environment with the merge request' do
            expect { subject }.to change { Environment.count }.by(1)

            expect(environment.merge_request).to eq(merge_request)
          end
        end
      end

      context 'when an environment already exists' do
        before do
          create(:environment, project: project, name: 'review/master')
        end

        it 'ensures environment existence for the job' do
          expect { subject }.not_to change { Environment.count }

          expect(environment).to be_present
          expect(job.persisted_environment.name).to eq('review/master')
          expect(job.expanded_environment_name).to eq('review/master')
        end

        context 'and the pipeline is for a merge request' do
          let(:merge_request) { create(:merge_request, source_project: project) }

          it 'does not associate the environment with the merge request' do
            expect { subject }.not_to change { Environment.count }

            expect(environment.merge_request).to be_nil
          end
        end
      end

      context 'when an environment name contains an invalid character' do
        before do
          job.pipeline = build(:ci_pipeline, ref: '!!!', project: project)
        end

        it 'sets the failure status' do
          expect { subject }.not_to change { Environment.count }

          expect(job).to be_failed
          expect(job).to be_environment_creation_failure
          expect(job.persisted_environment).to be_nil
        end
      end
    end

    context 'when a pipeline contains a teardown job' do
      let!(:job) { build(factory_type, :stop_review_app, project: project) }

      it 'ensures environment existence for the job' do
        expect { subject }.to change { Environment.count }.by(1)

        expect(environment).to be_present
        expect(job.persisted_environment.name).to eq('review/master')
        expect(job.expanded_environment_name).to eq('review/master')
      end

      context 'when job metadata exists' do
        before do
          job.metadata = build(:ci_build_metadata, project: project)
        end

        it 'does not change metadata.expanded_environment_name' do
          expect { subject }.to not_change { job.metadata.expanded_environment_name }
        end
      end
    end

    context 'when a pipeline does not contain a deployment job' do
      let!(:job) { build(factory_type, project: project) }

      it 'does not create any environments' do
        expect { subject }.not_to change { Environment.count }
      end
    end

    def environment
      project.environments.find_by_name('review/master')
    end
  end
end
