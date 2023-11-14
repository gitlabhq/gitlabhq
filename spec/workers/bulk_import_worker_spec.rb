#  frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImportWorker, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:job_args) { [bulk_import.id] }

  describe '#perform' do
    it 'executes the BulkImports::ProcessService' do
      expect_next_instance_of(BulkImports::ProcessService) do |process_service|
        expect(process_service).to receive(:execute)
      end

      described_class.new.perform(bulk_import.id)
    end

    context 'when no BulkImport is found' do
      let(:job_args) { nil }

      it 'returns without error' do
        expect { described_class.new.perform(bulk_import.id) }.not_to raise_error
      end

      it 'does not executes the BulkImports::ProcessService' do
        expect_any_instance_of(BulkImports::ProcessService) do |process_service|
          expect(process_service).not_to receive(:execute)
        end
      end
    end

    it_behaves_like 'an idempotent worker'
  end

  describe '#sidekiq_retries_exhausted' do
    it 'logs export failure and marks entity as failed' do
      exception = StandardError.new('Exhausted error!')

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception, bulk_import_id: bulk_import.id)

      described_class.sidekiq_retries_exhausted_block.call({ 'args' => job_args }, exception)

      expect(bulk_import.reload.failed?).to eq(true)
    end
  end
end
