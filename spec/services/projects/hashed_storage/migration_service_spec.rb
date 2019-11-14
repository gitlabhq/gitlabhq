# frozen_string_literal: true

require 'spec_helper'

describe Projects::HashedStorage::MigrationService do
  let(:project) { create(:project, :empty_repo, :wiki_repo, :legacy_storage) }
  let(:logger) { double }

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
    end

    context 'attachments migration' do
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
    end
  end
end
