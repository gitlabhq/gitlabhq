# frozen_string_literal: true

module MigrationHelpers
  module ProjectStatisticsHelper
    def generate_records(projects, table, values = {})
      projects.map do |proj|
        table.create!(
          values.merge({
            project_id: proj.id,
            namespace_id: proj.namespace_id
          })
        )
      end
    end

    def create_migration(end_id:)
      described_class.new(start_id: 1, end_id: end_id,
        batch_table: 'project_statistics', batch_column: 'project_id',
        sub_batch_size: 1_000, pause_ms: 0,
        connection: ApplicationRecord.connection)
    end

    def create_project_stats(project_table, namespace, default_stats, override_stats = {})
      stats = default_stats.merge(override_stats)

      group = namespace.create!(name: 'group_a', path: 'group-a', type: 'Group')
      project_namespace = namespace.create!(name: 'project_a', path: 'project_a', type: 'Project', parent_id: group.id)
      proj = project_table.create!(name: 'project_a', path: 'project-a', namespace_id: group.id,
        project_namespace_id: project_namespace.id)
      project_statistics_table.create!(
        project_id: proj.id,
        namespace_id: group.id,
        **stats
      )
    end
  end
end
