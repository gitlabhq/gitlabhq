# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::UploadsExportService, feature_category: :importers do
  let(:export_path) { Dir.mktmpdir }
  let(:project) { create(:project, avatar: fixture_file_upload('spec/fixtures/rails_sample.png', 'image/png')) }
  let!(:upload) { create(:upload, :with_file, :issuable_upload, uploader: FileUploader, model: project) }
  let(:exported_filepath) { File.join(export_path, upload.secret, upload.retrieve_uploader.filename) }

  subject(:service) { described_class.new(project, export_path) }

  after do
    FileUtils.rm_rf(export_path)
  end

  describe '#execute' do
    it 'exports project uploads and avatar' do
      service.execute

      expect(File).to exist(File.join(export_path, 'avatar', 'rails_sample.png'))
      expect(File).to exist(exported_filepath)
    end

    context 'when export is batched' do
      it 'exports only specified uploads' do
        service.execute(batch_ids: [upload.id])

        expect(service.exported_objects_count).to eq(1)
        expect(File).not_to exist(File.join(export_path, 'avatar', 'rails_sample.png'))
        expect(File).to exist(exported_filepath)
      end
    end

    context 'when upload has underlying file missing' do
      context 'with an upload missing its file' do
        it 'does not cause errors' do
          File.delete(upload.absolute_path)

          expect { service.execute }.not_to raise_error

          expect(File).not_to exist(exported_filepath)
        end
      end

      context 'when upload is in object storage' do
        before do
          stub_uploads_object_storage(FileUploader)
        end

        shared_examples 'export with invalid upload' do
          it 'ignores problematic upload and logs exception' do
            allow(service).to receive(:download_or_copy_upload).and_raise(exception)

            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(
                instance_of(exception), {
                  portable_id: project.id,
                  portable_class: 'Project',
                  upload_id: upload.id
                }
              )

            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(
                instance_of(exception), {
                  portable_id: project.id,
                  portable_class: 'Project',
                  upload_id: project.avatar.upload.id
                }
              )

            service.execute

            expect(File).not_to exist(exported_filepath)
          end
        end

        context 'when filename is too long' do
          let(:exception) { Errno::ENAMETOOLONG }

          include_examples 'export with invalid upload'
        end

        context 'when network exception occurs' do
          let(:exception) { Net::OpenTimeout }

          include_examples 'export with invalid upload'
        end
      end
    end
  end

  describe '#exported_objects_count' do
    it 'return the number of exported uploads' do
      service.execute

      expect(service.exported_objects_count).to eq(2)
    end
  end
end
