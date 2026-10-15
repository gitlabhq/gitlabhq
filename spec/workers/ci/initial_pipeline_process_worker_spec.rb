# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InitialPipelineProcessWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let(:job) { build(:ci_build, project: project, ref: project.default_branch) }
  let(:stage) { build(:ci_stage, project: project, statuses: [job], position: 1) }
  let(:pipeline) do
    create(:ci_pipeline, stages: [stage], status: :created, project: project, ref: project.default_branch,
      builds: [job])
  end

  describe '.get_data_consistency_per_database' do
    before do
      skip_if_shared_database(:ci)
    end

    it 'reads the ci database from the primary and keeps main sticky' do
      expect(described_class.get_data_consistency_per_database).to include({ main: :sticky, ci: :always })
    end

    context 'when the initial_pipeline_process_worker_ci_primary_reads feature flag is disabled' do
      before do
        stub_feature_flags(initial_pipeline_process_worker_ci_primary_reads: false)
      end

      it 'keeps the ci database sticky' do
        expect(described_class.get_data_consistency_per_database).to include({ main: :sticky, ci: :sticky })
      end
    end

    context 'when the application does not run in multiple-database mode' do
      before do
        allow(Gitlab::Database).to receive(:database_mode).and_return(Gitlab::Database::MODE_SINGLE_DATABASE)
      end

      it 'leaves the declared data consistency unchanged' do
        expect(described_class.get_data_consistency_per_database).to include({ main: :sticky, ci: :sticky })
      end
    end
  end

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
      let(:job) { build(:ci_build, :stop_review_app, project: project, ref: project.default_branch) }

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

      let(:job) do
        build(:ci_build, :created, :start_review_app, project: project, ref: project.default_branch,
          stage_idx: 1)
      end

      let!(:environment) do
        create(:environment, project: project, name: "review/#{project.default_branch}")
      end

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
