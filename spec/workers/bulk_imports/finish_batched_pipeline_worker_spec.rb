# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FinishBatchedPipelineWorker, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }

  let(:status_event) { :finish }
  let(:pipeline_tracker) { create(:bulk_import_tracker, :started, :batched, entity: entity) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when job version is nil' do
      before do
        allow(subject).to receive(:job_version).and_return(nil)
      end

      it 'finishes pipeline and enqueues entity worker' do
        expect(BulkImports::EntityWorker).to receive(:perform_async)
          .with(entity.id)

        subject.perform(pipeline_tracker.id)

        expect(pipeline_tracker.reload.finished?).to eq(true)
      end
    end

    context 'when job version is present' do
      it 'finishes pipeline and does not enqueues entity worker' do
        expect(BulkImports::EntityWorker).not_to receive(:perform_async)

        subject.perform(pipeline_tracker.id)

        expect(pipeline_tracker.reload.finished?).to eq(true)
      end
    end

    context 'when import is in progress' do
      it 're-enqueues for any started batches' do
        create(:bulk_import_batch_tracker, :started, tracker: pipeline_tracker)

        expect(described_class)
          .to receive(:perform_in)
          .with(described_class::REQUEUE_DELAY, pipeline_tracker.id)

        subject.perform(pipeline_tracker.id)
      end

      it 're-enqueues for any created batches' do
        create(:bulk_import_batch_tracker, :created, tracker: pipeline_tracker)

        expect(described_class)
          .to receive(:perform_in)
          .with(described_class::REQUEUE_DELAY, pipeline_tracker.id)

        subject.perform(pipeline_tracker.id)
      end
    end

    context 'when pipeline tracker is stale' do
      let(:pipeline_tracker) { create(:bulk_import_tracker, :started, :batched, :stale, entity: entity) }

      it 'fails pipeline tracker and its batches' do
        create(:bulk_import_batch_tracker, :finished, tracker: pipeline_tracker)

        subject.perform(pipeline_tracker.id)

        expect(pipeline_tracker.reload.failed?).to eq(true)
        expect(pipeline_tracker.batches.first.reload.failed?).to eq(true)
      end
    end

    context 'when pipeline is not batched' do
      let(:pipeline_tracker) { create(:bulk_import_tracker, :started, entity: entity) }

      it 'returns' do
        expect_next_instance_of(BulkImports::Tracker) do |instance|
          expect(instance).not_to receive(:finish!)
        end

        subject.perform(pipeline_tracker.id)
      end
    end

    context 'when pipeline is not started' do
      let(:status_event) { :start }

      it 'returns' do
        expect_next_instance_of(BulkImports::Tracker) do |instance|
          expect(instance).not_to receive(:finish!)
        end

        described_class.new.perform(pipeline_tracker.id)
      end
    end
  end
end
