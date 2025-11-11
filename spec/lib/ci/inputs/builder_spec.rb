# frozen_string_literal: true

require 'fast_spec_helper'
require 'oj'
require_relative Rails.root.join('lib/ci/inputs/builder.rb')

RSpec.describe Ci::Inputs::Builder, feature_category: :pipeline_composition do
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

    context 'with spec is not a hash' do
      let(:specs) { 'this is a string' }

      before do
        stub_const('TranslationStub', Module.new do
          def s_(message, *_args)
            message
          end
        end)

        described_class.include(TranslationStub)
      end

      it 'adds error message about invalid input specification' do
        spec_inputs = described_class.new(specs)
        expect(spec_inputs.errors).to include(
          a_string_matching(/Invalid input specification: expected a hash-like object/)
        )
      end

      it 'returns empty inputs' do
        spec_inputs = described_class.new(specs)
        expect(spec_inputs.all_inputs).to be_empty
      end
    end
  end

  describe '#all_inputs' do
    context 'when inputs exists' do
      let(:specs) do
        {
          'string_param' => string_input_spec,
          'number_param' => number_input_spec,
          'boolean_param' => boolean_input_spec,
          'array_param' => array_input_spec
        }
      end

      it 'returns all inputs' do
        inputs = described_class.new(specs).all_inputs

        expect(inputs.map(&:name)).to eq(specs.keys)
        expect(inputs[0]).to be_an_instance_of(Ci::Inputs::StringInput)
        expect(inputs[0].default).to eq('test')

        expect(inputs[1]).to be_an_instance_of(Ci::Inputs::NumberInput)
        expect(inputs[1].default).to eq(42)

        expect(inputs[2]).to be_an_instance_of(Ci::Inputs::BooleanInput)
        expect(inputs[2].default).to be(true)

        expect(inputs[3]).to be_an_instance_of(Ci::Inputs::ArrayInput)
        expect(inputs[3].default).to eq(['item1'])
      end
    end

    context 'when inputs do not exist' do
      it 'returns empty array' do
        expect(described_class.new(nil).all_inputs).to be_empty
        expect(described_class.new({}).all_inputs).to be_empty
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
        'number_param' => { type: 'number' }
      }
    end

    context 'with valid params as string' do
      let(:params) { { 'number_param' => '123' } }

      it 'does not raise error' do
        validate
        expect(spec_inputs.errors).to be_empty
      end
    end

    context 'with valid params as number' do
      let(:params) { { 'number_param' => 123 } }

      it 'does not raise error' do
        validate
        expect(spec_inputs.errors).to be_empty
      end
    end

    context 'with missing required params' do
      let(:params) { { 'number_param' => nil } }

      it 'adds an error for missing required param' do
        validate
        expect(spec_inputs.errors).to contain_exactly(/required value has not been provided/)
      end
    end

    context 'with invalid param type' do
      let(:params) { { 'number_param' => 'abc' } }

      it 'adds an error for invalid param type' do
        validate
        expect(spec_inputs.errors).to contain_exactly(/provided value is not a number/)
      end
    end

    context 'with rules-based options validation' do
      let(:specs) do
        {
          'cloud_provider' => {
            type: 'string',
            options: %w[aws gcp],
            default: 'aws'
          },
          'instance_type' => {
            type: 'string',
            rules: [
              {
                if: '$[[ inputs.cloud_provider ]] == "aws"',
                options: ['t3.micro', 't3.small']
              },
              {
                if: '$[[ inputs.cloud_provider ]] == "gcp"',
                options: %w[e2-small e2-medium]
              }
            ]
          }
        }
      end

      context 'when value matches resolved options' do
        let(:params) do
          {
            'cloud_provider' => 'aws',
            'instance_type' => 't3.micro'
          }
        end

        it 'does not add validation errors' do
          validate
          expect(spec_inputs.errors).to be_empty
        end
      end

      context 'when value does not match resolved options' do
        let(:params) do
          {
            'cloud_provider' => 'aws',
            'instance_type' => 'e2-small'
          }
        end

        it 'adds validation error for invalid option' do
          validate
          expect(spec_inputs.errors).to include(
            a_string_matching(/e2-small.*cannot be used.*not in the list of allowed options/)
          )
        end
      end

      context 'when dependent value changes the allowed options' do
        let(:params) do
          {
            'cloud_provider' => 'gcp',
            'instance_type' => 'e2-small'
          }
        end

        it 'validates against the correct resolved options' do
          validate
          expect(spec_inputs.errors).to be_empty
        end
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

    context 'with rules-based defaults' do
      let(:specs) do
        {
          'cloud_provider' => {
            type: 'string',
            options: %w[aws gcp],
            default: 'aws'
          },
          'instance_type' => {
            type: 'string',
            rules: [
              {
                if: '$[[ inputs.cloud_provider ]] == "aws"',
                options: ['t3.micro', 't3.small'],
                default: 't3.micro'
              },
              {
                if: '$[[ inputs.cloud_provider ]] == "gcp"',
                options: %w[e2-small e2-medium],
                default: 'e2-small'
              }
            ]
          }
        }
      end

      context 'when using default values' do
        let(:params) { {} }

        it 'returns resolved defaults based on dependencies' do
          expect(spec_inputs.to_params(params)).to eq(
            'cloud_provider' => 'aws',
            'instance_type' => 't3.micro'
          )
        end
      end

      context 'when changing dependent input' do
        let(:params) { { 'cloud_provider' => 'gcp' } }

        it 'returns resolved default for the new value' do
          expect(spec_inputs.to_params(params)).to eq(
            'cloud_provider' => 'gcp',
            'instance_type' => 'e2-small'
          )
        end
      end

      context 'with chained dependencies' do
        let(:specs) do
          {
            'env' => { type: 'string', default: 'prod' },
            'region' => {
              type: 'string',
              rules: [
                { if: '$[[ inputs.env ]] == "prod"', default: 'us-east-1' }
              ]
            },
            'az' => {
              type: 'string',
              rules: [
                { if: '$[[ inputs.region ]] == "us-east-1"', default: 'us-east-1a' }
              ]
            }
          }
        end

        it 'resolves chain of dependencies' do
          expect(spec_inputs.to_params({})).to eq(
            'env' => 'prod',
            'region' => 'us-east-1',
            'az' => 'us-east-1a'
          )
        end
      end
    end
  end
end
