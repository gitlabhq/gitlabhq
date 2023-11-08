# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InitialPipelineProcessWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let(:job) { build(:ci_build, project: project) }
  let(:stage) { build(:ci_stage, project: project, statuses: [job], position: 1) }
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
      before do
        allow(::Deployments::CreateForJobService).to receive(:new).and_call_original
        allow(::Ci::PipelineProcessing::AtomicProcessingService).to receive(:new).and_call_original
      end

      let(:job) { build(:ci_build, :created, :start_review_app, project: project, stage_idx: 1) }
      let!(:environment) { create(:environment, project: project, name: job.expanded_environment_name) }

      it 'creates a deployment record' do
        expect { subject }.to change { Deployment.count }.by(1)
      end

      context 'when the corresponding environment does not exist' do
        let(:environment) {}

        it 'does not create a deployment record' do
          expect { subject }.not_to change { Deployment.count }

          expect(job.deployment).to be_nil
        end
      end

      it 'kicks off atomic processing before a deployment is created' do
        expect(::Ci::PipelineProcessing::AtomicProcessingService).to receive(:new).ordered
        expect(::Deployments::CreateForJobService).to receive(:new).ordered

        subject
      end
    end
  end
end
