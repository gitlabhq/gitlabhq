# frozen_string_literal: true

RSpec.shared_context 'with agent_platform_sessions ClickHouse aggregation engine' do
  include ClickHouseHelpers

  let(:engine) { engine_definition.new(context: { scope: query_builder }) }
  let(:query_builder) { ClickHouse::Client::QueryBuilder.new(engine_definition.table_name) }

  let(:row_structure) do
    %i[user_id namespace_path project_id session_id flow_type environment session_year created_event_at
      started_event_at finished_event_at dropped_event_at stopped_event_at resumed_event_at]
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
