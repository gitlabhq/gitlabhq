# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckPipelines::ProcessService, feature_category: :continuous_integration do
  let_it_be(:ci_partition) { create(:ci_partition, :current, id: ci_testing_partition_id) }
  let_it_be(:project) { create(:project) }

  let(:service) { described_class.new }

  shared_examples 'does not enqueue PipelineProcessWorker' do
    it 'does not enqueue PipelineProcessWorker' do
      expect(PipelineProcessWorker).not_to receive(:perform_async)

      service.execute
    end
  end

  describe '#execute' do
    context 'with a stale running pipeline with no active builds' do
      let!(:stale_pipeline) do
        create(:ci_pipeline, :running, project: project, updated_at: 10.minutes.ago)
      end

      before do
        create(:ci_build, :success, pipeline: stale_pipeline)
      end

      it 'enqueues PipelineProcessWorker' do
        expect(PipelineProcessWorker)
          .to receive(:perform_async).with(stale_pipeline.id)

        service.execute
      end

      context 'when ci_process_stuck_pipelines is disabled' do
        before do
          stub_feature_flags(ci_process_stuck_pipelines: false)
        end

        it_behaves_like 'does not enqueue PipelineProcessWorker'
      end
    end

    context 'with a recently updated running pipeline' do
      let!(:active_pipeline) do
        create(:ci_pipeline, :running, project: project, updated_at: 2.minutes.ago)
      end

      it_behaves_like 'does not enqueue PipelineProcessWorker'
    end

    context 'with a non-running pipeline with old updated_at' do
      let!(:completed_pipeline) do
        create(:ci_pipeline, :success, project: project, updated_at: 10.minutes.ago)
      end

      it_behaves_like 'does not enqueue PipelineProcessWorker'
    end

    context 'with a running pipeline older than the lookback window' do
      let!(:old_pipeline) do
        create(:ci_pipeline, :running, project: project, updated_at: 2.hours.ago)
      end

      it_behaves_like 'does not enqueue PipelineProcessWorker'
    end

    context 'with more stale pipelines than the batch size' do
      let!(:stale_pipelines) do
        create_list(:ci_pipeline, 5, :running, project: project, updated_at: 10.minutes.ago).each do |pipeline|
          create(:ci_build, :success, pipeline: pipeline)
        end
      end

      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'enqueues PipelineProcessWorker for every stuck pipeline across batches' do
        stale_pipelines.each do |pipeline|
          expect(PipelineProcessWorker).to receive(:perform_async).with(pipeline.id)
        end

        service.execute
      end
    end

    context 'when exceeding MAX_PIPELINES' do
      before do
        stub_const("#{described_class}::MAX_PIPELINES", 2)
        stub_const("#{described_class}::BATCH_SIZE", 1)

        create_list(:ci_pipeline, 3, :running, project: project, updated_at: 10.minutes.ago).each do |pipeline|
          create(:ci_build, :success, pipeline: pipeline)
        end
      end

      it 'stops enqueuing after the limit is reached' do
        expect(PipelineProcessWorker)
          .to receive(:perform_async).twice

        service.execute
      end

      it 'logs a warning' do
        allow(PipelineProcessWorker).to receive(:perform_async)

        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            message: "Stuck pipelines cap reached, remaining pipelines will be processed in the next run",
            total_processed: 2,
            cap: 2
          )
        )

        service.execute
      end
    end
  end
end
