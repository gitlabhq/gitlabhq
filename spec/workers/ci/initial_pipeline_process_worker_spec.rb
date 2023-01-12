# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InitialPipelineProcessWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let(:job) { build(:ci_build, project: project) }
  let(:stage) { build(:ci_stage, project: project, statuses: [job]) }
  let(:pipeline) { create(:ci_pipeline, stages: [stage], status: :created, project: project, builds: [job]) }

  describe '#perform' do
    include_examples 'an idempotent worker' do
      let(:job_args) { pipeline.id }

      it 'marks the pipeline as pending' do
        expect(pipeline).to be_created

        subject

        expect(pipeline.reload).to be_pending
      end
    end

    context 'when a pipeline does not contain a deployment job' do
      it 'does not create any deployments' do
        expect { subject }.not_to change { Deployment.count }
      end
    end

    context 'when a pipeline contains a teardown job' do
      let(:job) { build(:ci_build, :stop_review_app, project: project) }

      before do
        create(:environment, name: job.expanded_environment_name)
      end

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(job.deployment).to be_nil
      end
    end

    context 'when a pipeline contains a deployment job' do
      let(:job) { build(:ci_build, :start_review_app, project: project) }
      let!(:environment) { create(:environment, project: project, name: job.expanded_environment_name) }

      it 'creates a deployment record' do
        expect { subject }.to change { Deployment.count }.by(1)

        expect(job.deployment).to have_attributes(
          project: job.project,
          ref: job.ref,
          sha: job.sha,
          deployable: job,
          deployable_type: 'CommitStatus',
          environment: job.persisted_environment)
      end

      context 'when the corresponding environment does not exist' do
        let(:environment) {}

        it 'does not create a deployment record' do
          expect { subject }.not_to change { Deployment.count }

          expect(job.deployment).to be_nil
        end
      end
    end
  end
end
