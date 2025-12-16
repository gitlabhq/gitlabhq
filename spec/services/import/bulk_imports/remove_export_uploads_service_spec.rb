# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::RemoveExportUploadsService, feature_category: :importers do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:export) { create(:bulk_import_export, project: project) }
    let_it_be(:export_upload) { create(:bulk_import_export_upload, export: export) }

    subject(:service) { described_class.new(project) }

    it 'enqueues RemoveExportUploadWorker for each upload' do
      export_upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))

      expect(Import::BulkImports::RemoveExportUploadWorker)
        .to receive(:perform_async).with(export_upload.uploads.first.id)

      service.execute
    end

    it 'returns a success response' do
      expect(service.execute).to be_success
    end

    context 'when the export has no associated upload' do
      it 'does not enqueue RemoveExportUploadWorker for each upload' do
        export_upload.destroy!
        project.reload

        expect(Import::BulkImports::RemoveExportUploadWorker)
          .not_to receive(:perform_async)

        service.execute
      end
    end
  end
end
