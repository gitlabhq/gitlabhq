# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ParameterizedDefinition, feature_category: :database do
  let(:definition_class) do
    Class.new(Gitlab::Database::Aggregation::PartDefinition) do
      include Gitlab::Database::Aggregation::ParameterizedDefinition

      self.supported_parameters = %i[bar]
    end
  end

  let(:definition) do
    definition_class.new(:foo, :string, nil, parameters: { bar: { type: :string } })
  end

  let(:definition_without_params) do
    definition_class.new(:foo, :sting)
  end

  let(:defintion_class_with_no_supported_params) do
    Class.new(Gitlab::Database::Aggregation::PartDefinition) do
      include Gitlab::Database::Aggregation::ParameterizedDefinition
    end
  end

  describe '#initialize' do
    it 'raises an error for unknown parameter' do
      expect do
        definition_class.new(:foo, :string, nil, parameters: { unknown: { type: :string } })
      end.to raise_error("Parameter `unknown` is not in supported parameters: [:bar]")

      expect do
        defintion_class_with_no_supported_params.new(:foo, :string, nil, parameters: { unknown: { type: :string } })
      end.to raise_error("Parameter `unknown` is not in supported parameters: ")
    end
  end

  describe '#to_hash' do
    it 'adds parameters definition to hash' do
      expect(definition.to_hash).to include(parameters: { bar: { type: :string } })
    end
  end

  describe '#instance_key' do
    it 'returns simple value for non-parameterized definition' do
      expect(definition_without_params.instance_key({})).to eq('foo')
    end

    it 'returns simple value for request without params' do
      expect(definition.instance_key({})).to eq('foo')
    end

    context 'with request parameters specified' do
      it 'returns identifier with parameters postfix' do
        expect(definition.instance_key(parameters: { bar: '42' })).to eq('foo_42')
      end

      it 'uses hashed identifier postfix if non-word param is present' do
        expect(definition.instance_key(parameters: { bar: '42.5' })).to eq('foo_7b713')
        expect(definition.instance_key(parameters: { bar: 'something long' })).to eq('foo_cb42e')
        expect(definition.instance_key(parameters: { bar: 'with_symbols;:"' })).to eq('foo_97763')
      end
    end
  end
end
