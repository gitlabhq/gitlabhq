require 'spec_helper'

describe CreateDeploymentService do
  let(:user) { create(:user) }
  let(:options) { nil }

  let(:job) do
    create(:ci_build,
      ref: 'master',
      tag: false,
      environment: 'production',
      options: { environment: options })
  end

  let(:project) { job.project }

  let!(:environment) do
    create(:environment, project: project, name: 'production')
  end

  let(:service) { described_class.new(job) }

  before do
    allow_any_instance_of(Deployment).to receive(:create_ref)
  end

  describe '#execute' do
    subject { service.execute }

    context 'when environment exists' do
      it 'creates a deployment' do
        expect(subject).to be_persisted
      end
    end

    context 'when environment does not exist' do
      let(:environment) {}

      it 'does not create a deployment' do
        expect do
          expect(subject).to be_nil
        end.not_to change { Deployment.count }
      end
    end

    context 'when start action is defined' do
      let(:options) { { action: 'start' } }

      context 'and environment is stopped' do
        before do
          environment.stop
        end

        it 'makes environment available' do
          subject

          expect(environment.reload).to be_available
        end

        it 'creates a deployment' do
          expect(subject).to be_persisted
        end
      end
    end

    context 'when stop action is defined' do
      let(:options) { { action: 'stop' } }

      context 'and environment is available' do
        before do
          environment.start
        end

        it 'makes environment stopped' do
          subject

          expect(environment.reload).to be_stopped
        end

        it 'does not create a deployment' do
          expect(subject).to be_nil
        end
      end
    end

    context 'when variables are used' do
      let(:options) do
        { name: 'review-apps/$CI_COMMIT_REF_NAME',
          url: 'http://$CI_COMMIT_REF_NAME.review-apps.gitlab.com' }
      end

      before do
        environment.update(name: 'review-apps/master')
        job.update(environment: 'review-apps/$CI_COMMIT_REF_NAME')
      end

      it 'creates a new deployment' do
        expect(subject).to be_persisted
      end

      it 'does not create a new environment' do
        expect { subject }.not_to change { Environment.count }
      end

      it 'updates external url' do
        subject

        expect(subject.environment.name).to eq('review-apps/master')
        expect(subject.environment.external_url).to eq('http://master.review-apps.gitlab.com')
      end
    end

    context 'when project was removed' do
      let(:environment) {}

      before do
        job.update(project: nil)
      end

      it 'does not create deployment or environment' do
        expect { subject }.not_to raise_error

        expect(Environment.count).to be_zero
        expect(Deployment.count).to be_zero
      end
    end
  end

  describe '#expanded_environment_url' do
    subject { service.send(:expanded_environment_url) }

    context 'when yaml environment uses $CI_COMMIT_REF_NAME' do
      let(:job) do
        create(:ci_build,
               ref: 'master',
               options: { environment: { url: 'http://review/$CI_COMMIT_REF_NAME' } })
      end

      it { is_expected.to eq('http://review/master') }
    end

    context 'when yaml environment uses $CI_ENVIRONMENT_SLUG' do
      let(:job) do
        create(:ci_build,
               ref: 'master',
               environment: 'production',
               options: { environment: { url: 'http://review/$CI_ENVIRONMENT_SLUG' } })
      end

      let!(:environment) do
        create(:environment,
          project: job.project,
          name: 'production',
          slug: 'prod-slug',
          external_url: 'http://review/old')
      end

      it { is_expected.to eq('http://review/prod-slug') }
    end

    context 'when yaml environment uses yaml_variables containing symbol keys' do
      let(:job) do
        create(:ci_build,
               yaml_variables: [{ key: :APP_HOST, value: 'host' }],
               options: { environment: { url: 'http://review/$APP_HOST' } })
      end

      it { is_expected.to eq('http://review/host') }
    end

    context 'when yaml environment does not have url' do
      let(:job) { create(:ci_build, environment: 'staging') }

      let!(:environment) do
        create(:environment, project: job.project, name: job.environment)
      end

      it 'returns the external_url from persisted environment' do
        is_expected.to be_nil
      end
    end
  end

  describe 'processing of builds' do
    shared_examples 'does not create deployment' do
      it 'does not create a new deployment' do
        expect { subject }.not_to change { Deployment.count }
      end

      it 'does not call a service' do
        expect_any_instance_of(described_class).not_to receive(:execute)

        subject
      end
    end

    shared_examples 'creates deployment' do
      it 'creates a new deployment' do
        expect { subject }.to change { Deployment.count }.by(1)
      end

      it 'calls a service' do
        expect_any_instance_of(described_class).to receive(:execute)

        subject
      end

      it 'is set as deployable' do
        subject

        expect(Deployment.last.deployable).to eq(deployable)
      end

      it 'updates environment URL' do
        subject

        expect(Deployment.last.environment.external_url).not_to be_nil
      end
    end

    context 'without environment specified' do
      let(:job) { create(:ci_build) }

      it_behaves_like 'does not create deployment' do
        subject { job.success }
      end
    end

    context 'when environment is specified' do
      let(:deployable) { job }

      let(:options) do
        { environment: { name: 'production', url: 'http://gitlab.com' } }
      end

      context 'when job succeeds' do
        it_behaves_like 'creates deployment' do
          subject { job.success }
        end
      end

      context 'when job fails' do
        it_behaves_like 'does not create deployment' do
          subject { job.drop }
        end
      end

      context 'when job is retried' do
        it_behaves_like 'creates deployment' do
          before do
            stub_not_protect_default_branch

            project.add_developer(user)
          end

          let(:deployable) { Ci::Build.retry(job, user) }

          subject { deployable.success }
        end
      end
    end
  end

  describe "merge request metrics" do
    let(:merge_request) { create(:merge_request, target_branch: 'master', source_branch: 'feature', source_project: project) }

    context "while updating the 'first_deployed_to_production_at' time" do
      before do
        merge_request.metrics.update!(merged_at: Time.now)
      end

      context "for merge requests merged before the current deploy" do
        it "sets the time if the deploy's environment is 'production'" do
          time = Time.now
          Timecop.freeze(time) { service.execute }

          expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_like_time(time)
        end

        it "doesn't set the time if the deploy's environment is not 'production'" do
          job.update(environment: 'staging')
          service = described_class.new(job)
          service.execute

          expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_nil
        end

        it 'does not raise errors if the merge request does not have a metrics record' do
          merge_request.metrics.destroy

          expect(merge_request.reload.metrics).to be_nil
          expect { service.execute }.not_to raise_error
        end
      end

      context "for merge requests merged before the previous deploy" do
        context "if the 'first_deployed_to_production_at' time is already set" do
          it "does not overwrite the older 'first_deployed_to_production_at' time" do
            # Previous deploy
            time = Time.now
            Timecop.freeze(time) { service.execute }

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_like_time(time)

            # Current deploy
            service = described_class.new(job)
            Timecop.freeze(time + 12.hours) { service.execute }

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_like_time(time)
          end
        end

        context "if the 'first_deployed_to_production_at' time is not already set" do
          it "does not overwrite the older 'first_deployed_to_production_at' time" do
            # Previous deploy
            time = 5.minutes.from_now
            Timecop.freeze(time) { service.execute }

            expect(merge_request.reload.metrics.merged_at).to be < merge_request.reload.metrics.first_deployed_to_production_at

            merge_request.reload.metrics.update(first_deployed_to_production_at: nil)

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_nil

            # Current deploy
            service = described_class.new(job)
            Timecop.freeze(time + 12.hours) { service.execute }

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_nil
          end
        end
      end
    end
  end
end
