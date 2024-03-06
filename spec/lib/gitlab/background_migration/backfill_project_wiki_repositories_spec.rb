# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(
  Gitlab::BackgroundMigration::BackfillProjectWikiRepositories,
  schema: 20230616082958,
  feature_category: :geo_replication) do
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:project_wiki_repositories) { table(:project_wiki_repositories) }

  subject(:migration) do
    described_class.new(
      start_id: projects.minimum(:id),
      end_id: projects.maximum(:id),
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    )
  end

  describe '#perform' do
    it 'creates project_wiki_repositories entries for all projects in range' do
      namespace1 = create_namespace('test1')
      namespace2 = create_namespace('test2')
      project1 = create_project(namespace1, 'test1')
      project2 = create_project(namespace2, 'test2')
      project_wiki_repositories.create!(project_id: project2.id)

      expect { migration.perform }
        .to change { project_wiki_repositories.pluck(:project_id) }
        .from([project2.id])
        .to match_array([project1.id, project2.id])
    end

    it 'does nothing if project_id already exist in project_wiki_repositories' do
      namespace = create_namespace('test1')
      project = create_project(namespace, 'test1')
      project_wiki_repositories.create!(project_id: project.id)

      expect { migration.perform }
        .not_to change { project_wiki_repositories.pluck(:project_id) }
    end

    def create_namespace(name)
      namespaces.create!(
        name: name,
        path: name,
        type: 'Project'
      )
    end

    def create_project(namespace, name)
      projects.create!(
        namespace_id: namespace.id,
        project_namespace_id: namespace.id,
        name: name,
        path: name
      )
    end
  end
end
