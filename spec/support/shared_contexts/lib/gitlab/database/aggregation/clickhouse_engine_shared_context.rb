# frozen_string_literal: true

RSpec.shared_context 'with agent_platform_sessions ClickHouse aggregation engine' do
  include ClickHouseHelpers

  let(:engine) { engine_definition.new(context: { scope: query_builder }) }
  let(:query_builder) { ClickHouse::Client::QueryBuilder.new(engine_definition.table_name) }

  let(:row_structure) do
    %i[user_id namespace_path project_id session_id flow_type environment session_year created_event_at
      started_event_at finished_event_at dropped_event_at stopped_event_at resumed_event_at]
  end

  let(:session1) do # finished & long
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session2) do # finished & short
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 2, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 3.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session3) do # not finished yet. in progress
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3]
  end

  let(:prepared_all_data_rows) do
    all_data_rows.map do |row|
      row_structure.to_h do |key|
        value = row.fetch(key, nil)
        if key.to_s.end_with?('_at') # timestamp
          value = if value
                    Arel.sql("parseDateTime64BestEffort('#{value}', 6, 'UTC')")
                  else
                    Arel.sql("CAST(NULL AS Nullable(DateTime64(6, 'UTC')))")
                  end
        end

        [key, value]
      end
    end
  end

  before do
    clickhouse_fixture(engine_definition.table_name, prepared_all_data_rows) do |rows, structure|
      subselects = rows.map do |row|
        fields = structure.map.with_index do |field, i|
          "#{row[i]} AS #{field}"
        end

        "SELECT #{fields.join(', ')}"
      end.join(' UNION ALL ')

      <<-SQL
        INSERT INTO agent_platform_sessions
        SELECT
            user_id,
            namespace_path,
            project_id,
            session_id,
            flow_type,
            environment,
            session_year,
            anyIfState(toNullable(created_event_at), created_event_at IS NOT NULL) as created_event_at,
            anyIfState(toNullable(started_event_at), started_event_at IS NOT NULL) as started_event_at,
            anyIfState(toNullable(finished_event_at), finished_event_at IS NOT NULL) as finished_event_at,
            anyIfState(toNullable(dropped_event_at), dropped_event_at IS NOT NULL) as dropped_event_at,
            anyIfState(toNullable(stopped_event_at), stopped_event_at IS NOT NULL) as stopped_event_at,
            anyIfState(toNullable(resumed_event_at), resumed_event_at IS NOT NULL) as resumed_event_at
        FROM (#{subselects})
        GROUP BY user_id, namespace_path, project_id, session_id, flow_type, environment, session_year
      SQL
    end
  end
end
