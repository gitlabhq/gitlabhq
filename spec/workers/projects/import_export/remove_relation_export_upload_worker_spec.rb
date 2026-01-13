# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RemoveRelationExportUploadWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  let_it_be(:project) { create(:project) }

  describe '#perform' do
    let!(:export_job) { create(:project_export_job, project: project) }
    let!(:relation_export) { create(:project_relation_export, project_export_job: export_job) }
    let!(:relation_export_upload) do
      create(:relation_export_upload, relation_export: relation_export).tap do |upload|
        upload.update!(export_file: fixture_file_upload('spec/fixtures/gitlab/import_export/labels.tar.gz'))
      end
    end

    let(:upload_id) { relation_export_upload.uploads.first.id }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [upload_id] }
    end

    context 'when export exists' do
      it 'destroys the upload and its associated file' do
        expect { worker.perform(upload_id) }
          .to change { Upload.all.count }.from(1).to(0)
      end
    end

    context 'when upload does not exist' do
      it 'returns early without raising an error' do
        expect { worker.perform(non_existing_record_id) }.not_to raise_error
      end
    end

    context 'when relation export upload does not exist' do
      it 'destroys the upload and its associated file' do
        expect_next_instance_of(ImportExportUploader) do |found_upload|
          expect(found_upload).to receive(:remove!).and_call_original
        end

        relation_export_upload.delete

        expect { worker.perform(upload_id) }
          .to change { Upload.all.count }.from(1).to(0)
      end
    end

    context 'when uploader is not ImportExportUploader' do
      it 'returns early without destroying the upload' do
        upload = create(:upload, :favicon_upload)

        expect { worker.perform(upload.id) }
          .not_to change { Upload.all.count }
      end
    end
  end
end
