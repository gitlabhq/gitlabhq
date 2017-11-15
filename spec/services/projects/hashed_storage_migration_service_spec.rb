require 'spec_helper'

describe Projects::HashedStorageMigrationService do
  let(:project) { create(:project, :empty_repo, :wiki_repo) }
  subject(:service) { described_class.new(project) }

  describe '#execute' do
    context 'repository migration' do
      it 'delegates migration to Projects::HashedStorage::MigrateRepositoryService' do
        expect(Projects::HashedStorage::MigrateRepositoryService).to receive(:new).with(project, subject.logger).and_call_original
        expect_any_instance_of(Projects::HashedStorage::MigrateRepositoryService).to receive(:execute)

        service.execute
      end

      it 'does not delegate migration if repository is already migrated' do
        project.storage_version = ::Project::LATEST_STORAGE_VERSION
        expect_any_instance_of(Projects::HashedStorage::MigrateRepositoryService).not_to receive(:execute)

        service.execute
      end
    end

    context 'attachments migration' do
      it 'delegates migration to Projects::HashedStorage::MigrateRepositoryService' do
        expect(Projects::HashedStorage::MigrateAttachmentsService).to receive(:new).with(project, subject.logger).and_call_original
        expect_any_instance_of(Projects::HashedStorage::MigrateAttachmentsService).to receive(:execute)

        service.execute
      end

      it 'does not delegate migration if attachments are already migrated' do
        project.storage_version = ::Project::LATEST_STORAGE_VERSION
        expect_any_instance_of(Projects::HashedStorage::MigrateAttachmentsService).not_to receive(:execute)

        service.execute
      end
    end
  end
end
