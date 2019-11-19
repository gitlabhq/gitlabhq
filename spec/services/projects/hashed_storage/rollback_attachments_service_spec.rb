# frozen_string_literal: true

require 'spec_helper'

describe Projects::HashedStorage::RollbackAttachmentsService do
  subject(:service) { described_class.new(project: project, old_disk_path: project.disk_path, logger: nil) }

  let(:project) { create(:project, :repository, skip_disk_validation: true) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  let!(:upload) { Upload.find_by(path: file_uploader.upload_path) }
  let(:file_uploader) { build(:file_uploader, project: project) }
  let(:old_disk_path) { File.join(base_path(hashed_storage), upload.path) }
  let(:new_disk_path) { File.join(base_path(legacy_storage), upload.path) }

  context '#execute' do
    context 'when succeeds' do
      it 'moves attachments to legacy storage layout' do
        expect(File.file?(old_disk_path)).to be_truthy
        expect(File.file?(new_disk_path)).to be_falsey
        expect(File.exist?(base_path(hashed_storage))).to be_truthy
        expect(File.exist?(base_path(legacy_storage))).to be_falsey
        expect(FileUtils).to receive(:mv).with(base_path(hashed_storage), base_path(legacy_storage)).and_call_original

        service.execute

        expect(File.exist?(base_path(legacy_storage))).to be_truthy
        expect(File.exist?(base_path(hashed_storage))).to be_falsey
        expect(File.file?(old_disk_path)).to be_falsey
        expect(File.file?(new_disk_path)).to be_truthy
      end

      it 'returns true' do
        expect(service.execute).to be_truthy
      end

      it 'sets skipped to false' do
        service.execute

        expect(service.skipped?).to be_falsey
      end
    end

    context 'when original folder does not exist anymore' do
      before do
        FileUtils.rm_rf(base_path(hashed_storage))
      end

      it 'skips moving folders and go to next' do
        expect(FileUtils).not_to receive(:mv).with(base_path(hashed_storage), base_path(legacy_storage))

        service.execute

        expect(File.exist?(base_path(legacy_storage))).to be_falsey
        expect(File.file?(new_disk_path)).to be_falsey
      end

      it 'returns true' do
        expect(service.execute).to be_truthy
      end

      it 'sets skipped to true' do
        service.execute

        expect(service.skipped?).to be_truthy
      end
    end

    context 'when target folder already exists' do
      before do
        FileUtils.mkdir_p(base_path(legacy_storage))
      end

      it 'raises AttachmentCannotMoveError' do
        expect(FileUtils).not_to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage))

        expect { service.execute }.to raise_error(Projects::HashedStorage::AttachmentCannotMoveError)
      end
    end

    it 'works even when project validation fails' do
      allow(project).to receive(:valid?) { false }

      expect { service.execute }.to change { project.hashed_storage?(:attachments) }.to(false)
    end
  end

  context '#old_disk_path' do
    it 'returns old disk_path for project' do
      expect(service.old_disk_path).to eq(project.disk_path)
    end
  end

  context '#new_disk_path' do
    it 'returns new disk_path for project' do
      service.execute

      expect(service.new_disk_path).to eq(project.full_path)
    end
  end

  def base_path(storage)
    File.join(FileUploader.root, storage.disk_path)
  end
end
