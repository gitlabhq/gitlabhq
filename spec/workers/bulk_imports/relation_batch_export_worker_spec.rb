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
          .with(user.id, batch.id)
          .twice.and_return(service)
        expect(service).to receive(:execute).twice

        perform_multiple(job_args)
      end
    end
  end
end
