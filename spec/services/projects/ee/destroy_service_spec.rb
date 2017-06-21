# rubocop:disable RSpec/FilePath
require 'spec_helper'

describe Projects::DestroyService, services: true do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let!(:project_id) { project.id }
  let!(:project_name) { project.name }
  let!(:project_path) { project.path_with_namespace }
  let!(:wiki_path) { project.path_with_namespace + '.wiki' }
  let!(:storage_path) { project.repository_storage_path }
  let!(:geo_node) { create(:geo_node, :primary, :current) }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  context 'Geo primary' do
    it 'logs the event' do
      # Run sidekiq immediatly to check that renamed repository will be removed
      Sidekiq::Testing.inline! { destroy_project(project, user, {}) }

      event = Geo::RepositoryDeletedEvent.first

      expect(Geo::EventLog.count).to eq(1)
      expect(Geo::RepositoryDeletedEvent.count).to eq(1)
      expect(event.project_id).to eq(project_id)
      expect(event.deleted_path).to eq(project_path)
      expect(event.deleted_wiki_path).to eq(wiki_path)
      expect(event.deleted_project_name).to eq(project_name)
      expect(event.repository_storage_path).to eq(storage_path)
    end
  end

  def destroy_project(project, user, params = {})
    described_class.new(project, user, params).execute
  end
end
