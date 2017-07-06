require 'spec_helper'

describe Geo::RepositoryDeletedEventStore, services: true do
  let(:project) { create(:empty_project, path: 'bar') }
  let!(:project_id) { project.id }
  let!(:project_name) { project.name }
  let!(:repo_path) { project.full_path }
  let!(:wiki_path) { "#{project.full_path}.wiki" }
  let!(:storage_name) { project.repository_storage }
  let!(:storage_path) { project.repository_storage_path }

  subject { described_class.new(project, repo_path: repo_path, wiki_path: wiki_path) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { subject.create }.not_to change(Geo::RepositoryDeletedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'creates a deleted event' do
        expect { subject.create }.to change(Geo::RepositoryDeletedEvent, :count).by(1)
      end

      it 'tracks information for the deleted project' do
        subject.create

        event = Geo::RepositoryDeletedEvent.last

        expect(event.project_id).to eq(project_id)
        expect(event.deleted_path).to eq(repo_path)
        expect(event.deleted_wiki_path).to eq(wiki_path)
        expect(event.deleted_project_name).to eq(project_name)
        expect(event.repository_storage_name).to eq(storage_name)
        expect(event.repository_storage_path).to eq(storage_path)
      end
    end
  end
end
