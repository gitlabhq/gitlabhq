# frozen_string_literal: true

module ClickHouseHelpers
  include ActiveRecord::ConnectionAdapters::Quoting

  def format_event_row(event)
    path = event.project.reload.project_namespace.traversal_ids.join('/')

    action = Event.actions[event.action]
    [
      event.id,
      "'#{path}/'",
      event.author_id,
      event.target_id,
      "'#{event.target_type}'",
      action,
      event.created_at.to_f,
      event.updated_at.to_f
    ].join(',')
  end

  def insert_events_into_click_house(events = Event.all)
    rows = events.map { |event| "(#{format_event_row(event)})" }.join(',')

    insert_query = <<~SQL
    INSERT INTO events
    (id, path, author_id, target_id, target_type, action, created_at, updated_at)
    VALUES
    #{rows}
    SQL

    ClickHouse::Client.execute(insert_query, :main)
  end

  def insert_ci_builds_to_click_house(builds)
    values = builds.map do |build|
      <<~SQL.squish
        (
        #{quote(build.id)},
        #{quote(build.project_id)},
        #{quote(build.pipeline_id)},
        #{quote(build.status)},
        #{format_datetime(build.finished_at)},
        #{format_datetime(build.created_at)},
        #{format_datetime(build.started_at)},
        #{format_datetime(build.queued_at)},
        #{quote(build.runner_id)},
        #{quote(build.runner_manager&.system_xid)},
        #{quote(build.runner&.run_untagged)},
        #{quote(Ci::Runner.runner_types[build.runner&.runner_type])},
        #{quote(build.runner_manager&.version || '')},
        #{quote(build.runner_manager&.revision || '')},
        #{quote(build.runner_manager&.platform || '')},
        #{quote(build.runner_manager&.architecture || '')}
        )
      SQL
    end

    values = values.join(', ')

    query = <<~SQL
      INSERT INTO ci_finished_builds
          (id, project_id, pipeline_id, status, finished_at, created_at, started_at, queued_at,
           runner_id, runner_manager_system_xid, runner_run_untagged, runner_type,
           runner_manager_version, runner_manager_revision, runner_manager_platform, runner_manager_architecture)
      VALUES #{values}
    SQL

    result = ClickHouse::Client.execute(query, :main)
    expect(result).to eq(true)
  end

  def format_datetime(date)
    quote(date&.utc&.to_f)
  end
end
