# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::QueryPlan, feature_category: :database do
  let_it_be(:engine_definition) do
    Gitlab::Database::Aggregation::Engine.build do
      def self.dimensions_mapping
        {
          column: Gitlab::Database::Aggregation::ActiveRecord::DimensionDefinition
        }
      end

      def self.metrics_mapping
        {
          count: Gitlab::Database::Aggregation::PartDefinition
        }
      end

      def self.filters_mapping
        {
          exact_match: Gitlab::Database::Aggregation::PartDefinition
        }
      end

      dimensions do
        column :state_id, :integer
        column :user_id, :integer, association: true
      end

      metrics do
        count :total_count, :integer
      end

      filters do
        exact_match :state_id, :integer
      end
    end
  end

  let(:engine) { engine_definition.new(context: { scope: MergeRequest.all }) }

  describe 'validations' do
    context 'when filter cannot be found' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          filters: [{ identifier: :missing_identfier }],
          metrics: [{ identifier: :total_count }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        )
      end
    end

    context 'when dimension cannot be found' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :missing_identfier }],
          metrics: [{ identifier: :total_count }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        )
      end
    end

    context 'when metric cannot be found' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: [{ identifier: :missing_identfier }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        )
      end
    end

    context 'when no metric is passed in' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: []
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include(a_string_matching(/at least one metric is required/))
      end
    end

    context 'when order cannot be found' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: [{ identifier: :total_count }],
          order: [{ identifier: :missing_identfier, direction: :asc }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        )
      end
    end

    context 'when duplicated dimensions are passed in' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }, { identifier: :state_id }],
          metrics: [{ identifier: :total_count }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include(a_string_matching(/duplicated identifiers found: state_id/))
      end
    end

    context 'when duplicated metrics are passed in' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: [{ identifier: :total_count }, { identifier: :total_count }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include(a_string_matching(/duplicated identifiers found: total_count/))
      end
    end

    context 'when dimensions have associations' do
      it 'accepts association name as identifier' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user }],
          metrics: [{ identifier: :total_count }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).to be_valid
      end

      it 'accepts pure identifier as identifier' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :total_count }]
        )

        query_plan = described_class.new(engine, request)

        expect(query_plan).to be_valid
      end
    end
  end
end
