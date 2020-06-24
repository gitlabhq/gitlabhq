# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HashedStorage::ProjectRollbackWorker, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let(:project) { create(:project, :empty_repo) }
    let(:lease_key) { "project_migrate_hashed_storage_worker:#{project.id}" }
    let(:lease_timeout) { described_class::LEASE_TIMEOUT }
    let(:rollback_service) { ::Projects::HashedStorage::RollbackService }

    it 'skips when project no longer exists' do
      expect(rollback_service).not_to receive(:new)

      subject.perform(-1)
    end

    it 'skips when project is pending delete' do
      pending_delete_project = create(:project, :empty_repo, pending_delete: true)

      expect(rollback_service).not_to receive(:new)

      subject.perform(pending_delete_project.id)
    end

    it 'delegates rollback to service class when have exclusive lease' do
      stub_exclusive_lease(lease_key, 'uuid', timeout: lease_timeout)

      service_spy = spy

      allow(rollback_service)
        .to receive(:new).with(project, project.disk_path, logger: subject.logger)
        .and_return(service_spy)

      subject.perform(project.id)

      expect(service_spy).to have_received(:execute)
    end

    it 'skips when it cant acquire the exclusive lease' do
      stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

      expect(rollback_service).not_to receive(:new)

      subject.perform(project.id)
    end
  end
end
