# rubocop:disable RSpec/FilePath
require 'spec_helper'

describe Projects::DestroyService, services: true do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let!(:project_id) { project.id }
  let!(:project_name) { project.name }
  let!(:project_path) { project.path_with_namespace }
  let!(:wiki_path) { project.path_with_namespace + '.wiki' }
  let!(:storage_name) { project.repository_storage }
  let!(:storage_path) { project.repository_storage_path }

  subject { described_class.new(project, user, {}) }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  context 'when running on a primary node' do
    let!(:geo_node) { create(:geo_node, :primary, :current) }

    it 'logs an event to the Geo event log' do
      # Run sidekiq immediatly to check that renamed repository will be removed
      Sidekiq::Testing.inline! do
        expect { subject.execute }.to change(Geo::RepositoryDeletedEvent, :count).by(1)
      end
    end
  end
end
