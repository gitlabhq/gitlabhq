# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::PartDefinition, feature_category: :database do
  let(:name) { :test_part }
  let(:type) { :integer }
  let(:expression) { -> { 'COUNT(*)' } }
  let(:secondary_expression) { -> { 'SUM(value)' } }
  let(:description) { 'Test part description' }
  let(:formatter) { ->(val) { val * 2 } }

  describe '#format_value' do
    it 'applies the formatter to the value if formatter is present' do
      expect(described_class.new(name, type, formatter: formatter).format_value(5)).to eq(10)
    end

    it 'returns the value unchanged without formatter' do
      expect(described_class.new(name, type).format_value(42)).to eq(42)
    end
  end

  describe '#parameterized?' do
    subject(:part) { described_class.new(name, type) }

    it { is_expected.not_to be_parameterized }
  end

  describe '#identifier' do
    subject(:part) { described_class.new(name, type) }

    it 'returns the part name' do
      expect(part.identifier).to eq(name)
    end
  end

  describe '#instance_key' do
    subject(:part) { described_class.new(name, type) }

    it 'returns the identifier as a string' do
      expect(part.instance_key({})).to eq(name.to_s)
    end
  end
end
