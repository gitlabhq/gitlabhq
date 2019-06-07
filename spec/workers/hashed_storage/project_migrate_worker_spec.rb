# frozen_string_literal: true

require 'spec_helper'

describe HashedStorage::ProjectMigrateWorker, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let(:project) { create(:project, :empty_repo, :legacy_storage) }
    let(:lease_key) { "project_migrate_hashed_storage_worker:#{project.id}" }
    let(:lease_timeout) { described_class::LEASE_TIMEOUT }
    let(:migration_service) { ::Projects::HashedStorage::MigrationService }

    it 'skips when project no longer exists' do
      expect(migration_service).not_to receive(:new)

      subject.perform(-1)
    end

    it 'skips when project is pending delete' do
      pending_delete_project = create(:project, :empty_repo, pending_delete: true)

      expect(migration_service).not_to receive(:new)

      subject.perform(pending_delete_project.id)
    end

    it 'delegates migration to service class when we have exclusive lease' do
      stub_exclusive_lease(lease_key, 'uuid', timeout: lease_timeout)

      service_spy = spy

      allow(migration_service)
        .to receive(:new).with(project, project.full_path, logger: subject.logger)
        .and_return(service_spy)

      subject.perform(project.id)

      expect(service_spy).to have_received(:execute)
    end

    it 'skips when it cant acquire the exclusive lease' do
      stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

      expect(migration_service).not_to receive(:new)

      subject.perform(project.id)
    end
  end
end
