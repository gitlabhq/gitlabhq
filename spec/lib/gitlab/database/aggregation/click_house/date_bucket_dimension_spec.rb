# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::DateBucketDimension, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      dimensions do
        date_bucket :started_event_at, :date, -> { sql('anyIfMerge(started_event_at)') }, parameters: {
          granularity: {
            type: :string,
            in: ['weekly', 'monthly', /\A([1-9]\d?|[12]\d{2}|3[0-5]\d|36[0-6])d\z/]
          },
          origin: { type: :datetime }
        }
      end

      metrics do
        count
        count :users, :integer, -> { sql('user_id') }, distinct: true
      end
    end
  end

  let(:session1) do # march bucket
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session2) do # march bucket
    created_at = DateTime.parse('2025-03-12 00:00:00 UTC')
    { session_id: 2, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 3.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session3) do # april bucket
    created_at = DateTime.parse('2025-04-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      dropped_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3]
  end

  it 'returns monthly buckets by default' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :started_event_at }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { started_event_at: Date.parse('2025-03-01'), total_count: 2 },
      { started_event_at: Date.parse('2025-04-01'), total_count: 1 }
    ])
  end

  it 'returns specified buckets if provided' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :started_event_at, parameters: { granularity: 'weekly' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { started_event_at_granularity_weekly: Date.parse('2025-03-01').beginning_of_week, total_count: 1 },
      { started_event_at_granularity_weekly: Date.parse('2025-03-12').beginning_of_week, total_count: 1 },
      { started_event_at_granularity_weekly: Date.parse('2025-04-01').beginning_of_week, total_count: 1 }
    ])
  end

  it 'returns errors if granularity is not allowed' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :started_event_at, parameters: { granularity: 'daily' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).with_errors(array_including(
      a_string_matching(%r{Invalid value\(s\) for parameter `granularity`: daily})
    ))
  end

  context 'with a dynamic day granularity' do
    def request_for(parameters)
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :started_event_at, parameters: parameters }],
        metrics: [{ identifier: :total_count }]
      )
    end

    it 'returns fixed-length day buckets aligned to the unix epoch' do
      # 30-day grid aligned to the unix epoch: sessions 1 and 2 fall into the
      # bucket starting 2025-02-11, session 3 into the one starting 2025-03-13.
      expect(engine).to execute_aggregation(request_for(granularity: '30d')).and_return([
        { started_event_at_granularity_30d: Date.parse('2025-02-11'), total_count: 2 },
        { started_event_at_granularity_30d: Date.parse('2025-03-13'), total_count: 1 }
      ])
    end

    context 'with an origin' do
      let(:dimension_definition) { engine_definition.dimensions.first }
      let(:origin) { Time.utc(2025, 3, 20) }

      def origin_request(origin_value, metrics: [{ identifier: :total_count }])
        Gitlab::Database::Aggregation::Request.new(
          dimensions: [
            { identifier: :started_event_at, parameters: { granularity: '30d', origin: origin_value } }
          ],
          metrics: metrics
        )
      end

      it 'returns one row per origin-anchored period for a current-vs-previous comparison' do
        instance_key = dimension_definition.instance_key(parameters: { granularity: '30d', origin: origin })
        request = origin_request(origin, metrics: [{ identifier: :total_count }, { identifier: :users_count }])

        # Buckets anchored at the origin: sessions 1 and 2 precede the origin and
        # land in the previous period [Feb 18, Mar 20) thanks to the epoch phase
        # normalization; session 3 lands in the current period [Mar 20, Apr 19).
        expect(engine).to execute_aggregation(request).and_return([
          { instance_key => Time.utc(2025, 2, 18), total_count: 2, users_count: 2 },
          { instance_key => origin, total_count: 1, users_count: 1 }
        ])
      end

      it 'raises for a non-Time origin instead of anchoring silently' do
        # GraphQL inputs are coerced to Time by the API layer; direct callers
        # must do the same.
        expect { engine.execute(origin_request('2025-03-20T00:00:00Z')) }
          .to raise_error(ArgumentError, /origin must be a Time, got String/)
      end

      it 'returns errors if origin is combined with a calendar granularity' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [
            { identifier: :started_event_at, parameters: { granularity: 'monthly', origin: origin } }
          ],
          metrics: [{ identifier: :total_count }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/Parameter `origin` requires a dynamic day granularity/)
        ))
      end

      it 'rejects an arbitrarily long day count without parsing it' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [
            { identifier: :started_event_at, parameters: { granularity: "#{'9' * 5000}d", origin: origin } }
          ],
          metrics: [{ identifier: :total_count }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(%r{Invalid value\(s\) for parameter `granularity`})
        ))
      end

      it 'returns errors if origin is given without a granularity' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :started_event_at, parameters: { origin: origin } }],
          metrics: [{ identifier: :total_count }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/Parameter `origin` requires a dynamic day granularity/)
        ))
      end
    end

    it 'accepts the lower boundary day count of 1d' do
      expect(engine).to execute_aggregation(request_for(granularity: '1d')).and_return(match_array([
        { started_event_at_granularity_1d: Time.utc(2025, 3, 1), total_count: 1 },
        { started_event_at_granularity_1d: Time.utc(2025, 3, 12), total_count: 1 },
        { started_event_at_granularity_1d: Time.utc(2025, 4, 4), total_count: 1 }
      ]))
    end

    it 'accepts the upper boundary day count of 366d' do
      # All three sessions fall into the epoch-aligned 366-day bucket
      # starting 2025-02-11.
      expect(engine).to execute_aggregation(request_for(granularity: '366d')).and_return([
        { started_event_at_granularity_366d: Date.parse('2025-02-11'), total_count: 3 }
      ])
    end

    it 'returns errors if the day count exceeds 366' do
      expect(engine).to execute_aggregation(request_for(granularity: '367d')).with_errors(array_including(
        a_string_matching(%r{Invalid value\(s\) for parameter `granularity`: 367d})
      ))
    end

    it 'returns errors if the day count is zero' do
      expect(engine).to execute_aggregation(request_for(granularity: '0d')).with_errors(array_including(
        a_string_matching(%r{Invalid value\(s\) for parameter `granularity`: 0d})
      ))
    end

    it 'returns errors if the format is malformed' do
      expect(engine).to execute_aggregation(request_for(granularity: '30days')).with_errors(array_including(
        a_string_matching(%r{Invalid value\(s\) for parameter `granularity`: 30days})
      ))
    end

    it 'rejects day counts with more than three digits by pattern' do
      expect(engine).to execute_aggregation(request_for(granularity: '1000d')).with_errors(array_including(
        a_string_matching(%r{Invalid value\(s\) for parameter `granularity`: 1000d})
      ))
    end

    it 'rejects arbitrarily long digit strings without parsing them' do
      # Validation must reject by pattern alone; parsing this would needlessly
      # build a multi-kilobyte Integer.
      expect(engine).to execute_aggregation(request_for(granularity: "#{'9' * 5000}d"))
        .with_errors(array_including(a_string_matching(%r{Invalid value\(s\) for parameter `granularity`})))
    end

    context 'when the engine allowlist permits day counts beyond 366' do
      let(:engine_definition) do
        Gitlab::Database::Aggregation::ClickHouse::Engine.build do
          self.table_name = 'agent_platform_sessions'

          dimensions do
            date_bucket :started_event_at, :date, -> { sql('anyIfMerge(started_event_at)') }, parameters: {
              granularity: { type: :string, in: [/\A\d{1,4}d\z/] }
            }
          end

          metrics do
            count
          end
        end
      end

      it 'buckets by the engine-allowed day count' do
        expect(engine).to execute_aggregation(request_for(granularity: '400d')).and_return([
          { started_event_at_400d: Date.parse('2024-10-04'), total_count: 3 }
        ])
      end
    end
  end
end
