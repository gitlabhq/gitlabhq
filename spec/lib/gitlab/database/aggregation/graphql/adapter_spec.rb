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
end
