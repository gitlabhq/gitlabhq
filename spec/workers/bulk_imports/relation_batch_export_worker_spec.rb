# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationBatchExportWorker, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:batch) { create(:bulk_import_export_batch) }

  let(:job_args) { [user.id, batch.id] }

  describe '#perform' do
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
end
