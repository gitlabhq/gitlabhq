# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Ratio, :click_house,
  feature_category: :value_stream_management do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      dimensions do
        column :flow_type, :string
      end

      filters do
        exact_match :flow_type, :string
        metric_range :zero_denominator_ratio, :float
      end

      metrics do
        ratio :users_per_session,
          numerator: ->(_params) { Arel.sql('user_id') },
          denominator: ->(_params) { Arel.sql('session_id') }

        ratio :distinct_users_per_session,
          numerator: ->(_params) { Arel.sql('user_id') },
          denominator: ->(_params) { Arel.sql('session_id') },
          numerator_agg: :uniqExact,
          denominator_agg: :count

        ratio :zero_denominator,
          numerator: ->(_params) { Arel.sql('user_id') },
          denominator: ->(_params) { Arel.sql('0') }
      end
    end
  end

  let(:session1) do
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 10.minutes }
  end

  let(:session2) do
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 2, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 3.minutes }
  end

  let(:session3) do
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review',
      environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second }
  end

  let(:all_data_rows) do
    [session1, session2, session3]
  end

  describe 'identifier' do
    it 'appends the `_ratio` suffix' do
      definition = described_class.new(:credits_per_mr, numerator: ->(_p) {}, denominator: ->(_p) {})

      expect(definition.identifier).to eq(:credits_per_mr_ratio)
    end

    it 'leaves a dotted name untouched' do
      definition = described_class.new(:"credits.per_mr", numerator: ->(_p) {}, denominator: ->(_p) {})

      expect(definition.identifier).to eq(:"credits.per_mr")
    end
  end

  describe 'aggregate function allowlist' do
    it 'defaults both sides to `sum`' do
      definition = described_class.new(:foo, numerator: ->(_p) {}, denominator: ->(_p) {})

      expect(definition.numerator_agg).to eq(:sum)
      expect(definition.denominator_agg).to eq(:sum)
    end

    it 'rejects an aggregate function outside the allowlist' do
      expect do
        described_class.new(:foo, numerator: ->(_p) {}, denominator: ->(_p) {}, numerator_agg: :median)
      end.to raise_error(ArgumentError, /Unsupported aggregate function :median/)
    end

    it 'rejects an unsupported denominator aggregate function' do
      expect do
        described_class.new(:foo, numerator: ->(_p) {}, denominator: ->(_p) {}, denominator_agg: :quantile)
      end.to raise_error(ArgumentError, /Unsupported aggregate function :quantile/)
    end

    it 'rejects a nil aggregate with a clear error, not a NoMethodError' do
      expect do
        described_class.new(:foo, numerator: ->(_p) {}, denominator: ->(_p) {}, numerator_agg: nil)
      end.to raise_error(ArgumentError, /Unsupported aggregate function nil for `ratio`/)
    end

    it 'rejects a non-symbolizable aggregate with a clear error' do
      expect do
        described_class.new(:foo, numerator: ->(_p) {}, denominator: ->(_p) {}, denominator_agg: 5)
      end.to raise_error(ArgumentError, /Unsupported aggregate function 5 for `ratio`/)
    end

    it 'rejects free-form SQL as an aggregate function' do
      expect do
        described_class.new(:foo, numerator: ->(_p) {}, denominator: ->(_p) {},
          numerator_agg: 'sum(x) FROM other_table --')
      end.to raise_error(ArgumentError, /Unsupported aggregate function/)
    end
  end

  describe 'declared type' do
    it 'rejects a non-float type, which GraphQL would silently truncate' do
      expect do
        described_class.new(:foo, :integer, numerator: ->(_p) {}, denominator: ->(_p) {})
      end.to raise_error(ArgumentError, /`ratio` metric `foo` must be declared as `:float`, got :integer/)
    end

    it 'rejects a nil type with a clear error, not a NoMethodError' do
      expect do
        described_class.new(:foo, nil, numerator: ->(_p) {}, denominator: ->(_p) {})
      end.to raise_error(ArgumentError, /must be declared as `:float`, got nil/)
    end

    it 'names the metric in the error, even though the check runs before `super`' do
      expect do
        described_class.new(:credits_per_mr, :string, numerator: ->(_p) {}, denominator: ->(_p) {})
      end.to raise_error(ArgumentError, /metric `credits_per_mr`/)
    end
  end

  describe 'an expression that returns nil' do
    let(:engine_definition) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'

        metrics do
          ratio :nil_denominator,
            numerator: ->(_params) { Arel.sql('user_id') },
            denominator: ->(params) { params[:flag] ? Arel.sql('session_id') : nil },
            parameters: { flag: { type: :string } }

          ratio :nil_numerator,
            numerator: ->(params) { params[:flag] ? Arel.sql('user_id') : nil },
            denominator: ->(_params) { Arel.sql('session_id') },
            parameters: { flag: { type: :string } }
        end
      end
    end

    it 'returns an error response rather than raising, for a nil denominator' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :nil_denominator_ratio }]
      )

      expect(engine).to execute_aggregation(request)
        .with_errors(["metric 'nil_denominator_ratio' has no denominator for the given parameters"])
    end

    it 'returns an error response for a nil numerator' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :nil_numerator_ratio }]
      )

      expect(engine).to execute_aggregation(request)
        .with_errors(["metric 'nil_numerator_ratio' has no numerator for the given parameters"])
    end

    it 'still raises if the query is built without validating the plan first' do
      plan = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :nil_denominator_ratio }]
      ).to_query_plan(engine)

      expect { engine.send(:execute_query_plan, plan) }.to raise_error(
        ArgumentError, /built no denominator projection/
      )
    end

    it 'reports a nil numerator expression itself, not just one that returns nil' do
      definition = Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'

        metrics do
          ratio :absent_numerator,
            numerator: nil,
            denominator: ->(_params) { Arel.sql('session_id') }
        end
      end

      engine = definition.new(context: { scope: query_builder })
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :absent_numerator_ratio }]
      )

      expect(engine).to execute_aggregation(request)
        .with_errors(["metric 'absent_numerator_ratio' has no numerator for the given parameters"])
    end

    it 'reports a nil denominator expression itself' do
      definition = Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'

        metrics do
          ratio :absent_denominator,
            numerator: ->(_params) { Arel.sql('user_id') },
            denominator: nil
        end
      end

      engine = definition.new(context: { scope: query_builder })
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :absent_denominator_ratio }]
      )

      expect(engine).to execute_aggregation(request)
        .with_errors(["metric 'absent_denominator_ratio' has no denominator for the given parameters"])
    end

    it 'still computes normally once the parameter is supplied' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :nil_denominator_ratio, parameters: { flag: 'on' } }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { nil_denominator_ratio_on: 4.0 / 6 }
      ])
    end
  end

  describe 'the `if:` keyword' do
    it 'is rejected, because the denominator occupies the secondary expression slot' do
      expect do
        described_class.new(:foo, numerator: ->(_p) {}, denominator: ->(_p) {}, if: ->(_p) {})
      end.to raise_error(ArgumentError, /`if:` is not supported by `ratio`/)
    end
  end

  describe 'ratio with default aggregates' do
    it 'divides the summed numerator by the summed denominator' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :users_per_session_ratio }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { users_per_session_ratio: 4.0 / 6 }
      ])
    end
  end

  describe 'ratio with per-side aggregate functions' do
    it 'applies each side its own aggregate function' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :distinct_users_per_session_ratio }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { distinct_users_per_session_ratio: 2.0 / 3 }
      ])
    end
  end

  describe 'a parameter value outside the declared allowlist' do
    let(:engine_definition) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'

        metrics do
          ratio :picked_numerator,
            numerator: ->(params) { { 'users' => Arel.sql('user_id') }.fetch(params[:field]) },
            denominator: ->(_params) { Arel.sql('session_id') },
            parameters: { field: { type: :string, in: %w[users] } }

          ratio :picked_denominator,
            numerator: ->(_params) { Arel.sql('user_id') },
            denominator: ->(params) { { 'users' => Arel.sql('session_id') }.fetch(params[:field]) },
            parameters: { field: { type: :string, in: %w[users] } }
        end
      end
    end

    # An expression may trust the allowlist, so it must not be called once the
    # parameter has already been rejected.
    it 'does not evaluate the numerator expression' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :picked_numerator_ratio, parameters: { field: 'invalid' } }]
      )

      expect(engine).to execute_aggregation(request)
        .with_errors(['Field Invalid value(s) for parameter `field`: invalid'])
    end

    it 'does not evaluate the denominator expression' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :picked_denominator_ratio, parameters: { field: 'invalid' } }]
      )

      expect(engine).to execute_aggregation(request)
        .with_errors(['Field Invalid value(s) for parameter `field`: invalid'])
    end
  end

  describe 'zero denominator' do
    it 'returns NULL rather than inf or nan' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :zero_denominator_ratio }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { zero_denominator_ratio: nil }
      ])
    end

    it 'excludes the groups from a lower-bound filter' do
      # The JSON response format renders both NULL and inf as null, so only a filter,
      # which is applied in SQL, can tell the guarded result from an unguarded one.
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :flow_type }],
        metrics: [{ identifier: :zero_denominator_ratio }],
        filters: [{ identifier: :zero_denominator_ratio, values: 0.5.. }]
      )

      expect(engine).to execute_aggregation(request).and_return([])
    end
  end

  describe 'combined with a dimension' do
    it 'computes the ratio per dimension value' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :flow_type }],
        metrics: [{ identifier: :users_per_session_ratio }],
        order: [{ identifier: :flow_type, direction: :asc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { flow_type: 'chat', users_per_session_ratio: 1.0 },
        { flow_type: 'code_review', users_per_session_ratio: 1.0 / 3 }
      ])
    end
  end

  describe 'combined with a filter' do
    it 'computes the ratio over the filtered rows only' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :flow_type, values: ['chat'] }],
        metrics: [{ identifier: :users_per_session_ratio }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { users_per_session_ratio: 1.0 }
      ])
    end
  end

  describe 'inherited part options' do
    let_it_be(:authorized_user) { create(:user) }
    let_it_be(:authorized_project) { create(:project) }

    let(:engine_definition) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'

        metrics do
          ratio :plain,
            numerator: ->(_params) { Arel.sql('user_id') },
            denominator: ->(_params) { Arel.sql('session_id') }

          # mirrors how `credits_used` is protected on the DuoWorkflows engine
          ratio :restricted,
            numerator: ->(_params) { Arel.sql('user_id') },
            denominator: ->(_params) { Arel.sql('session_id') },
            authorize: :read_agent_artifacts

          ratio :formatted,
            numerator: ->(_params) { Arel.sql('user_id') },
            denominator: ->(_params) { Arel.sql('session_id') },
            formatter: ->(value) { value.nil? ? nil : "#{(value * 100).round(1)}%" }
        end
      end
    end

    let(:engine) do
      engine_definition.new(context: {
        scope: query_builder,
        current_user: authorized_user,
        authorization_resources: [authorized_project]
      })
    end

    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :plain_ratio }, { identifier: :restricted_ratio }]
      )
    end

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
        .with(authorized_user, :read_agent_artifacts, anything).and_return(ability_granted)
    end

    context 'when the required ability is granted' do
      let(:ability_granted) { true }

      it 'returns the restricted ratio' do
        expect(engine).to execute_aggregation(request).and_return([
          { plain_ratio: 4.0 / 6, restricted_ratio: 4.0 / 6 }
        ])
      end
    end

    context 'when the required ability is missing' do
      let(:ability_granted) { false }

      it 'drops the restricted ratio and keeps the unrestricted one' do
        expect(engine).to execute_aggregation(request).and_return([
          { plain_ratio: 4.0 / 6 }
        ])
      end
    end

    context 'with a formatter' do
      let(:ability_granted) { true }

      it 'applies the formatter to the computed ratio' do
        formatted_request = Gitlab::Database::Aggregation::Request.new(
          metrics: [{ identifier: :formatted_ratio }]
        )

        expect(engine).to execute_aggregation(formatted_request).and_return([
          { formatted_ratio: '66.7%' }
        ])
      end
    end
  end

  describe 'parameterized ratio' do
    let(:engine_definition) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'

        metrics do
          ratio :by_flow,
            numerator: ->(params) { Arel.sql("if(flow_type = '#{params[:flow_type]}', user_id, 0)") },
            denominator: ->(_params) { Arel.sql('session_id') },
            parameters: {
              flow_type: { type: :string }
            }
        end
      end
    end

    it 'passes parameter values to the numerator expression' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :by_flow_ratio, parameters: { flow_type: 'chat' } }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { by_flow_ratio_chat: 3.0 / 6 }
      ])
    end

    it 'generates a unique result key per parameter combination' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [
          { identifier: :by_flow_ratio, parameters: { flow_type: 'chat' } },
          { identifier: :by_flow_ratio, parameters: { flow_type: 'code_review' } }
        ]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { by_flow_ratio_chat: 3.0 / 6, by_flow_ratio_code_review: 1.0 / 6 }
      ])
    end
  end
end
