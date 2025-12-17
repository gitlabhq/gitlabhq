# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::RemoveExportUploadWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  let_it_be(:project) { create(:project) }
  let!(:export) { create(:bulk_import_export, project: project) }
  let!(:export_upload) { create(:bulk_import_export_upload, export: export) }

  describe '#perform' do
    before do
      export_upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))
    end

    let(:upload_id) { export_upload.uploads.first.id }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [upload_id] }
    end

    context 'when export exists' do
      it 'destroys the upload and its associated file' do
        expect_next_instance_of(BulkImports::ExportUploader) do |found_upload|
          expect(found_upload).to receive(:remove!).and_call_original
        end

        expect { worker.perform(upload_id) }
          .to change { Upload.all.count }.from(1).to(0)
      end
    end

    context 'when upload does not exist' do
      it 'returns early without raising an error' do
        expect { worker.perform(non_existing_record_id) }.not_to raise_error
      end
    end

    context 'when export does not exist' do
      before do
        export_upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))
      end

      it 'destroys the upload and its associated file' do
        expect_next_instance_of(BulkImports::ExportUploader) do |found_upload|
          expect(found_upload).to receive(:remove!).and_call_original
        end

        export_upload.delete

        expect { worker.perform(upload_id) }
          .to change { Upload.all.count }.from(1).to(0)
      end
    end

    context 'when uploader is not BulkImports::ExportUploader' do
      it 'returns early without destroying the upload' do
        upload = create(:upload, :favicon_upload)

        expect { worker.perform(upload.id) }
          .not_to change { Upload.all.count }
      end
    end
  end
end
