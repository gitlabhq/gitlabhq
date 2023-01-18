# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::CreateDeployments, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:stage) { build(:ci_stage, project: project, statuses: [job]) }
  let(:pipeline) { create(:ci_pipeline, project: project, stages: [stage]) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject { step.perform! }

    before do
      stub_feature_flags(move_create_deployments_to_worker: false)
      job.pipeline = pipeline
    end

    context 'when a pipeline contains a deployment job' do
      let!(:job) { build(:ci_build, :start_review_app, project: project) }
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
      end

      context 'when the corresponding environment does not exist' do
        let!(:environment) {}

        it 'does not create a deployment record' do
          expect { subject }.not_to change { Deployment.count }

          expect(job.deployment).to be_nil
        end
      end
    end

    context 'when a pipeline contains a teardown job' do
      let!(:job) { build(:ci_build, :stop_review_app, project: project) }
      let!(:environment) { create(:environment, name: job.expanded_environment_name) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(job.deployment).to be_nil
      end
    end

    context 'when a pipeline does not contain a deployment job' do
      let!(:job) { build(:ci_build, project: project) }

      it 'does not create any deployments' do
        expect { subject }.not_to change { Deployment.count }
      end
    end
  end
end
