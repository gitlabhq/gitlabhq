require 'spec_helper'

describe ProjectMigrateHashedStorageWorker do
  describe '#perform' do
    let(:project) { create(:project, :empty_repo) }
    let(:pending_delete_project) { create(:project, :empty_repo, pending_delete: true) }

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
end
