# frozen_string_literal: true

require 'fast_spec_helper'
require_relative Rails.root.join('lib/ci/pipeline_creation/inputs/spec_inputs.rb')

RSpec.describe Ci::PipelineCreation::Inputs::SpecInputs, feature_category: :pipeline_composition do
  subject(:spec_inputs) { described_class.new(specs) }

  let(:string_input_spec) { { type: 'string', default: 'test' } }
  let(:number_input_spec) { { type: 'number', default: 42 } }
  let(:boolean_input_spec) { { type: 'boolean', default: true } }
  let(:array_input_spec) { { type: 'array', default: ['item1'] } }

  describe '.input_types' do
    it 'returns an array of valid input type names' do
      expect(described_class.input_types).to match_array(%w[string number boolean array])
    end
  end

  describe '#initialize' do
    context 'with valid input specifications' do
      let(:specs) do
        {
          'string_param' => string_input_spec,
          'number_param' => number_input_spec,
          'boolean_param' => boolean_input_spec,
          'array_param' => array_input_spec
        }
      end

      it 'creates inputs without errors' do
        spec_inputs = described_class.new(specs)
        expect(spec_inputs.errors).to be_empty
      end
    end

    context 'with invalid input specification' do
      let(:specs) do
        {
          'invalid_param' => { type: 'invalid_type' }
        }
      end

      it 'adds error message' do
        spec_inputs = described_class.new(specs)
        expect(spec_inputs.errors).to include(
          a_string_matching(/unknown input specification for `invalid_param`/)
        )
      end
    end

    context 'with nil specs' do
      it 'handles nil input without errors' do
        spec_inputs = described_class.new(nil)
        expect(spec_inputs.errors).to be_empty
      end
    end
  end

  describe '#input_names' do
    let(:specs) do
      {
        'string_param' => string_input_spec,
        'number_param' => number_input_spec
      }
    end

    it 'returns array of input names' do
      spec_inputs = described_class.new(specs)
      expect(spec_inputs.input_names).to contain_exactly('string_param', 'number_param')
    end
  end

  describe '#validate_input_params!' do
    subject(:validate) { spec_inputs.validate_input_params!(params) }

    let(:spec_inputs) { described_class.new(specs) }

    let(:specs) do
      {
        'string_param' => { type: 'string' }
      }
    end

    context 'with valid params' do
      let(:params) { { 'string_param' => 'value' } }

      it 'does not raise error' do
        validate
        expect(spec_inputs.errors).to be_empty
      end
    end

    context 'with missing required params' do
      let(:params) { { 'string_param' => nil } }

      it 'adds an error for missing required param' do
        validate
        expect(spec_inputs.errors).to contain_exactly(/required value has not been provided/)
      end
    end

    context 'with invalid param type' do
      let(:params) { { 'string_param' => 123 } }

      it 'adds an error for invalid param type' do
        validate
        expect(spec_inputs.errors).to contain_exactly(/provided value is not a string/)
      end
    end
  end

  describe '#to_params' do
    let(:specs) do
      {
        'string_param' => string_input_spec,
        'number_param' => number_input_spec
      }
    end

    let(:spec_inputs) { described_class.new(specs) }

    context 'with provided params' do
      let(:params) do
        {
          'string_param' => 'custom_value',
          'number_param' => 100
        }
      end

      it 'returns hash with actual values' do
        expect(spec_inputs.to_params(params)).to eq(
          'string_param' => 'custom_value',
          'number_param' => 100
        )
      end
    end

    context 'with missing params' do
      let(:params) do
        { 'number_param' => 100 }
      end

      it 'returns hash with default values' do
        expect(spec_inputs.to_params(params)).to eq(
          'string_param' => 'test',
          'number_param' => 100
        )
      end
    end
  end
end
