require 'spec_helper'

describe ProjectMigrateHashedStorageWorker, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let(:project) { create(:project, :empty_repo) }
    let(:lease_key) { "project_migrate_hashed_storage_worker:#{project.id}" }
    let(:lease_timeout) { ProjectMigrateHashedStorageWorker::LEASE_TIMEOUT }

    it 'skips when project no longer exists' do
      expect(::Projects::HashedStorageMigrationService).not_to receive(:new)

      subject.perform(-1)
    end

    it 'skips when project is pending delete' do
      pending_delete_project = create(:project, :empty_repo, pending_delete: true)

      expect(::Projects::HashedStorageMigrationService).not_to receive(:new)

      subject.perform(pending_delete_project.id)
    end

    it 'delegates removal to service class when have exclusive lease' do
      stub_exclusive_lease(lease_key, 'uuid', timeout: lease_timeout)

      migration_service = spy

      allow(::Projects::HashedStorageMigrationService)
        .to receive(:new).with(project, project.full_path, logger: subject.logger)
        .and_return(migration_service)

      subject.perform(project.id)

      expect(migration_service).to have_received(:execute)
    end

    it 'skips when dont have lease when dont have exclusive lease' do
      stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

      expect(::Projects::HashedStorageMigrationService).not_to receive(:new)

      subject.perform(project.id)
    end
  end
end
