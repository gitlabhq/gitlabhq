# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::QueryPlan::Filter, feature_category: :database do
  let(:part_definition) { Gitlab::Database::Aggregation::PartDefinition.new(:exact_match, :string) }
  let(:part_configuration) { { identifier: :exact_match, values: ['value1'] } }

  describe '#name' do
    it 'delegates to definition' do
      filter = described_class.new(part_definition, part_configuration)
      expect(filter.name).to eq(:exact_match)
    end
  end

  describe '#type' do
    it 'delegates to definition' do
      filter = described_class.new(part_definition, part_configuration)
      expect(filter.type).to eq(:string)
    end
  end

  describe '#instance_key' do
    it 'returns instance key from definition' do
      filter = described_class.new(part_definition, part_configuration)
      expect(filter.instance_key).to eq('exact_match')
    end
  end

  describe 'formatter' do
    context 'when definition has a formatter' do
      let(:formatting_map) { { 'a' => 1, 'b' => 2 } }
      let(:part_definition) do
        Gitlab::Database::Aggregation::PartDefinition.new(
          :event, :string, nil,
          formatter: ->(values) { Array.wrap(values).map { |v| formatting_map[v] } }
        )
      end

      it 'formats single value' do
        filter = described_class.new(part_definition, { identifier: :event, values: 'a' })
        expect(filter.configuration[:values]).to eq([1])
      end

      it 'formats array values' do
        filter = described_class.new(part_definition, { identifier: :event, values: %w[a b] })
        expect(filter.configuration[:values]).to eq([1, 2])
      end
    end

    context 'when definition has no formatter' do
      it 'does not modify values' do
        filter = described_class.new(part_definition, part_configuration)
        expect(filter.configuration[:values]).to eq(['value1'])
      end
    end
  end

  describe 'validations' do
    it 'is valid when definition is present' do
      filter = described_class.new(part_definition, part_configuration)
      expect(filter).to be_valid
    end

    it 'is invalid when definition is nil' do
      filter = described_class.new(nil, part_configuration)
      expect(filter).not_to be_valid
    end

    it 'includes error message when definition is missing' do
      filter = described_class.new(nil, { identifier: :missing_filter })
      filter.validate
      expect(filter.errors.to_a).to include(
        a_string_matching(/identifier is not available: 'missing_filter'/)
      )
    end
  end
end
