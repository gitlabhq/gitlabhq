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
  end
end
