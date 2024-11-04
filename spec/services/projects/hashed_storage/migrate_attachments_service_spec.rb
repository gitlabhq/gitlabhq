# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HashedStorage::MigrateAttachmentsService, feature_category: :groups_and_projects do
  subject(:service) { described_class.new(project: project, old_disk_path: project.full_path, logger: nil) }

  let(:project) { create(:project, :repository, storage_version: 1, skip_disk_validation: true) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::Hashed.new(project) }

  let!(:upload) { Upload.find_by(path: file_uploader.upload_path) }
  let(:file_uploader) { build(:file_uploader, container: project) }
  let(:old_disk_path) { File.join(base_path(legacy_storage), upload.path) }
  let(:new_disk_path) { File.join(base_path(hashed_storage), upload.path) }

  describe '#execute' do
    context 'when succeeds' do
      it 'moves attachments to hashed storage layout' do
        expect(File.file?(old_disk_path)).to be_truthy
        expect(File.file?(new_disk_path)).to be_falsey
        expect(File.exist?(base_path(legacy_storage))).to be_truthy
        expect(File.exist?(base_path(hashed_storage))).to be_falsey
        expect(FileUtils).to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage)).and_call_original

        service.execute

        expect(File.exist?(base_path(hashed_storage))).to be_truthy
        expect(File.exist?(base_path(legacy_storage))).to be_falsey
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
        FileUtils.rm_rf(base_path(legacy_storage))
      end

      it 'skips moving folders and go to next' do
        expect(FileUtils).not_to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage))

        service.execute

        expect(File.exist?(base_path(hashed_storage))).to be_falsey
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
        FileUtils.mkdir_p(base_path(hashed_storage))
      end

      it 'succeed when target is empty' do
        expect { service.execute }.not_to raise_error
      end

      it 'succeed when target include only discardable items' do
        Projects::HashedStorage::MigrateAttachmentsService::DISCARDABLE_PATHS.each do |path_fragment|
          discardable_path = File.join(base_path(hashed_storage), path_fragment)
          FileUtils.mkdir_p(discardable_path)
        end

        expect { service.execute }.not_to raise_error
      end

      it 'raises AttachmentCannotMoveError when there are non discardable items on target path' do
        not_discardable_path = File.join(base_path(hashed_storage), 'something')
        FileUtils.mkdir_p(not_discardable_path)

        expect(FileUtils).not_to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage))

        expect { service.execute }.to raise_error(Projects::HashedStorage::AttachmentCannotMoveError)
      end
    end

    it 'works even when project validation fails' do
      allow(project).to receive(:valid?) { false }

      expect { service.execute }.to change { project.hashed_storage?(:attachments) }.to(true)
    end
  end

  describe '#old_disk_path' do
    it 'returns old disk_path for project' do
      expect(service.old_disk_path).to eq(project.full_path)
    end
  end

  describe '#new_disk_path' do
    it 'returns new disk_path for project' do
      service.execute

      expect(service.new_disk_path).to eq(project.disk_path)
    end
  end

  describe '#target_path_discardable?' do
    it 'returns true when it include only items on the discardable list' do
      hashed_attachments_path = File.join(base_path(hashed_storage))
      Projects::HashedStorage::MigrateAttachmentsService::DISCARDABLE_PATHS.each do |path_fragment|
        discardable_path = File.join(hashed_attachments_path, path_fragment)
        FileUtils.mkdir_p(discardable_path)
      end

      expect(service.target_path_discardable?(hashed_attachments_path)).to be_truthy
    end
  end

  def base_path(storage)
    File.join(FileUploader.root, storage.disk_path)
  end
end
