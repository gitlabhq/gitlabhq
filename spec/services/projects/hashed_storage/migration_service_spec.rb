# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HashedStorage::MigrationService do
  let(:project) { create(:project, :empty_repo, :wiki_repo, :legacy_storage) }
  let(:logger) { double }
  let!(:project_attachment) { build(:file_uploader, project: project) }
  let(:project_hashed_path) { Storage::Hashed.new(project).disk_path }
  let(:project_legacy_path) { Storage::LegacyProject.new(project).disk_path }
  let(:wiki_hashed_path) { "#{project_hashed_path}.wiki" }
  let(:wiki_legacy_path) { "#{project_legacy_path}.wiki" }

  subject(:service) { described_class.new(project, project.full_path, logger: logger) }

  describe '#execute' do
    context 'repository migration' do
      let(:repository_service) do
        Projects::HashedStorage::MigrateRepositoryService.new(project: project,
                                                              old_disk_path: project.full_path,
                                                              logger: logger)
      end

      it 'delegates migration to Projects::HashedStorage::MigrateRepositoryService' do
        expect(service).to receive(:migrate_repository_service).and_return(repository_service)
        expect(repository_service).to receive(:execute)

        service.execute
      end

      it 'does not delegate migration if repository is already migrated' do
        project.storage_version = ::Project::LATEST_STORAGE_VERSION
        expect(Projects::HashedStorage::MigrateRepositoryService).not_to receive(:new)

        service.execute
      end

      it 'migrates legacy repositories to hashed storage' do
        legacy_attachments_path = FileUploader.absolute_base_dir(project)
        hashed_project = project.dup.tap { |p| p.id = project.id }
        hashed_project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:attachments]
        hashed_attachments_path = FileUploader.absolute_base_dir(hashed_project)

        expect(logger).to receive(:info).with(/Repository moved from '#{project_legacy_path}' to '#{project_hashed_path}'/)
        expect(logger).to receive(:info).with(/Repository moved from '#{wiki_legacy_path}' to '#{wiki_hashed_path}'/)
        expect(logger).to receive(:info).with(/Project attachments moved from '#{legacy_attachments_path}' to '#{hashed_attachments_path}'/)

        expect { service.execute }.to change { project.storage_version }.from(nil).to(2)
      end
    end

    context 'attachments migration' do
      let(:project) { create(:project, :empty_repo, :wiki_repo, storage_version: ::Project::HASHED_STORAGE_FEATURES[:repository]) }

      let(:attachments_service) do
        Projects::HashedStorage::MigrateAttachmentsService.new(project: project,
                                                               old_disk_path: project.full_path,
                                                               logger: logger)
      end

      it 'delegates migration to Projects::HashedStorage::MigrateRepositoryService' do
        expect(service).to receive(:migrate_attachments_service).and_return(attachments_service)
        expect(attachments_service).to receive(:execute)

        service.execute
      end

      it 'does not delegate migration if attachments are already migrated' do
        project.storage_version = ::Project::LATEST_STORAGE_VERSION
        expect(Projects::HashedStorage::MigrateAttachmentsService).not_to receive(:new)

        service.execute
      end

      it 'migrates legacy attachments to hashed storage' do
        legacy_attachments_path = FileUploader.absolute_base_dir(project)
        hashed_project = project.dup.tap { |p| p.id = project.id }
        hashed_project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:attachments]
        hashed_attachments_path = FileUploader.absolute_base_dir(hashed_project)

        expect(logger).to receive(:info).with(/Project attachments moved from '#{legacy_attachments_path}' to '#{hashed_attachments_path}'/)

        expect { service.execute }.to change { project.storage_version }.from(1).to(2)
      end
    end
  end
end
