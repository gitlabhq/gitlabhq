# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HashedStorage::RollbackService do
  let(:project) { create(:project, :empty_repo, :wiki_repo) }
  let(:logger) { double }
  let!(:project_attachment) { build(:file_uploader, project: project) }
  let(:project_hashed_path) { Storage::Hashed.new(project).disk_path }
  let(:project_legacy_path) { Storage::LegacyProject.new(project).disk_path }
  let(:wiki_hashed_path) { "#{project_hashed_path}.wiki" }
  let(:wiki_legacy_path) { "#{project_legacy_path}.wiki" }

  subject(:service) { described_class.new(project, project.disk_path, logger: logger) }

  describe '#execute' do
    context 'attachments rollback' do
      let(:attachments_service_class) { Projects::HashedStorage::RollbackAttachmentsService }
      let(:attachments_service) { attachments_service_class.new(project: project, old_disk_path: project.disk_path, logger: logger) }

      it 'delegates rollback to Projects::HashedStorage::RollbackAttachmentsService' do
        expect(service).to receive(:rollback_attachments_service).and_return(attachments_service)
        expect(attachments_service).to receive(:execute)

        service.execute
      end

      it 'does not delegate rollback if repository is in legacy storage already' do
        project.storage_version = nil
        expect(attachments_service_class).not_to receive(:new)

        service.execute
      end

      it 'rollbacks to legacy storage' do
        hashed_attachments_path = FileUploader.absolute_base_dir(project)
        legacy_project = project.dup
        legacy_project.storage_version = nil
        legacy_attachments_path = FileUploader.absolute_base_dir(legacy_project)

        expect(logger).to receive(:info).with(/Project attachments moved from '#{hashed_attachments_path}' to '#{legacy_attachments_path}'/)

        expect(logger).to receive(:info).with(/Repository moved from '#{project_hashed_path}' to '#{project_legacy_path}'/)
        expect(logger).to receive(:info).with(/Repository moved from '#{wiki_hashed_path}' to '#{wiki_legacy_path}'/)

        expect { service.execute }.to change { project.storage_version }.from(2).to(nil)
      end
    end

    context 'repository rollback' do
      let(:project) { create(:project, :empty_repo, :wiki_repo, storage_version: ::Project::HASHED_STORAGE_FEATURES[:repository]) }
      let(:repository_service_class) { Projects::HashedStorage::RollbackRepositoryService }
      let(:repository_service) { repository_service_class.new(project: project, old_disk_path: project.disk_path, logger: logger) }

      it 'delegates rollback to RollbackRepositoryService' do
        expect(service).to receive(:rollback_repository_service).and_return(repository_service)
        expect(repository_service).to receive(:execute)

        service.execute
      end

      it 'does not delegate rollback if repository is in legacy storage already' do
        project.storage_version = nil

        expect(repository_service_class).not_to receive(:new)

        service.execute
      end

      it 'rollbacks to legacy storage' do
        expect(logger).to receive(:info).with(/Repository moved from '#{project_hashed_path}' to '#{project_legacy_path}'/)
        expect(logger).to receive(:info).with(/Repository moved from '#{wiki_hashed_path}' to '#{wiki_legacy_path}'/)

        expect { service.execute }.to change { project.storage_version }.from(1).to(nil)
      end
    end
  end
end
