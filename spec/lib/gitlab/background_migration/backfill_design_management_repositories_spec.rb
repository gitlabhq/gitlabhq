# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(
  Gitlab::BackgroundMigration::BackfillDesignManagementRepositories,
  schema: 20230406121544,
  feature_category: :geo_replication
) do
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:design_management_repositories) { table(:design_management_repositories) }

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
    it 'creates design_management_repositories entries for all projects in range' do
      namespace1 = create_namespace('test1')
      namespace2 = create_namespace('test2')
      project1 = create_project(namespace1, 'test1')
      project2 = create_project(namespace2, 'test2')
      design_management_repositories.create!(project_id: project2.id)

      expect { migration.perform }
        .to change { design_management_repositories.pluck(:project_id) }
        .from([project2.id])
        .to match_array([project1.id, project2.id])
    end

    context 'when project_id already exists in design_management_repositories' do
      it "doesn't duplicate project_id" do
        namespace = create_namespace('test1')
        project = create_project(namespace, 'test1')
        design_management_repositories.create!(project_id: project.id)

        expect { migration.perform }
          .not_to change { design_management_repositories.pluck(:project_id) }
      end
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
