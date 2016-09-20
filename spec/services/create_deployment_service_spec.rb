require 'spec_helper'

describe CreateDeploymentService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    let(:params) do
      { environment: 'production',
        ref: 'master',
        tag: false,
        sha: '97de212e80737a608d939f648d959671fb0a0142',
      }
    end

    subject { service.execute }

    context 'when no environments exist' do
      it 'does create a new environment' do
        expect { subject }.to change { Environment.count }.by(1)
      end

      it 'does create a deployment' do
        expect(subject).to be_persisted
      end
    end

    context 'when environment exist' do
      before { create(:environment, project: project, name: 'production') }

      it 'does not create a new environment' do
        expect { subject }.not_to change { Environment.count }
      end

      it 'does create a deployment' do
        expect(subject).to be_persisted
      end
    end

    context 'for environment with invalid name' do
      let(:params) do
        { environment: 'name,with,commas',
          ref: 'master',
          tag: false,
          sha: '97de212e80737a608d939f648d959671fb0a0142',
        }
      end

      it 'does not create a new environment' do
        expect { subject }.not_to change { Environment.count }
      end

      it 'does not create a deployment' do
        expect(subject).not_to be_persisted
      end
    end

    context 'when variables are used' do
      let(:params) do
        { environment: 'review-apps/$CI_BUILD_REF_NAME',
          ref: 'master',
          tag: false,
          sha: '97de212e80737a608d939f648d959671fb0a0142',
          options: {
            name: 'review-apps/$CI_BUILD_REF_NAME',
            url: 'http://$CI_BUILD_REF_NAME.review-apps.gitlab.com'
          },
          variables: [
            { key: 'CI_BUILD_REF_NAME', value: 'feature-review-apps' }
          ]
        }
      end

      it 'does create a new environment' do
        expect { subject }.to change { Environment.count }.by(1)

        expect(subject.environment.name).to eq('review-apps/feature-review-apps')
        expect(subject.environment.external_url).to eq('http://feature-review-apps.review-apps.gitlab.com')
      end

      it 'does create a new deployment' do
        expect(subject).to be_persisted
      end
    end
  end

  describe 'processing of builds' do
    let(:environment) { nil }
    
    shared_examples 'does not create environment and deployment' do
      it 'does not create a new environment' do
        expect { subject }.not_to change { Environment.count }
      end

      it 'does not create a new deployment' do
        expect { subject }.not_to change { Deployment.count }
      end

      it 'does not call a service' do
        expect_any_instance_of(described_class).not_to receive(:execute)
        subject
      end
    end

    shared_examples 'does create environment and deployment' do
      it 'does create a new environment' do
        expect { subject }.to change { Environment.count }.by(1)
      end

      it 'does create a new deployment' do
        expect { subject }.to change { Deployment.count }.by(1)
      end

      it 'does call a service' do
        expect_any_instance_of(described_class).to receive(:execute)
        subject
      end

      it 'is set as deployable' do
        subject

        expect(Deployment.last.deployable).to eq(deployable)
      end

      it 'create environment has URL set' do
        subject

        expect(Deployment.last.environment.external_url).not_to be_nil
      end
    end

    context 'without environment specified' do
      let(:build) { create(:ci_build, project: project) }
      
      it_behaves_like 'does not create environment and deployment' do
        subject { build.success }
      end
    end
    
    context 'when environment is specified' do
      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:build) { create(:ci_build, pipeline: pipeline, environment: 'production', options: options) }
      let(:options) do
        { environment: { name: 'production', url: 'http://gitlab.com' } }
      end

      context 'when build succeeds' do
        it_behaves_like 'does create environment and deployment' do
          let(:deployable) { build }

          subject { build.success }
        end
      end

      context 'when build fails' do
        it_behaves_like 'does not create environment and deployment' do
          subject { build.drop }
        end
      end

      context 'when build is retried' do
        it_behaves_like 'does create environment and deployment' do
          let(:deployable) { Ci::Build.retry(build) }

          subject { deployable.success }
        end
      end
    end
  end

  describe "merge request metrics" do
    let(:params) do
      {
        environment: 'production',
        ref: 'master',
        tag: false,
        sha: '97de212e80737a608d939f648d959671fb0a0142b',
      }
    end

    let(:merge_request) { create(:merge_request, target_branch: 'master', source_branch: 'feature', source_project: project) }

    context "while updating the 'first_deployed_to_production_at' time" do
      before { merge_request.mark_as_merged }

      context "for merge requests merged before the current deploy" do
        it "sets the time if the deploy's environment is 'production'" do
          time = Time.now
          Timecop.freeze(time) { service.execute }

          expect(merge_request.metrics.first_deployed_to_production_at).to eq(time)
        end

        it "doesn't set the time if the deploy's environment is not 'production'" do
          staging_params = params.merge(environment: 'staging')
          service = described_class.new(project, user, staging_params)
          service.execute

          expect(merge_request.metrics.first_deployed_to_production_at).to be_nil
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

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to eq(time)

            # Current deploy
            service = described_class.new(project, user, params)
            Timecop.freeze(time + 12.hours) { service.execute }

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to eq(time)
          end
        end

        context "if the 'first_deployed_to_production_at' time is not already set" do
          it "does not overwrite the older 'first_deployed_to_production_at' time" do
            # Previous deploy
            time = Time.now
            Timecop.freeze(time) { service.execute }
            merge_request.metrics.update(first_deployed_to_production_at: nil)

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_nil

            # Current deploy
            service = described_class.new(project, user, params)
            Timecop.freeze(time + 12.hours) { service.execute }

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_nil
          end
        end
      end
    end
  end
end
