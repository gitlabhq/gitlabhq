# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationBatchExportWorker, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:batch) { create(:bulk_import_export_batch) }

  let(:job_args) { [user.id, batch.id] }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(user.id, batch.id) }

    include_examples 'an idempotent worker' do
      it 'executes RelationBatchExportService' do
        service = instance_double(BulkImports::RelationBatchExportService)

        expect(BulkImports::RelationBatchExportService)
          .to receive(:new)
          .with(user, batch)
          .twice.and_return(service)
        expect(service).to receive(:execute).twice

        perform_multiple(job_args)
      end
    end

    context 'when the max number of exports have already started' do
      let_it_be(:existing_export) { create(:bulk_import_export_batch, :started) }

      before do
        stub_application_setting(concurrent_relation_batch_export_limit: 1)
      end

      it 'does not start the export and schedules it for later' do
        expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, user.id, batch.id)

        expect(BulkImports::RelationBatchExportService).not_to receive(:new)

        perform
      end

      it 'resets the expiration date for the cache key' do
        cache_key = BulkImports::BatchedRelationExportService.cache_key(batch.export_id, batch.id)
        Gitlab::Cache::Import::Caching.write(cache_key, "test", timeout: 1.hour.to_i)

        perform

        expires_in_seconds = Gitlab::Cache::Import::Caching.with_redis do |redis|
          redis.ttl(Gitlab::Cache::Import::Caching.cache_key_for(cache_key))
        end

        expect(expires_in_seconds).to be_within(10).of(BulkImports::BatchedRelationExportService::CACHE_DURATION.to_i)
      end

      context 'when the export batch started longer ago than the timeout time' do
        before do
          existing_export.update!(updated_at: (BulkImports::ExportBatch::TIMEOUT_AFTER_START + 1.minute).ago)
        end

        it 'starts the export and does not schedule it for later' do
          expect(described_class).not_to receive(:perform_in).with(described_class::PERFORM_DELAY, user.id, batch.id)

          expect_next_instance_of(BulkImports::RelationBatchExportService) do |instance|
            expect(instance).to receive(:execute)
          end

          perform
        end
      end

      context 'when the export batch job was interrupted' do
        before do
          batch.start!
        end

        it 'starts the export and does not schedule it for later' do
          expect(described_class).not_to receive(:perform_in).with(described_class::PERFORM_DELAY, user.id, batch.id)

          expect_next_instance_of(BulkImports::RelationBatchExportService) do |instance|
            expect(instance).to receive(:execute)
          end

          perform
        end
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => job_args } }

    it 'sets export status to failed and tracks the exception' do
      portable = batch.export.portable

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(kind_of(StandardError), portable_id: portable.id, portable_type: portable.class.name)

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new('*' * 300))

      expect(batch.reload.failed?).to eq(true)
      expect(batch.error.size).to eq(255)
    end
  end

  describe '.sidekiq_interruptions_exhausted' do
    it 'sets export status to failed' do
      job = { 'args' => job_args }

      described_class.interruptions_exhausted_block.call(job)
      expect(batch.reload).to be_failed
      expect(batch.error).to eq('Export process reached the maximum number of interruptions')
    end
  end
end
