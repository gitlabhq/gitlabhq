# frozen_string_literal: true

RSpec.shared_examples 'create deployment for job' do
  describe '#execute' do
    subject { service.execute(job) }

    context 'with a deployment job' do
      let!(:job) { create(factory_type, :start_review_app, project: project) }
      let!(:environment) { create(:environment, project: project, name: job.expanded_environment_name) }

      it 'creates a deployment record' do
        expect { subject }.to change { Deployment.count }.by(1)

        job.reset
        expect(job.deployment.project).to eq(job.project)
        expect(job.deployment.ref).to eq(job.ref)
        expect(job.deployment.sha).to eq(job.sha)
        expect(job.deployment.deployable).to eq(job)
        expect(job.deployment.deployable_type).to eq('CommitStatus')
        expect(job.deployment.environment).to eq(job.persisted_environment)
        expect(job.deployment.valid?).to be_truthy
      end

      context 'when creation failure occures' do
        before do
          allow_next_instance_of(Deployment) do |deployment|
            allow(deployment).to receive(:save!) { raise ActiveRecord::RecordInvalid }
          end
        end

        it 'trackes the exception' do
          expect { subject }.to raise_error(described_class::DeploymentCreationError)

          expect(Deployment.count).to eq(0)
        end
      end

      context 'when the corresponding environment does not exist' do
        let!(:environment) {} # rubocop:disable Lint/EmptyBlock

        it 'does not create a deployment record' do
          expect { subject }.not_to change { Deployment.count }

          expect(job.deployment).to be_nil
        end
      end
    end

    context 'with a teardown job' do
      let!(:job) { create(factory_type, :stop_review_app, project: project) }
      let!(:environment) { create(:environment, name: job.expanded_environment_name) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(job.deployment).to be_nil
      end
    end

    context 'with a normal job' do
      let!(:job) { create(factory_type, project: project) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(job.deployment).to be_nil
      end
    end

    context 'when job has environment attribute' do
      let!(:job) do
        create(factory_type, environment: 'production', project: project,
                          options: { environment: { name: 'production', **kubernetes_options } }) # rubocop:disable Layout/ArgumentAlignment
      end

      let!(:environment) { create(:environment, project: project, name: job.expanded_environment_name) }

      let(:kubernetes_options) { {} }

      it 'returns a deployment object with environment' do
        expect(subject).to be_a(Deployment)
        expect(subject.iid).to be_present
        expect(subject.environment.name).to eq('production')
        expect(subject.cluster).to be_nil
        expect(subject.deployment_cluster).to be_nil
      end

      context 'when environment has deployment platform' do
        let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project], managed: managed_cluster) }
        let(:managed_cluster) { true }

        it 'sets the cluster and deployment_cluster' do
          expect(subject.cluster).to eq(cluster) # until we stop double writing in 12.9: https://gitlab.com/gitlab-org/gitlab/issues/202628
          expect(subject.deployment_cluster.cluster).to eq(cluster)
        end

        context 'when a custom namespace is given' do
          let(:kubernetes_options) { { kubernetes: { namespace: 'the-custom-namespace' } } }

          context 'when cluster is managed' do
            it 'does not set the custom namespace' do
              expect(subject.deployment_cluster.kubernetes_namespace).not_to eq('the-custom-namespace')
            end
          end

          context 'when cluster is not managed' do
            let(:managed_cluster) { false }

            it 'sets the custom namespace' do
              expect(subject.deployment_cluster.kubernetes_namespace).to eq('the-custom-namespace')
            end
          end
        end
      end

      context 'when job already has deployment' do
        let!(:job) { create(factory_type, :with_deployment, project: project, environment: 'production') }
        let!(:environment) {} # rubocop:disable Lint/EmptyBlock

        it 'returns the persisted deployment' do
          expect { subject }.not_to change { Deployment.count }

          is_expected.to eq(job.deployment)
        end
      end
    end

    context 'when job does not start environment' do
      where(:action) do
        %w[stop prepare verify access]
      end

      with_them do
        let!(:job) do
          create(factory_type, environment: 'production', project: project,
                            options: { environment: { name: 'production', action: action } }) # rubocop:disable Layout/ArgumentAlignment
        end

        it 'returns nothing' do
          is_expected.to be_nil
        end
      end
    end

    context 'when job does not have environment attribute' do
      let!(:job) { create(factory_type, project: project) }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end
end
