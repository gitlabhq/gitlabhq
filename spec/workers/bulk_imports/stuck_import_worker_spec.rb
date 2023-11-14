# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::StuckImportWorker, feature_category: :importers do
  let_it_be(:created_bulk_import) { create(:bulk_import, :created) }
  let_it_be(:started_bulk_import) { create(:bulk_import, :started) }
  let_it_be(:stale_created_bulk_import) { create(:bulk_import, :created, created_at: 3.days.ago) }
  let_it_be(:stale_started_bulk_import) { create(:bulk_import, :started, created_at: 3.days.ago) }
  let_it_be(:stale_created_bulk_import_entity) { create(:bulk_import_entity, :created, created_at: 3.days.ago) }
  let_it_be(:stale_started_bulk_import_entity) { create(:bulk_import_entity, :started, created_at: 3.days.ago) }

  let_it_be(:started_bulk_import_tracker) do
    create(:bulk_import_tracker, :started, entity: stale_started_bulk_import_entity)
  end

  subject { described_class.new.perform }

  describe 'perform' do
    it 'updates the status of bulk imports to timeout' do
      expect_next_instance_of(BulkImports::Logger) do |logger|
        allow(logger).to receive(:error)
        expect(logger).to receive(:error).with(
          message: 'BulkImport stale',
          bulk_import_id: stale_created_bulk_import.id
        )
        expect(logger).to receive(:error).with(
          message: 'BulkImport stale',
          bulk_import_id: stale_started_bulk_import.id
        )
      end

      expect { subject }.to change { stale_created_bulk_import.reload.status_name }.from(:created).to(:timeout)
                        .and change { stale_started_bulk_import.reload.status_name }.from(:started).to(:timeout)
    end

    it 'updates the status of bulk import entities to timeout' do
      expect_next_instance_of(BulkImports::Logger) do |logger|
        allow(logger).to receive(:error)
        expect(logger).to receive(:error).with(
          message: 'BulkImports::Entity stale',
          bulk_import_entity_id: stale_created_bulk_import_entity.id,
          bulk_import_id: stale_created_bulk_import_entity.bulk_import_id
        )
        expect(logger).to receive(:error).with(
          message: 'BulkImports::Entity stale',
          bulk_import_entity_id: stale_started_bulk_import_entity.id,
          bulk_import_id: stale_started_bulk_import_entity.bulk_import_id
        )
      end

      expect { subject }.to change { stale_created_bulk_import_entity.reload.status_name }.from(:created).to(:timeout)
                        .and change { stale_started_bulk_import_entity.reload.status_name }.from(:started).to(:timeout)
    end

    it 'updates the status of stale entities trackers to timeout' do
      expect { subject }.to change { started_bulk_import_tracker.reload.status_name }.from(:started).to(:timeout)
    end

    it 'does not update the status of non-stale records' do
      expect { subject }.to not_change { created_bulk_import.reload.status }
                        .and not_change { started_bulk_import.reload.status }
    end
  end
end
