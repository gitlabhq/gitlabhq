require 'spec_helper'

describe Projects::HashedStorage::MigrateAttachmentsService do
  subject(:service) { described_class.new(project) }
  let(:project) { create(:project) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  let!(:upload) { Upload.find_by(path: file_uploader.relative_path) }
  let(:file_uploader) { build(:file_uploader, project: project) }
  let(:old_path) { attachments_path(legacy_storage, upload) }
  let(:new_path) { attachments_path(hashed_storage, upload) }

  let(:other_file_uploader) { build(:file_uploader, project: project) }
  let(:other_old_path) { attachments_path(legacy_storage, other_upload) }
  let(:other_new_path) { attachments_path(hashed_storage, other_upload) }

  context '#execute' do
    context 'when succeeds' do
      it 'moves attachments to hashed storage layout' do
        expect(File.file?(old_path)).to be_truthy
        expect(File.file?(new_path)).to be_falsey

        service.execute

        expect(File.file?(old_path)).to be_falsey
        expect(File.file?(new_path)).to be_truthy
      end
    end

    context 'when original file does not exist anymore' do
      let!(:other_upload) { Upload.find_by(path: other_file_uploader.relative_path) }

      before do
        File.unlink(old_path)
      end

      it 'skips moving the file and goes to next' do
        expect(FileUtils).not_to receive(:mv).with(old_path, new_path)
        expect(FileUtils).to receive(:mv).with(other_old_path, other_new_path).and_call_original

        service.execute

        expect(File.file?(new_path)).to be_falsey
        expect(File.file?(other_new_path)).to be_truthy
      end
    end

    context 'when target file already exists' do
      let!(:other_upload) { Upload.find_by(path: other_file_uploader.relative_path) }

      before do
        FileUtils.mkdir_p(File.dirname(new_path))
        FileUtils.touch(new_path)
      end

      it 'skips moving the file and goes to next' do
        expect(FileUtils).not_to receive(:mv).with(old_path, new_path)
        expect(FileUtils).to receive(:mv).with(other_old_path, other_new_path).and_call_original
        expect(File.file?(new_path)).to be_truthy

        service.execute

        expect(File.file?(old_path)).to be_truthy
      end
    end
  end

  def attachments_path(storage, upload)
    File.join(CarrierWave.root, FileUploader.base_dir, storage.disk_path, upload.path)
  end
end
