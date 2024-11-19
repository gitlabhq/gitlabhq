# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FinishBatchedRelationExportWorker, feature_category: :importers do
  let(:export) { create(:bulk_import_export, :started) }
  let(:batch) { create(:bulk_import_export_batch, :finished, export: export) }
  let(:export_id) { export.id }
  let(:job_args) { [export_id] }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      it 'marks export as finished and expires batches cache' do
        cache_key = BulkImports::BatchedRelationExportService.cache_key(export.id, batch.id)

        expect(Gitlab::Cache::Import::Caching).to receive(:expire).with(cache_key, 0)

        perform_multiple(job_args)

        expect(export.reload.finished?).to eq(true)
      end

      context 'when export is finished' do
        let(:export) { create(:bulk_import_export, :finished) }

        it 'returns without updating export' do
          perform_multiple(job_args)

          expect(export.reload.finished?).to eq(true)
        end
      end

      context 'when export is failed' do
        let(:export) { create(:bulk_import_export, :failed) }

        it 'returns without updating export' do
          perform_multiple(job_args)

          expect(export.reload.failed?).to eq(true)
        end
      end

      shared_examples 'reenqueues itself' do
        it 'reenqueues itself' do
          expect(described_class).to receive(:perform_in).twice.with(described_class::REENQUEUE_DELAY, export.id)

          perform_multiple(job_args)

          expect(export.reload.started?).to eq(true)
        end
      end

      context 'when export has started' do
        before do
          create(:bulk_import_export_batch, :started, export: export)
        end

        it_behaves_like 'reenqueues itself'
      end

      context 'when export has been created' do
        before do
          create(:bulk_import_export_batch, :created, export: export)
        end

        it_behaves_like 'reenqueues itself'
      end

      context 'when export timed out' do
        it 'marks export as failed' do
          expect(export.reload.failed?).to eq(false)
          expect(batch.reload.failed?).to eq(false)

          export.update!(updated_at: 1.day.ago)

          perform_multiple(job_args)

          expect(export.reload.failed?).to eq(true)
          expect(batch.reload.failed?).to eq(true)
        end
      end

      context 'when export is missing' do
        let(:export_id) { nil }

        it 'returns' do
          expect(described_class).not_to receive(:perform_in)

          perform_multiple(job_args)
        end
      end
    end
  end
end
