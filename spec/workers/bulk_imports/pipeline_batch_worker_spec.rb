# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::PipelineBatchWorker, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }

  let(:pipeline_class) do
    Class.new do
      def initialize(_); end

      def run; end

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

    allow(subject).to receive(:jid).and_return('jid')
    allow(entity).to receive(:pipeline_exists?).with('FakePipeline').and_return(true)
    allow_next_instance_of(BulkImports::Groups::Stage) do |instance|
      allow(instance)
        .to receive(:pipelines)
        .and_return([{ stage: 0, pipeline: pipeline_class }])
    end
  end

  describe '#perform' do
    it 'runs the given pipeline batch successfully' do
      expect(BulkImports::FinishBatchedPipelineWorker).to receive(:perform_async).with(tracker.id)

      subject.perform(batch.id)

      expect(batch.reload).to be_finished
    end

    context 'when tracker is failed' do
      let(:tracker) { create(:bulk_import_tracker, :failed) }

      it 'skips the batch' do
        subject.perform(batch.id)

        expect(batch.reload).to be_skipped
      end
    end

    context 'when tracker is finished' do
      let(:tracker) { create(:bulk_import_tracker, :finished) }

      it 'skips the batch' do
        subject.perform(batch.id)

        expect(batch.reload).to be_skipped
      end
    end

    context 'when exclusive lease cannot be obtained' do
      it 'does not run the pipeline' do
        expect(subject).to receive(:try_obtain_lease).and_return(false)
        expect(subject).not_to receive(:run)

        subject.perform(batch.id)
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

          subject.perform(batch.id)

          expect(batch.reload).to be_created
        end
      end

      context 'when pipeline is not retryable' do
        it 'fails the batch and creates a failure record' do
          allow_next_instance_of(pipeline_class) do |instance|
            allow(instance).to receive(:run).and_raise(StandardError, 'Something went wrong')
          end

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(StandardError),
            hash_including(
              batch_id: batch.id,
              tracker_id: tracker.id,
              pipeline_class: 'FakePipeline',
              pipeline_step: 'pipeline_batch_worker_run'
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

          subject.perform(batch.id)

          expect(batch.reload).to be_failed
        end
      end
    end
  end
end
