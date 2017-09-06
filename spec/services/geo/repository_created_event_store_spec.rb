require 'spec_helper'

describe Geo::RepositoryCreatedEventStore do
  let(:project) { create(:project) }

  subject(:event) { described_class.new(project) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event.create }.not_to change(Geo::RepositoryCreatedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'creates a created event' do
        expect { event.create }.to change(Geo::RepositoryCreatedEvent, :count).by(1)
      end

      it 'tracks information for the created project' do
        event.create

        event = Geo::RepositoryCreatedEvent.last

        expect(event).to have_attributes(
          project_id: project.id,
          repo_path: project.disk_path,
          wiki_path: "#{project.disk_path}.wiki",
          project_name: project.name,
          repository_storage_name: project.repository_storage,
          repository_storage_path: project.repository_storage_path
        )
      end
    end
  end
end
