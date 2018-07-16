require 'spec_helper'

describe Projects::HashedStorage::MigrateAttachmentsService do
  subject(:service) { described_class.new(project, project.full_path, logger: nil) }
  let(:project) { create(:project, :legacy_storage) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  let!(:upload) { Upload.find_by(path: file_uploader.upload_path) }
  let(:file_uploader) { build(:file_uploader, project: project) }
  let(:old_path) { File.join(base_path(legacy_storage), upload.path) }
  let(:new_path) { File.join(base_path(hashed_storage), upload.path) }

  context '#execute' do
    context 'when succeeds' do
      it 'moves attachments to hashed storage layout' do
        expect(File.file?(old_path)).to be_truthy
        expect(File.file?(new_path)).to be_falsey
        expect(File.exist?(base_path(legacy_storage))).to be_truthy
        expect(File.exist?(base_path(hashed_storage))).to be_falsey
        expect(FileUtils).to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage)).and_call_original

        service.execute

        expect(File.exist?(base_path(hashed_storage))).to be_truthy
        expect(File.exist?(base_path(legacy_storage))).to be_falsey
        expect(File.file?(old_path)).to be_falsey
        expect(File.file?(new_path)).to be_truthy
      end
    end

    context 'when original folder does not exist anymore' do
      before do
        FileUtils.rm_rf(base_path(legacy_storage))
      end

      it 'skips moving folders and go to next' do
        expect(FileUtils).not_to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage))

        service.execute

        expect(File.exist?(base_path(hashed_storage))).to be_falsey
        expect(File.file?(new_path)).to be_falsey
      end
    end

    context 'when target folder already exists' do
      before do
        FileUtils.mkdir_p(base_path(hashed_storage))
      end

      it 'raises AttachmentMigrationError' do
        expect(FileUtils).not_to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage))

        expect { service.execute }.to raise_error(Projects::HashedStorage::AttachmentMigrationError)
      end
    end

    context 'when old_path does not match full_path' do
      let(:old_path) { 'old-path' }
      let(:logger) { double }
      subject(:service) { described_class.new(project, old_path, logger: logger) }

      it 'uses old_path parameter' do
        expect(logger).to receive(:info).with(/source path doesn\'t exist or is not a directory/)

        service.execute

        expect(service.old_path).to eq old_path
      end
    end
  end

  def base_path(storage)
    File.join(FileUploader.root, storage.disk_path)
  end
end
