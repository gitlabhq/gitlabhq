# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::QueryPlan::Dimension, feature_category: :database do
  let(:part_definition) { Gitlab::Database::Aggregation::PartDefinition.new(:state_id, :integer) }
  let(:part_configuration) { { identifier: :state_id } }

  describe '#name' do
    it 'delegates to definition' do
      dimension = described_class.new(part_definition, part_configuration)
      expect(dimension.name).to eq(:state_id)
    end
  end

  describe '#type' do
    it 'delegates to definition' do
      dimension = described_class.new(part_definition, part_configuration)
      expect(dimension.type).to eq(:integer)
    end
  end

  describe '#instance_key' do
    it 'returns instance key from definition' do
      dimension = described_class.new(part_definition, part_configuration)
      expect(dimension.instance_key).to eq('state_id')
    end
  end

  describe 'validations' do
    it 'is valid when definition is present' do
      dimension = described_class.new(part_definition, part_configuration)
      expect(dimension).to be_valid
    end

    it 'is invalid when definition is nil' do
      dimension = described_class.new(nil, part_configuration)
      expect(dimension).not_to be_valid
    end

    it 'includes error message when definition is missing' do
      dimension = described_class.new(nil, { identifier: :missing_dimension })
      dimension.validate
      expect(dimension.errors.to_a).to include(
        a_string_matching(/identifier is not available: 'missing_dimension'/)
      )
    end
  end
end
