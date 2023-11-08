# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::PipelineBatchWorker, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }

  let(:pipeline_class) do
    Class.new do
      def initialize(context)
        @context = context
      end

      def run
        @context.tracker.finish!
      end

      def self.file_extraction_pipeline?
        false
      end
    end
  end

  let(:tracker) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'FakePipeline',
      status_event: 'enqueue'
    )
  end

  let(:batch) { create(:bulk_import_batch_tracker, :created, tracker: tracker) }

  subject(:worker) { described_class.new }

  before do
    stub_const('FakePipeline', pipeline_class)

    allow(entity).to receive(:pipeline_exists?).with('FakePipeline').and_return(true)
    allow_next_instance_of(BulkImports::Groups::Stage) do |instance|
      allow(instance)
        .to receive(:pipelines)
        .and_return([{ stage: 0, pipeline: pipeline_class }])
    end
  end

  include_examples 'an idempotent worker' do
    let(:job_args) { batch.id }
    let(:tracker) { create(:bulk_import_tracker, :started, entity: entity, pipeline_name: 'FakePipeline') }

    it 'processes the batch once' do
      allow_next_instance_of(pipeline_class) do |instance|
        expect(instance).to receive(:run).once.and_call_original
      end

      perform_multiple(job_args)

      expect(batch.reload).to be_finished
    end
  end

  describe '#perform' do
    it 'runs the given pipeline batch successfully' do
      expect(BulkImports::FinishBatchedPipelineWorker).to receive(:perform_async).with(tracker.id)
      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:info).with(a_hash_including('message' => 'Batch tracker started'))
        expect(logger).to receive(:info).with(a_hash_including('message' => 'Batch tracker finished'))
      end

      worker.perform(batch.id)

      expect(batch.reload).to be_finished
    end

    context 'with tracker status' do
      context 'when tracker is failed' do
        let(:tracker) { create(:bulk_import_tracker, :failed) }

        it 'skips the batch' do
          worker.perform(batch.id)

          expect(batch.reload).to be_skipped
        end
      end

      context 'when tracker is finished' do
        let(:tracker) { create(:bulk_import_tracker, :finished) }

        it 'skips the batch' do
          worker.perform(batch.id)

          expect(batch.reload).to be_skipped
        end
      end
    end

    context 'with batch status' do
      context 'when batch status is started' do
        let(:batch) { create(:bulk_import_batch_tracker, :started, tracker: tracker) }

        it 'finishes the batch' do
          worker.perform(batch.id)

          expect(batch.reload).to be_finished
        end
      end

      context 'when batch status is created' do
        let(:batch) { create(:bulk_import_batch_tracker, :created, tracker: tracker) }

        it 'finishes the batch' do
          worker.perform(batch.id)

          expect(batch.reload).to be_finished
        end
      end

      context 'when batch status is finished' do
        let(:batch) { create(:bulk_import_batch_tracker, :finished, tracker: tracker) }

        it 'stays finished' do
          worker.perform(batch.id)

          expect(batch.reload).to be_finished
        end
      end
    end

    context 'when exclusive lease cannot be obtained' do
      it 'does not run the pipeline' do
        expect(worker).to receive(:try_obtain_lease).and_return(false)
        expect(worker).not_to receive(:run)

        worker.perform(batch.id)
      end
    end

    context 'when pipeline raises an exception' do
      context 'when pipeline is retryable' do
        it 'retries the batch' do
          allow_next_instance_of(pipeline_class) do |instance|
            allow(instance)
              .to receive(:run)
              .and_raise(BulkImports::RetryPipelineError.new('Error!', 60))
          end

          expect(described_class).to receive(:perform_in).with(60, batch.id)
          expect(BulkImports::FinishBatchedPipelineWorker).not_to receive(:perform_async).with(tracker.id)

          worker.perform(batch.id)

          expect(batch.reload).to be_created
        end
      end

      context 'when pipeline raises an error' do
        it 'keeps batch status as `started` and lets the error bubble up' do
          allow_next_instance_of(pipeline_class) do |instance|
            allow(instance).to receive(:run).and_raise(StandardError, 'Something went wrong')
          end

          expect { worker.perform(batch.id) }.to raise_exception(StandardError)

          expect(batch.reload).to be_started
        end
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    it 'sets batch status to failed' do
      job = { 'args' => [batch.id] }

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(StandardError),
        hash_including(
          'message' => 'Batch tracker failed',
          'batch_id' => batch.id,
          'tracker_id' => tracker.id,
          'pipeline_class' => 'FakePipeline',
          'pipeline_step' => 'pipeline_batch_worker_run',
          'importer' => 'gitlab_migration'
        )
      )

      expect(BulkImports::Failure).to receive(:create).with(
        bulk_import_entity_id: entity.id,
        pipeline_class: 'FakePipeline',
        pipeline_step: 'pipeline_batch_worker_run',
        exception_class: 'StandardError',
        exception_message: 'Something went wrong',
        correlation_id_value: anything
      )

      expect(BulkImports::FinishBatchedPipelineWorker).to receive(:perform_async).with(tracker.id)

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new("Something went wrong"))

      expect(batch.reload).to be_failed
    end
  end
end
