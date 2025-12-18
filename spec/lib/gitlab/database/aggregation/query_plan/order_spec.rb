# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::QueryPlan::Order, feature_category: :database do
  let(:part_definition) { Gitlab::Database::Aggregation::PartDefinition.new(:count, :integer) }
  let(:part_configuration) { {} }
  let(:plan_part) { Gitlab::Database::Aggregation::QueryPlan::Metric.new(part_definition, part_configuration) }

  describe '#definition' do
    it 'returns part_definition' do
      expect(described_class.new(plan_part, {}).definition).to eq(part_definition)
    end

    it 'returns nil if plan_part is nil' do
      expect(described_class.new(nil, {}).definition).to be_nil
    end
  end

  describe '#instance_key' do
    it 'returns plan_part#instance_key' do
      expect(described_class.new(plan_part, {}).instance_key).to eq(plan_part.instance_key)
    end

    it 'returns nil if plan_part is nil' do
      expect(described_class.new(nil, {}).instance_key).to be_nil
    end
  end

  describe '#direction' do
    it 'is picked from configuration' do
      expect(described_class.new(plan_part, { direction: :asc }).direction).to eq(:asc)
    end

    it 'returns nil if configuration is empty' do
      expect(described_class.new(nil, {}).direction).to be_nil
    end
  end
end
