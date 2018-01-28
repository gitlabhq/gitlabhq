require 'spec_helper'

describe ProjectMigrateHashedStorageWorker, :clean_gitlab_redis_shared_state do
  describe '#perform' do
    let(:project) { create(:project, :empty_repo) }
    let(:pending_delete_project) { create(:project, :empty_repo, pending_delete: true) }

    context 'when have exclusive lease' do
      before do
        lease = subject.lease_for(project.id)

        allow(Gitlab::ExclusiveLease).to receive(:new).and_return(lease)
        allow(lease).to receive(:try_obtain).and_return(true)
      end

      it 'skips when project no longer exists' do
        nonexistent_id = 999999999999

        expect(::Projects::HashedStorageMigrationService).not_to receive(:new)
        subject.perform(nonexistent_id)
      end

      it 'skips when project is pending delete' do
        expect(::Projects::HashedStorageMigrationService).not_to receive(:new)

        subject.perform(pending_delete_project.id)
      end

      it 'delegates removal to service class' do
        service = double('service')
        expect(::Projects::HashedStorageMigrationService).to receive(:new).with(project, subject.logger).and_return(service)
        expect(service).to receive(:execute)

        subject.perform(project.id)
      end
    end

    context 'when dont have exclusive lease' do
      before do
        lease = subject.lease_for(project.id)

        allow(Gitlab::ExclusiveLease).to receive(:new).and_return(lease)
        allow(lease).to receive(:try_obtain).and_return(false)
      end

      it 'skips when dont have lease' do
        expect(::Projects::HashedStorageMigrationService).not_to receive(:new)

        subject.perform(project.id)
      end
    end
  end
end
