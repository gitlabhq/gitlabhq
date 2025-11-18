# frozen_string_literal: true

module ClickHouseHelpers
  extend ActiveRecord::ConnectionAdapters::Quoting

  def insert_events_into_click_house(events = Event.all)
    # Insert into both events table until legacy table is removed
    %i[events events_new].each do |clickhouse_table_name|
      clickhouse_fixture(clickhouse_table_name, events.map do |event|
        project_namespace = event.project.reload.project_namespace
        include_organization_on_path = clickhouse_table_name == :events_new
        path = project_namespace.traversal_path(with_organization: include_organization_on_path)

        {
          id: event.id,
          path: path,
          author_id: event.author_id,
          # The target* getters for Event/PushEvent are overriden. We need to use `read_attribute`
          # to copy the true value.
          target_id: event.read_attribute(:target_id),
          target_type: event.read_attribute(:target_type),
          action: Event.actions[event.action],
          created_at: event.created_at,
          updated_at: event.updated_at
        }
      end)
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity -- the method is straightforward, just a lot of &.
  # rubocop:disable Metrics/PerceivedComplexity -- same
  def insert_ci_builds_to_click_house(builds)
    result = clickhouse_fixture(:ci_finished_builds, builds.map do |build|
      build.slice(
        %i[id project_id pipeline_id status finished_at created_at started_at queued_at runner_id name
          stage_id]).symbolize_keys
          .merge(
            runner_run_untagged: build.runner&.run_untagged,
            runner_type: Ci::Runner.runner_types[build.runner&.runner_type],
            runner_owner_namespace_id: build.runner&.owner_runner_namespace&.namespace_id,
            runner_manager_system_xid: build.runner_manager&.system_xid,
            runner_manager_version: build.runner_manager&.version || '',
            runner_manager_revision: build.runner_manager&.revision || '',
            runner_manager_platform: build.runner_manager&.platform || '',
            runner_manager_architecture: build.runner_manager&.architecture || ''
          )
    end)

    expect(result).to eq(true)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def insert_ci_pipelines_to_click_house(pipelines)
    result = clickhouse_fixture(:ci_finished_pipelines, pipelines.map do |pipeline|
      pipeline.slice(
        %i[id duration status source ref committed_at created_at started_at finished_at]).symbolize_keys
           .merge(
             path: pipeline.project&.project_namespace&.traversal_path || '0/'
           )
    end)

    expect(result).to eq(true)
  end

  def self.default_timezone
    ActiveRecord.default_timezone
  end

  def clickhouse_fixture(table, data, db = :main)
    return if data.empty?

    if data.map { |row| row.keys.sort }.uniq.size > 1
      raise "Data is inconsistent! Make sure all data object have the same structure"
    end

    structure = data.first.keys

    rows = data.map do |row|
      cols = structure.map do |col|
        val = row[col].is_a?(Hash) ? row[col].to_json : row[col]
        ClickHouseHelpers.quote(val)
      end

      "(#{cols.join(', ')})"
    end

    query = "INSERT INTO #{table} (#{structure.join(', ')}) VALUES #{rows.join(',')}"

    ClickHouse::Client.execute(query, db)
  end
end
