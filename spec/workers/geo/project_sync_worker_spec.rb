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

    it 'does not raise an error when project could not be found' do
      expect { subject.perform(999, Time.now) }.not_to raise_error
    end
  end
end
