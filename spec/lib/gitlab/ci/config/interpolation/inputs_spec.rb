# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Inputs, feature_category: :pipeline_composition do
  let(:inputs) { described_class.new(specs, args) }
  let(:specs) { { foo: { default: 'bar' } } }
  let(:args) { {} }

  context 'when inputs are valid strings and have options' do
    let(:specs) { { foo: { default: 'one', options: %w[one two three] } } }

    context 'and the value is selected' do
      let(:args) { { foo: 'two' } }

      it 'assigns the selected value' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq({ foo: 'two' })
      end
    end

    context 'and the value is not selected' do
      it 'assigns the default value' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq({ foo: 'one' })
      end
    end
  end

  context 'when inputs options are valid integers' do
    let(:specs) { { foo: { default: 1, options: [1, 2, 3, 4, 5], type: 'number' } } }

    context 'and a value of the wrong type is given' do
      let(:args) { { foo: 'word' } }

      it 'returns an error' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          "`foo` input: `word` cannot be used because it is not in the list of the allowed options",
          "`foo` input: provided value is not a number"
        )
      end
    end

    context 'and the value is selected' do
      let(:args) { { foo: 2 } }

      it 'assigns the selected value' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq({ foo: 2 })
      end
    end

    context 'and the value is not selected' do
      it 'assigns the default value' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq({ foo: 1 })
      end
    end
  end

  context 'when inputs have invalid type options' do
    let(:specs) { { foo: { default: true, options: [true, false], type: 'boolean' } } }

    it 'returns an error' do
      expect(inputs).not_to be_valid
      expect(inputs.errors).to contain_exactly("`foo` input: Options can only be used with string and number inputs")
    end
  end

  context 'when inputs are valid with options but the default value is not in the options' do
    let(:specs) { { foo: { default: 'coop', options: %w[one two three] } } }

    it 'returns an error' do
      expect(inputs).not_to be_valid
      expect(inputs.errors).to contain_exactly(
        '`foo` input: `coop` cannot be used because it is not in the list of allowed options'
      )
    end
  end

  context 'when inputs are valid with options but the value is not in the options' do
    let(:specs) { { foo: { default: 'one', options: %w[one two three] } } }
    let(:args) { { foo: 'niet' } }

    it 'returns an error' do
      expect(inputs).not_to be_valid
      expect(inputs.errors).to contain_exactly(
        '`foo` input: `niet` cannot be used because it is not in the list of allowed options'
      )
    end
  end

  context 'when given unrecognized inputs' do
    let(:specs) { { foo: nil } }
    let(:args) { { foo: 'bar', test: 'bar' } }

    it 'is invalid' do
      expect(inputs).not_to be_valid
      expect(inputs.errors).to contain_exactly('unknown input arguments: test')
    end
  end

  context 'when given unrecognized configuration keywords' do
    let(:specs) { { foo: 123 } }
    let(:args) { {} }

    it 'is invalid' do
      expect(inputs).not_to be_valid
      expect(inputs.errors).to contain_exactly(
        'unknown input specification for `foo` (valid types: array, boolean, number, string)'
      )
    end
  end

  context 'when the inputs have multiple errors' do
    let(:specs) { { foo: nil } }
    let(:args) { { test: 'bar', gitlab: '1' } }

    it 'reports all of them' do
      expect(inputs).not_to be_valid
      expect(inputs.errors).to contain_exactly(
        'unknown input arguments: test, gitlab',
        '`foo` input: required value has not been provided'
      )
    end
  end

  describe 'required inputs' do
    let(:specs) { { foo: nil } }

    context 'when a value is given' do
      let(:args) { { foo: 'bar' } }

      it 'is valid' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(foo: 'bar')
      end
    end

    context 'when no value is given' do
      let(:args) { {} }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly('`foo` input: required value has not been provided')
      end
    end
  end

  describe 'inputs with a default value' do
    let(:specs) { { foo: { default: 'bar' } } }

    context 'when a value is given' do
      let(:args) { { foo: 'test' } }

      it 'uses the given value' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(foo: 'test')
      end
    end

    context 'when no value is given' do
      let(:args) { {} }

      it 'uses the default value' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(foo: 'bar')
      end
    end
  end

  describe 'inputs with type validation' do
    describe 'string validation' do
      let(:specs) { { a_input: nil, b_input: { default: 'test' }, c_input: { default: 123 } } }
      let(:args) { { a_input: 123, b_input: 123, c_input: 'test' } }

      it 'is the default type' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          '`a_input` input: provided value is not a string',
          '`b_input` input: provided value is not a string',
          '`c_input` input: default value is not a string'
        )
      end

      context 'when the value is a string' do
        let(:specs) { { foo: { type: 'string' } } }
        let(:args) { { foo: 'bar' } }

        it 'is valid' do
          expect(inputs).to be_valid
          expect(inputs.to_hash).to eq(foo: 'bar')
        end
      end

      context 'when the default is a string' do
        let(:specs) { { foo: { type: 'string', default: 'bar' } } }
        let(:args) { {} }

        it 'is valid' do
          expect(inputs).to be_valid
          expect(inputs.to_hash).to eq(foo: 'bar')
        end
      end

      context 'when the value is not a string' do
        let(:specs) { { foo: { type: 'string' } } }
        let(:args) { { foo: 123 } }

        it 'is invalid' do
          expect(inputs).not_to be_valid
          expect(inputs.errors).to contain_exactly('`foo` input: provided value is not a string')
        end
      end

      context 'when the default is not a string' do
        let(:specs) { { foo: { default: 123, type: 'string' } } }
        let(:args) { {} }

        it 'is invalid' do
          expect(inputs).not_to be_valid
          expect(inputs.errors).to contain_exactly('`foo` input: default value is not a string')
        end
      end
    end

    describe 'number validation' do
      let(:specs) { { integer: { type: 'number' }, float: { type: 'number' } } }

      context 'when the value is a float or integer' do
        let(:args) { { integer: 6, float: 6.6 } }

        it 'is valid' do
          expect(inputs).to be_valid
          expect(inputs.to_hash).to eq(integer: 6, float: 6.6)
        end
      end

      context 'when the default is a float or integer' do
        let(:specs) { { integer: { default: 6, type: 'number' }, float: { default: 6.6, type: 'number' } } }

        it 'is valid' do
          expect(inputs).to be_valid
          expect(inputs.to_hash).to eq(integer: 6, float: 6.6)
        end
      end

      context 'when the value is not a number' do
        let(:specs) { { number_input: { type: 'number' } } }
        let(:args) { { number_input: false } }

        it 'is invalid' do
          expect(inputs).not_to be_valid
          expect(inputs.errors).to contain_exactly('`number_input` input: provided value is not a number')
        end
      end

      context 'when the default is not a number' do
        let(:specs) { { number_input: { default: 'NaN', type: 'number' } } }
        let(:args) { {} }

        it 'is invalid' do
          expect(inputs).not_to be_valid
          expect(inputs.errors).to contain_exactly('`number_input` input: default value is not a number')
        end
      end
    end

    describe 'boolean validation' do
      context 'when the value is true or false' do
        let(:specs) { { truthy: { type: 'boolean' }, falsey: { type: 'boolean' } } }
        let(:args) { { truthy: true, falsey: false } }

        it 'is valid' do
          expect(inputs).to be_valid
          expect(inputs.to_hash).to eq(truthy: true, falsey: false)
        end
      end

      context 'when the default is true or false' do
        let(:specs) { { truthy: { default: true, type: 'boolean' }, falsey: { default: false, type: 'boolean' } } }
        let(:args) { {} }

        it 'is valid' do
          expect(inputs).to be_valid
          expect(inputs.to_hash).to eq(truthy: true, falsey: false)
        end
      end

      context 'when the value is not a boolean' do
        let(:specs) { { boolean_input: { type: 'boolean' } } }
        let(:args) { { boolean_input: 'string' } }

        it 'is invalid' do
          expect(inputs).not_to be_valid
          expect(inputs.errors).to contain_exactly('`boolean_input` input: provided value is not a boolean')
        end
      end

      context 'when the default is not a boolean' do
        let(:specs) { { boolean_input: { default: 'string', type: 'boolean' } } }
        let(:args) { {} }

        it 'is invalid' do
          expect(inputs).not_to be_valid
          expect(inputs.errors).to contain_exactly('`boolean_input` input: default value is not a boolean')
        end
      end
    end

    context 'when given an unknown type' do
      let(:specs) { { unknown: { type: 'datetime' } } }
      let(:args) { { unknown: '2023-10-31' } }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          'unknown input specification for `unknown` (valid types: array, boolean, number, string)'
        )
      end
    end
  end

  describe 'array validation' do
    context 'when the value is an array' do
      let(:specs) { { array_input: { type: 'array' } } }
      let(:args) { { array_input: [] } }

      it 'is valid' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(array_input: [])
      end
    end

    context 'when the default is an array' do
      let(:specs) { { array_input: { default: [], type: 'array' } } }
      let(:args) { {} }

      it 'is valid' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(array_input: [])
      end
    end

    context 'when the value is not an array' do
      let(:specs) { { array_input: { type: 'array' } } }
      let(:args) { { array_input: 'string' } }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly('`array_input` input: provided value is not an array')
      end
    end

    context 'when the default is not a boolean' do
      let(:specs) { { array_input: { default: 'string', type: 'array' } } }
      let(:args) { {} }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly('`array_input` input: default value is not an array')
      end
    end
  end

  describe 'inputs with RegEx validation' do
    context 'when given a value that matches the pattern' do
      let(:specs) { { test_input: { regex: '^input_value$' } } }
      let(:args) { { test_input: 'input_value' } }

      it 'is valid' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(test_input: 'input_value')
      end
    end

    context 'when given a default that matches the pattern' do
      let(:specs) { { test_input: { default: 'input_value', regex: '^input_value$' } } }
      let(:args) { {} }

      it 'is valid' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(test_input: 'input_value')
      end
    end

    context 'when given a value that does not match the pattern' do
      let(:specs) { { test_input: { regex: '^input_value$' } } }
      let(:args) { { test_input: 'input' } }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          '`test_input` input: provided value does not match required RegEx pattern'
        )
      end
    end

    context 'when given a default that does not match the pattern' do
      let(:specs) { { test_input: { default: 'input', regex: '^input_value$' } } }
      let(:args) { {} }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          '`test_input` input: default value does not match required RegEx pattern'
        )
      end
    end

    context 'when used with any type other than `string`' do
      let(:specs) { { test_input: { regex: '^input_value$', type: 'number' } } }
      let(:args) { { test_input: 999 } }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          '`test_input` input: RegEx validation can only be used with string inputs'
        )
      end
    end

    context 'when given a value that is not a string' do
      let(:specs) { { test_input: { regex: '^input_value$' } } }
      let(:args) { { test_input: 999 } }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          '`test_input` input: provided value is not a string'
        )
      end
    end

    context 'when the pattern is unsafe' do
      let(:specs) { { test_input: { regex: 'a++' } } }
      let(:args) { { test_input: 'aaaaaaaaaaaaaaaaaaaaa' } }

      it 'is invalid' do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(
          '`test_input` input: invalid regular expression'
        )
      end
    end
  end
end
