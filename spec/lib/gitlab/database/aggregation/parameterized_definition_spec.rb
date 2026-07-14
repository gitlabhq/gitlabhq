# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ParameterizedDefinition, feature_category: :database do
  let(:definition_class) do
    Class.new(Gitlab::Database::Aggregation::PartDefinition) do
      include Gitlab::Database::Aggregation::ParameterizedDefinition
    end
  end

  let(:definition) do
    definition_class.new(:foo, :string, nil, parameters: { bar: { type: :string } })
  end

  let(:definition_without_params) do
    definition_class.new(:foo, :string)
  end

  let(:array_definition) do
    definition_class.new(:foo, :string, nil, parameters: { bar: { type: :string, array: true } })
  end

  describe '#instance_key' do
    it 'returns simple value for non-parameterized definition' do
      expect(definition_without_params.instance_key({})).to eq('foo')
    end

    it 'returns simple value for request without params' do
      expect(definition.instance_key({})).to eq('foo')
    end

    context 'with scalar request parameters' do
      it 'returns identifier with parameters postfix' do
        expect(definition.instance_key(parameters: { bar: '42' })).to eq('foo_42')
      end

      it 'uses hashed identifier postfix if non-word param is present' do
        expect(definition.instance_key(parameters: { bar: '42.5' })).to eq('foo_7b713')
        expect(definition.instance_key(parameters: { bar: 'something long' })).to eq('foo_cb42e')
        expect(definition.instance_key(parameters: { bar: 'with_symbols;:"' })).to eq('foo_97763')
      end
    end

    context 'with array: true parameter' do
      it 'produces the same key for a single-element array and its scalar equivalent' do
        expect(array_definition.instance_key(parameters: { bar: ['42'] })).to eq('foo_42')
        expect(array_definition.instance_key(parameters: { bar: '42' })).to eq('foo_42')
      end

      it 'joins multi-element array values with underscore in the postfix' do
        expect(array_definition.instance_key(parameters: { bar: %w[success failed] })).to eq('foo_success_failed')
      end

      it 'uses hashed postfix when joined array values contain non-word characters' do
        expect(array_definition.instance_key(parameters: { bar: ['v1.0', 'v2.0'] })).to match(/\Afoo_[0-9a-f]{5}\z/)
      end

      it 'produces different keys for different array contents' do
        key1 = array_definition.instance_key(parameters: { bar: %w[success failed] })
        key2 = array_definition.instance_key(parameters: { bar: %w[failed success] })
        expect(key1).not_to eq(key2)
      end
    end
  end

  describe '#validate_part' do
    let(:part_class) do
      Class.new do
        include ActiveModel::Validations

        attr_reader :configuration

        def initialize(configuration)
          @configuration = configuration
        end

        def self.human_attribute_name(attr, _options = {})
          attr.to_s
        end
      end
    end

    def build_part(configuration)
      part_class.new(configuration)
    end

    context 'with a scalar parameter constrained by in:' do
      let(:definition_with_in) do
        definition_class.new(:foo, :string, nil, parameters: { status: { type: :string, in: %w[success failed] } })
      end

      it 'adds no errors when the value is in the allowed list' do
        part = build_part({ parameters: { status: 'success' } })
        definition_with_in.validate_part(part)
        expect(part.errors).to be_empty
      end

      it 'adds an error when the value is not in the allowed list' do
        part = build_part({ parameters: { status: 'unknown' } })
        definition_with_in.validate_part(part)
        expect(part.errors[:status]).to include(a_string_matching(/Invalid value.*unknown/))
      end

      it 'adds no errors when the parameter is not provided' do
        part = build_part({})
        definition_with_in.validate_part(part)
        expect(part.errors).to be_empty
      end
    end

    context 'with an array: true parameter constrained by in:' do
      let(:definition_with_array_in) do
        definition_class.new(:foo, :string, nil,
          parameters: { status: { type: :string, in: %w[success failed cancelled], array: true } })
      end

      it 'adds no errors when all values are in the allowed list' do
        part = build_part({ parameters: { status: %w[success failed] } })
        definition_with_array_in.validate_part(part)
        expect(part.errors).to be_empty
      end

      it 'adds no errors when a scalar value is in the allowed list' do
        part = build_part({ parameters: { status: 'success' } })
        definition_with_array_in.validate_part(part)
        expect(part.errors).to be_empty
      end

      it 'adds an error listing only the invalid elements' do
        part = build_part({ parameters: { status: %w[success unknown bogus] } })
        definition_with_array_in.validate_part(part)
        expect(part.errors[:status]).to include(a_string_matching(/unknown.*bogus|bogus.*unknown/))
        expect(part.errors[:status].first).not_to match(/success/)
      end
    end

    context 'without an in: constraint' do
      it 'adds no errors regardless of the value' do
        part = build_part({ parameters: { bar: 'anything' } })
        definition.validate_part(part)
        expect(part.errors).to be_empty
      end
    end
  end
end
