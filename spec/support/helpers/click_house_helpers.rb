# frozen_string_literal: true

module ClickHouseHelpers
  extend ActiveRecord::ConnectionAdapters::Quoting

  def insert_events_into_click_house(events = Event.all)
    # Insert into both events table until legacy table is removed
    %i[events siphon_events].each do |clickhouse_table_name|
      clickhouse_fixture(clickhouse_table_name, events.map do |event|
        project_namespace = event.project.reload.project_namespace
        include_organization_on_path = clickhouse_table_name == :siphon_events
        path = project_namespace.traversal_path(with_organization: include_organization_on_path)

        {
          id: event.id,
          path: path,
          author_id: event.author_id,
          # The target* getters for Event/PushEvent are overridden. We need to use `read_attribute`
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
  def insert_ci_builds_to_click_house(builds, version: Time.current, deleted: false)
    result = clickhouse_fixture(:ci_finished_builds, builds.map do |build|
      build.slice(
        %i[id project_id pipeline_id status finished_at created_at started_at queued_at runner_id name
          stage_id]).symbolize_keys
          .merge(
            stage_name: build.stage_name,
            runner_run_untagged: build.runner&.run_untagged,
            runner_type: Ci::Runner.runner_types[build.runner&.runner_type],
            runner_owner_namespace_id: build.runner&.owner_runner_namespace&.namespace_id,
            runner_manager_system_xid: build.runner_manager&.system_xid,
            runner_manager_version: build.runner_manager&.version || '',
            runner_manager_revision: build.runner_manager&.revision || '',
            runner_manager_platform: build.runner_manager&.platform || '',
            runner_manager_architecture: build.runner_manager&.architecture || '',
            version: version,
            deleted: deleted
          )
    end)

    expect(result).to be(true)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def insert_merge_requests_to_click_house(merge_requests_data, default_project: nil)
    result = clickhouse_fixture(:merge_requests, merge_requests_data.map do |data|
      project = data[:project] || default_project

      {
        id: data[:id],
        iid: data[:id],
        target_branch: data.fetch(:target_branch, 'main'),
        source_branch: data.fetch(:source_branch, 'feature'),
        title: 'Test MR',
        description: '',
        merge_jid: '',
        target_project_id: project&.id || 0,
        state_id: data.fetch(:state_id, MergeRequest.available_states[:opened]),
        created_at: data[:created_at],
        updated_at: data.fetch(:updated_at, data[:created_at]),
        metric_merged_at: data[:metric_merged_at],
        traversal_path: project&.project_namespace&.traversal_path(with_organization: true)&.to_s || '0/',
        _siphon_replicated_at: data.fetch(:_siphon_replicated_at, data[:created_at]),
        _siphon_deleted: data.fetch(:_siphon_deleted, false)
      }
    end)

    expect(result).to be(true)
  end

  def insert_ci_pipelines_to_click_house(pipelines)
    result = clickhouse_fixture(:ci_finished_pipelines, pipelines.map do |pipeline|
      project = pipeline.project

      pipeline.slice(
        %i[id duration status source ref committed_at created_at started_at finished_at]).symbolize_keys
           .merge(
             path: project&.project_namespace&.traversal_path || '0/',
             is_default_branch: pipeline.default_branch?
           )
    end)

    expect(result).to be(true)

    insert_ci_pipelines_to_siphon(pipelines)
  end

  def insert_ci_builds_to_siphon(builds, replicated_at: Time.current, deleted: false)
    result = clickhouse_fixture(:siphon_p_ci_builds, builds.map do |build|
      project = build.project

      {
        id: build.id,
        partition_id: build.try(:partition_id) || 100,
        project_id: project&.id || 0,
        commit_id: build.commit_id || build.pipeline_id,
        status: build.status,
        name: build.name,
        stage_id: build.stage_id,
        type: build.try(:type) || 'Ci::Build',
        started_at: build.started_at,
        finished_at: build.finished_at,
        created_at: build.created_at,
        updated_at: build.try(:updated_at) || build.created_at,
        traversal_path: project&.project_namespace&.traversal_path(with_organization: true) || '0/',
        _siphon_replicated_at: replicated_at,
        _siphon_deleted: deleted
      }
    end)

    expect(result).to be(true)
  end

  def insert_ci_pipelines_to_siphon(pipelines, replicated_at: Time.current, deleted: false)
    result = clickhouse_fixture(:siphon_p_ci_pipelines, pipelines.map do |pipeline|
      project = pipeline.project

      # NOTE: siphon_* tables store traversal_path with the leading organization_id
      # segment (e.g. '1/9970/19/') because the project_traversal_paths_dict source
      # uses `with_organization: true`. The non-siphon `ci_finished_pipelines` table
      # uses the namespace-only form (e.g. '9970/19/'). See similar handling for
      # `events` vs `siphon_events` above.
      {
        id: pipeline.id,
        partition_id: pipeline.try(:partition_id) || 100,
        project_id: project&.id || 0,
        status: pipeline.status,
        source: ::Ci::Pipeline.sources[pipeline.source.to_s],
        ref: pipeline.ref,
        duration: pipeline.duration,
        committed_at: pipeline.committed_at,
        created_at: pipeline.created_at,
        started_at: pipeline.started_at,
        finished_at: pipeline.finished_at,
        traversal_path: project&.project_namespace&.traversal_path(with_organization: true) || '0/',
        _siphon_replicated_at: replicated_at,
        _siphon_deleted: deleted
      }
    end)

    expect(result).to be(true)
  end

  def insert_ci_stages_to_siphon(stages, replicated_at: Time.current, deleted: false)
    result = clickhouse_fixture(:siphon_p_ci_stages, stages.map do |stage|
      project = stage.project

      {
        id: stage.id,
        partition_id: stage.try(:partition_id) || 100,
        project_id: project&.id || 0,
        pipeline_id: stage.pipeline_id,
        name: stage.name,
        status: stage.try(:status_value) || 0,
        position: stage.try(:position),
        created_at: stage.created_at,
        updated_at: stage.try(:updated_at) || stage.created_at,
        traversal_path: project&.project_namespace&.traversal_path(with_organization: true) || '0/',
        _siphon_replicated_at: replicated_at,
        _siphon_deleted: deleted
      }
    end)

    expect(result).to be(true)
  end

  def self.default_timezone
    ActiveRecord.default_timezone
  end

  def clickhouse_fixture(table_or_models, *args, &block)
    case table_or_models
    when String, Symbol then clickhouse_raw_fixture(table_or_models, *args, &block)
    else clickhouse_model_fixture(table_or_models)
    end
  end

  def clickhouse_model_fixture(models)
    clickhouse_raw_fixture(models.first.class.clickhouse_table_name, models.map(&:to_clickhouse_csv_row))
  end

  def clickhouse_raw_fixture(table, data, db = :main, &block)
    return if data.empty?

    if data.map { |row| row.keys.sort }.uniq.size > 1
      raise "Data is inconsistent! Make sure all data object have the same structure"
    end

    structure = data.first.keys

    rows = data.map do |row|
      structure.map do |col|
        val = row[col].is_a?(Hash) ? row[col].to_json : row[col]
        val.is_a?(Arel::Nodes::SqlLiteral) ? val : ClickHouseHelpers.quote(val)
      end
    end

    query = if block
              yield(rows, structure)
            else
              values_data = rows.map do |cols|
                "(#{cols.join(', ')})"
              end.join(',')

              "INSERT INTO #{table} (#{structure.join(', ')}) VALUES #{values_data}"
            end

    ClickHouse::Client.execute(query, db)
  end
end
