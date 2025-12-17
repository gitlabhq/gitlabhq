# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportUploader, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let!(:export) { create(:bulk_import_export, project: project) }

  describe '#store_dirs' do
    let!(:export_upload) { create(:bulk_import_export_upload, export: export, project_id: project.id) }
    let!(:upload) { create(:upload, :bulk_imports_export_uploader, model: export_upload) }

    subject(:uploader) { upload.retrieve_uploader }

    context 'when ExportUpload and Upload are present' do
      it 'pulls the path details from the ExportUpload record' do
        expect(uploader.store_dirs).to eq({
          1 => "uploads/-/system/bulk_imports/export_upload/export_file/#{upload.model.id}",
          2 => "bulk_imports/export_upload/export_file/#{upload.model.id}"
        })
      end
    end

    context 'when ExportUpload is absent' do
      before do
        upload.model.delete
        upload.reload
      end

      it 'pulls the path details from the Upload record' do
        expect(uploader.model).to be_nil
        expect(uploader.store_dirs).to eq({
          1 => "uploads/-/system/bulk_imports/export_upload/export_file/#{upload.model_id}",
          2 => "bulk_imports/export_upload/export_file/#{upload.model_id}"
        })
      end

      context 'when Upload is missing mount point' do
        before do
          upload.update_column(:mount_point, nil)
          upload.reload
        end

        it 'raises an exception' do
          expect { upload.retrieve_uploader.store_dirs }
            .to raise_exception(StandardError, "Missing required upload attributes for path reconstruction")
        end
      end
    end
  end

  describe '#mounted_as' do
    let!(:export_upload) { create(:bulk_import_export_upload, export: export, project_id: project.id) }
    let!(:upload) { create(:upload, :bulk_imports_export_uploader, model: export_upload) }

    subject(:uploader) { upload.retrieve_uploader }

    context 'when ExportUpload and Upload are present' do
      it 'pulls the path details from the ExportUpload record' do
        expect(uploader.mounted_as).to eq(:export_file)
      end
    end

    context 'when ExportUpload is absent' do
      before do
        upload.model.delete
        upload.update_column :mount_point, 'other_mount_point'
        upload.reload
      end

      it 'pulls the path details from the Upload record' do
        expect(uploader.model).to be_nil
        expect(uploader.mounted_as).to eq(:other_mount_point)
      end
    end
  end
end
