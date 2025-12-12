# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::RemoveExportUploadWorker, feature_category: :importers do
  let(:worker) { described_class.new }
  let!(:upload) { create(:upload, :bulk_imports_export_uploader) }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [upload.id] }
    end

    context 'when export exists' do
      it 'destroys the upload and its associated file' do
        expect_next_found_instance_of(Upload) do |found_upload|
          expect(found_upload).to receive(:delete_file!)
        end

        expect { worker.perform(upload.id) }
          .to change { Upload.all.count }.from(1).to(0)
      end
    end

    context 'when export does not exist' do
      it 'returns early without raising an error' do
        expect { worker.perform(non_existing_record_id) }.not_to raise_error
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
