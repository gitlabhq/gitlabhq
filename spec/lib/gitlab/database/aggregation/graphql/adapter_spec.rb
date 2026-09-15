# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Graphql::Adapter, feature_category: :database do
  describe '.parent_context_name' do
    it 'converts name to camelCase' do
      expect(described_class.types_prefix('my_engine')).to eq('MyEngine')
      expect(described_class.types_prefix('engine')).to eq('Engine')
      expect(described_class.types_prefix(:my_engine)).to eq('MyEngine')
      expect(described_class.types_prefix('MY_ENGINE')).to eq('MyEngine')
    end
  end

  describe '.graphql_type' do
    it 'returns corresponding GraphQL types' do
      expect(described_class.graphql_type(:string)).to eq(::GraphQL::Types::String)
      expect(described_class.graphql_type(:integer)).to eq(::GraphQL::Types::Int)
      expect(described_class.graphql_type(:boolean)).to eq(::GraphQL::Types::Boolean)
      expect(described_class.graphql_type(:float)).to eq(::GraphQL::Types::Float)
      expect(described_class.graphql_type(:date)).to eq(::Types::DateType)
      expect(described_class.graphql_type(:datetime)).to eq(::Types::TimeType)
    end
  end

  describe '.each_filter_argument' do
    let(:exact_match_filter) do
      Gitlab::Database::Aggregation::ClickHouse::ExactMatchFilter.new(
        :status, :string, description: 'Filter by status'
      )
    end

    let(:range_filter) do
      Gitlab::Database::Aggregation::ClickHouse::RangeFilter.new(
        :created_at, :datetime, description: 'Filter by creation date'
      )
    end

    let(:metric_exact_match_filter) do
      Gitlab::Database::Aggregation::ClickHouse::MetricExactMatchFilter.new(
        :session_count, :integer, description: 'Filter by session count'
      )
    end

    let(:metric_range_filter) do
      Gitlab::Database::Aggregation::ClickHouse::MetricRangeFilter.new(
        :session_duration, :integer, description: 'Filter by session duration'
      )
    end

    context 'with multiple filters' do
      it 'yields arguments for all filters' do
        filters = [exact_match_filter, range_filter]
        arguments = []

        described_class.each_filter_argument(filters) do |identifier, type, options|
          arguments << [identifier, type, options]
        end

        expect(arguments.size).to eq(3)
        expect(arguments.map(&:first)).to eq([:status, :created_at_from, :created_at_to])
      end
    end

    context 'with metric filters' do
      it 'exposes metric filters with the same argument shape as their non-metric counterparts' do
        filters = [exact_match_filter, metric_exact_match_filter, metric_range_filter]
        arguments = []

        described_class.each_filter_argument(filters) do |identifier, type, options|
          arguments << [identifier, type, options]
        end

        expect(arguments.map(&:first))
          .to eq([:status, :session_count, :session_duration_from, :session_duration_to])
      end

      it 'notes that the referenced metric must also be requested in the description' do
        filters = [exact_match_filter, metric_exact_match_filter, metric_range_filter]
        descriptions = {}

        described_class.each_filter_argument(filters) do |identifier, _type, options|
          descriptions[identifier] = options[:description]
        end

        expect(descriptions[:status]).to eq('Filter by status')
        expect(descriptions[:session_count]).to eq(
          'Filter by session count The `session_count` metric must also be requested when using this filter'
        )
        expect(descriptions[:session_duration_from]).to eq(
          'Filter by session duration The `session_duration` metric must also be requested when using this filter. ' \
            'Start of the range.'
        )
        expect(descriptions[:session_duration_to]).to eq(
          'Filter by session duration The `session_duration` metric must also be requested when using this filter. ' \
            'End of the range.'
        )
      end
    end
  end

  describe '.arguments_to_filters' do
    let(:exact_match) { Gitlab::Database::Aggregation::ClickHouse::ExactMatchFilter.new(:status, :string) }
    let(:metric_exact_match) do
      Gitlab::Database::Aggregation::ClickHouse::MetricExactMatchFilter.new(:session_count, :integer)
    end

    let(:metric_range) do
      Gitlab::Database::Aggregation::ClickHouse::MetricRangeFilter.new(:session_duration, :integer)
    end

    let(:filters) { [exact_match, metric_exact_match, metric_range] }

    it 'builds filter configurations for the provided filters' do
      arguments = {
        status: %w[active],
        session_count: [1, 2, 3],
        session_duration_from: 10,
        session_duration_to: 20
      }

      expect(described_class.arguments_to_filters(filters, arguments))
        .to contain_exactly(
          { identifier: :status, values: %w[active] },
          { identifier: :session_count, values: [1, 2, 3] },
          { identifier: :session_duration, values: 10..20 }
        )
    end

    it 'only builds filters for the subset of filters passed in' do
      arguments = {
        status: %w[active],
        session_count: [1, 2, 3],
        session_duration_from: 10,
        session_duration_to: 20
      }

      expect(described_class.arguments_to_filters([exact_match], arguments))
        .to contain_exactly({ identifier: :status, values: %w[active] })
    end
  end

  describe '.coerce_order_parameters!' do
    let_it_be(:engine_definition) do
      Gitlab::Database::Aggregation::Engine.build do
        def self.dimensions_mapping
          {
            column: Gitlab::Database::Aggregation::ClickHouse::DimensionDefinition,
            date_bucket: Gitlab::Database::Aggregation::ClickHouse::DateBucketDimension
          }
        end

        def self.metrics_mapping
          { metric: Gitlab::Database::Aggregation::ClickHouse::MetricDefinition }
        end

        def self.filters_mapping
          {}
        end

        dimensions do
          column :status, :string
          date_bucket :created_at, :datetime, parameters: {
            granularity: { type: :string },
            origin: { type: :datetime }
          }
        end

        metrics do
          metric :total, :integer
          metric :quantile, :float, ->(_params) { Arel.sql('quantile(duration)') },
            parameters: { levels: { type: :float, array: true } }
          metric :retained, :integer, ->(_params) { Arel.sql('count(distinct user_id)') },
            parameters: { cohort_date: { type: :date } }
        end
      end
    end

    let(:engine) { engine_definition.new(context: {}) }
    let(:metrics) { [{ identifier: :total, parameters: {} }] }

    def build_request(dimensions: [], metrics: self.metrics, order: [])
      Gitlab::Database::Aggregation::Request.new(dimensions: dimensions, metrics: metrics, order: order)
    end

    it 'coerces order parameters to the same values as typed field arguments' do
      origin_string = '2026-06-07T00:00:00Z'
      # the dimension part carries an already-coerced field argument value
      origin_time = ::Types::TimeType.coerce_isolated_input(origin_string)
      request = build_request(
        dimensions: [{ identifier: :created_at, parameters: { granularity: '30d', origin: origin_time } }],
        order: [{ identifier: :created_at, direction: :desc,
                  parameters: { granularity: '30d', origin: origin_string } }]
      )

      described_class.coerce_order_parameters!(request, engine)

      parameters = request.order.first[:parameters]
      expect(parameters[:origin]).to eq(Time.utc(2026, 6, 7))
      expect(parameters[:granularity]).to eq('30d')

      # instance keys now line up, so the order resolves to the dimension part
      expect(request.to_query_plan(engine).order.first.definition).to be_present
    end

    it 'coerces date parameters to the same values as typed field arguments' do
      request = build_request(
        metrics: metrics + [{ identifier: :retained, parameters: { cohort_date: Date.iso8601('2026-06-07') } }],
        order: [{ identifier: :retained, direction: :desc, parameters: { cohort_date: '2026-06-07' } }]
      )

      described_class.coerce_order_parameters!(request, engine)

      expect(request.order.first[:parameters][:cohort_date]).to eq(Date.new(2026, 6, 7))
      expect(request.to_query_plan(engine).order.first.definition).to be_present
    end

    it 'coerces array parameters and wraps single values' do
      request = build_request(
        metrics: metrics + [{ identifier: :quantile, parameters: { levels: [0.5] } }],
        order: [{ identifier: :quantile, direction: :asc, parameters: { levels: 0.5 } }]
      )

      described_class.coerce_order_parameters!(request, engine)

      expect(request.order.first[:parameters][:levels]).to eq([0.5])
    end

    it 'raises an argument error when a scalar rejects the value' do
      request = build_request(
        dimensions: [{ identifier: :created_at, parameters: { granularity: '30d' } }],
        order: [{ identifier: :created_at, direction: :desc,
                  parameters: { granularity: '30d', origin: 'not-a-time' } }]
      )

      expect { described_class.coerce_order_parameters!(request, engine) }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /order parameter `origin` of `created_at`/)
    end

    it 'raises an argument error when a built-in scalar returns nil for the value' do
      request = build_request(
        dimensions: [{ identifier: :created_at, parameters: { granularity: 'daily' } }],
        order: [{ identifier: :created_at, direction: :desc, parameters: { granularity: 30 } }]
      )

      expect { described_class.coerce_order_parameters!(request, engine) }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /30 is not a valid String/)
    end

    it 'skips order entries referencing parts that are not requested' do
      request = build_request(
        order: [{ identifier: :created_at, direction: :desc, parameters: { origin: 'not-a-time' } }]
      )

      described_class.coerce_order_parameters!(request, engine)

      expect(request.order.first[:parameters]).to eq({ origin: 'not-a-time' })
    end

    it 'leaves unknown identifiers, undeclared and nil parameters untouched' do
      request = build_request(
        dimensions: [{ identifier: :created_at, parameters: { granularity: '30d' } }],
        order: [
          { identifier: :missing, direction: :asc, parameters: { granularity: '30d' } },
          { identifier: :created_at, direction: :desc,
            parameters: { granularity: '30d', origin: nil, undeclared: 'x' } }
        ]
      )

      described_class.coerce_order_parameters!(request, engine)

      expect(request.order.first[:parameters]).to eq({ granularity: '30d' })
      expect(request.order.last[:parameters]).to eq({ granularity: '30d', origin: nil, undeclared: 'x' })
    end

    it 'skips non-parameterized definitions' do
      request = build_request(order: [{ identifier: :status, direction: :asc, parameters: { foo: 'bar' } }])

      described_class.coerce_order_parameters!(request, engine)

      expect(request.order.first[:parameters]).to eq({ foo: 'bar' })
    end
  end
end
