# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::QueryPlan::Metric, feature_category: :database do
  let(:part_definition) { Gitlab::Database::Aggregation::PartDefinition.new(:total_count, :integer) }
  let(:part_configuration) { { identifier: :total_count } }

  describe '#definition' do
    it 'returns the definition' do
      metric = described_class.new(part_definition, part_configuration, query_plan: nil)
      expect(metric.definition).to eq(part_definition)
    end
  end

  describe '#name' do
    it 'delegates to definition' do
      metric = described_class.new(part_definition, part_configuration, query_plan: nil)
      expect(metric.name).to eq(:total_count)
    end
  end

  describe '#type' do
    it 'delegates to definition' do
      metric = described_class.new(part_definition, part_configuration, query_plan: nil)
      expect(metric.type).to eq(:integer)
    end
  end

  describe '#instance_key' do
    it 'returns instance key from definition' do
      metric = described_class.new(part_definition, part_configuration, query_plan: nil)
      expect(metric.instance_key).to eq('total_count')
    end
  end

  describe '#matches?' do
    let(:dimension_definition) do
      Gitlab::Database::Aggregation::ActiveRecord::DateBucketDimension.new(
        :created_at,
        :timestamp,
        parameters: { granularity: { type: :string, in: %w[monthly daily] } }
      )
    end

    it 'returns true when identifier and parameters match' do
      part = described_class.new(part_definition, { identifier: :total_count }, query_plan: nil)

      expect(part.matches?({ identifier: :total_count, values: [1, 2] })).to be(true)
    end

    it 'returns false when identifier differs' do
      part = described_class.new(part_definition, { identifier: :total_count }, query_plan: nil)

      expect(part.matches?({ identifier: :other_count })).to be(false)
    end

    it 'matches parameterized parts only when parameters are equal' do
      part_with_params = Gitlab::Database::Aggregation::QueryPlan::Dimension.new(
        dimension_definition,
        { identifier: :created_at, parameters: { granularity: 'monthly' } },
        query_plan: nil
      )

      expect(part_with_params.matches?({ identifier: :created_at, parameters: { granularity: 'monthly' },
        direction: :desc })).to be(true)
      expect(part_with_params.matches?({ identifier: :created_at,
        parameters: { granularity: 'daily' } })).to be(false)
    end

    it 'matches by configured identifier when it differs from the definition identifier' do
      association_definition = Gitlab::Database::Aggregation::ActiveRecord::DimensionDefinition.new(
        :user_id, :integer, association: true
      )

      part = Gitlab::Database::Aggregation::QueryPlan::Dimension.new(
        association_definition,
        { identifier: :user, parameters: {} },
        query_plan: nil
      )

      expect(part.matches?({ identifier: :user, direction: :desc })).to be(true)
      expect(part.matches?({ identifier: :user_id, direction: :desc })).to be(false)
    end
  end

  describe 'validations' do
    it 'is valid when definition is present' do
      metric = described_class.new(part_definition, part_configuration, query_plan: nil)
      expect(metric).to be_valid
    end

    it 'is invalid when definition is nil' do
      metric = described_class.new(nil, part_configuration, query_plan: nil)
      expect(metric).not_to be_valid
    end

    it 'includes error message when definition is missing' do
      metric = described_class.new(nil, { identifier: :missing_metric }, query_plan: nil)
      metric.validate
      expect(metric.errors.to_a).to include(
        a_string_matching(/identifier is not available: 'missing_metric'/)
      )
    end
  end
end
