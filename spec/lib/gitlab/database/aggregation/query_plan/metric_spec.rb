# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::QueryPlan::Metric, feature_category: :database do
  let(:part_definition) { Gitlab::Database::Aggregation::PartDefinition.new(:total_count, :integer) }
  let(:part_configuration) { { identifier: :total_count } }

  describe '#definition' do
    it 'returns the definition' do
      metric = described_class.new(part_definition, part_configuration)
      expect(metric.definition).to eq(part_definition)
    end
  end

  describe '#name' do
    it 'delegates to definition' do
      metric = described_class.new(part_definition, part_configuration)
      expect(metric.name).to eq(:total_count)
    end
  end

  describe '#type' do
    it 'delegates to definition' do
      metric = described_class.new(part_definition, part_configuration)
      expect(metric.type).to eq(:integer)
    end
  end

  describe '#instance_key' do
    it 'returns instance key from definition' do
      metric = described_class.new(part_definition, part_configuration)
      expect(metric.instance_key).to eq('total_count')
    end
  end

  describe 'validations' do
    it 'is valid when definition is present' do
      metric = described_class.new(part_definition, part_configuration)
      expect(metric).to be_valid
    end

    it 'is invalid when definition is nil' do
      metric = described_class.new(nil, part_configuration)
      expect(metric).not_to be_valid
    end

    it 'includes error message when definition is missing' do
      metric = described_class.new(nil, { identifier: :missing_metric })
      metric.validate
      expect(metric.errors.to_a).to include(
        a_string_matching(/identifier is not available: 'missing_metric'/)
      )
    end
  end
end
