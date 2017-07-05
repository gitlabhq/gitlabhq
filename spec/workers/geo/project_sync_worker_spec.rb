require 'rails_helper'

RSpec.describe Geo::ProjectSyncWorker do
  subject { described_class.new }

  describe '#perform' do
    let(:project) { create(:empty_project) }
    let(:repository_sync_service) { spy }

    it 'performs Geo::RepositorySyncService for the given project' do
      allow(Geo::RepositorySyncService).to receive(:new)
        .with(project.id).once.and_return(repository_sync_service)

      subject.perform(project.id, Time.now)

      expect(repository_sync_service).to have_received(:execute).once
    end
  end
end
