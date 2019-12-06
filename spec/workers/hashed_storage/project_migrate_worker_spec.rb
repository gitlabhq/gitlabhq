# frozen_string_literal: true

require 'spec_helper'

describe HashedStorage::ProjectMigrateWorker, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  let(:migration_service) { ::Projects::HashedStorage::MigrationService }
  let(:lease_timeout) { described_class::LEASE_TIMEOUT }

  describe '#perform' do
    it 'skips when project no longer exists' do
      stub_exclusive_lease(lease_key(-1), 'uuid', timeout: lease_timeout)

      expect(migration_service).not_to receive(:new)

      subject.perform(-1)
    end

    it 'skips when project is pending delete' do
      pending_delete_project = create(:project, :empty_repo, pending_delete: true)
      stub_exclusive_lease(lease_key(pending_delete_project.id), 'uuid', timeout: lease_timeout)

      expect(migration_service).not_to receive(:new)

      subject.perform(pending_delete_project.id)
    end

    it 'skips when project is already migrated' do
      migrated_project = create(:project, :empty_repo)
      stub_exclusive_lease(lease_key(migrated_project.id), 'uuid', timeout: lease_timeout)

      expect(migration_service).not_to receive(:new)

      subject.perform(migrated_project.id)
    end

    context 'with exclusive lease available' do
      it 'delegates migration to service class' do
        project = create(:project, :empty_repo, :legacy_storage)
        stub_exclusive_lease(lease_key(project.id), 'uuid', timeout: lease_timeout)

        service_spy = spy

        allow(migration_service)
          .to receive(:new).with(project, project.full_path, logger: subject.logger)
                .and_return(service_spy)

        subject.perform(project.id)

        expect(service_spy).to have_received(:execute)
      end

      it 'delegates migration to service class with correct path in a partially migrated project' do
        project = create(:project, :empty_repo, storage_version: 1)
        stub_exclusive_lease(lease_key(project.id), 'uuid', timeout: lease_timeout)

        service_spy = spy

        allow(migration_service)
          .to receive(:new).with(project, project.full_path, logger: subject.logger)
                .and_return(service_spy)

        subject.perform(project.id)

        expect(service_spy).to have_received(:execute)
      end
    end

    context 'with exclusive lease taken' do
      it 'skips when it cant acquire the exclusive lease' do
        project = create(:project, :empty_repo, :legacy_storage)
        stub_exclusive_lease_taken(lease_key(project.id), timeout: lease_timeout)

        expect(migration_service).not_to receive(:new)

        subject.perform(project.id)
      end
    end
  end

  def lease_key(key)
    "project_migrate_hashed_storage_worker:#{key}"
  end
end
