# frozen_string_literal: true

require 'fast_spec_helper'
require_relative Rails.root.join('lib/ci/inputs/base_input.rb')
require_relative Rails.root.join('lib/ci/inputs/string_input.rb')
require_relative Rails.root.join('lib/ci/inputs/rules_evaluator.rb')

RSpec.describe Ci::Inputs::StringInput, feature_category: :pipeline_composition do
  describe '.matches?' do
    context 'when spec is a hash with type: string' do
      it 'returns true' do
        expect(described_class.matches?({ type: 'string' })).to be_truthy
      end
    end

    context 'when spec is a hash without a type key' do
      it 'returns true' do
        expect(described_class.matches?({ default: 'value' })).to be_truthy
      end
    end

    context 'when spec is nil' do
      it 'returns true' do
        expect(described_class.matches?(nil)).to be_truthy
      end
    end

    context 'when spec is a hash with a different type' do
      it 'returns false' do
        expect(described_class.matches?({ type: 'number' })).to be_falsey
      end
    end

    context 'when spec is not a hash or nil' do
      it 'returns false' do
        expect(described_class.matches?([])).to be_falsey
      end
    end
  end

  describe '.type_name' do
    it 'returns string' do
      expect(described_class.type_name).to eq('string')
    end
  end

  describe '#validate_param!' do
    context 'when validating type' do
      context 'when value is a string' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'test' }) }

        it 'does not add errors' do
          input.validate_param!('value')

          expect(input.errors).to be_empty
        end
      end

      context 'when value is not a string' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'test' }) }

        it 'does not add errors because it will be coerced to string' do
          input.validate_param!(123)

          expect(input.errors).to be_empty
        end
      end
    end

    context 'when validating options' do
      context 'when value is in the allowed options' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'a', options: %w[a b c] }) }

        it 'does not add errors' do
          input.validate_param!('b')

          expect(input.errors).to be_empty
        end
      end

      context 'when value is not in the allowed options' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'a', options: %w[a b c] }) }

        it 'adds an error' do
          input.validate_param!('d')

          expect(input.errors).to contain_exactly(
            '`test_input` input: `d` cannot be used because it is not in the list of allowed options'
          )
        end
      end

      context 'when options contain symbols and value is a string' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'a', options: [:a, :b, :c] }) }

        it 'converts options to strings for comparison' do
          input.validate_param!('b')

          expect(input.errors).to be_empty
        end
      end

      context 'when options are not specified' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'a' }) }

        it 'does not add errors' do
          input.validate_param!('any value')

          expect(input.errors).to be_empty
        end
      end

      context 'when value is nil and options are specified' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'a', options: %w[a b c] }) }

        it 'does not validate options for nil values' do
          input.validate_param!(nil)

          expect(input.errors).to be_empty
        end
      end
    end

    context 'when validating regex' do
      context 'when value matches the regex' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'test', regex: '^[a-z]+$' }) }

        it 'does not add errors' do
          input.validate_param!('hello')

          expect(input.errors).to be_empty
        end
      end

      context 'when value does not match the regex' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'test', regex: '^[a-z]+$' }) }

        it 'adds an error' do
          input.validate_param!('hello123')

          expect(input.errors).to contain_exactly(
            '`test_input` input: provided value does not match required RegEx pattern'
          )
        end
      end

      context 'when default value does not match the regex' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'test123', regex: '^[a-z]+$' }) }

        it 'adds an error' do
          input.validate_param!(nil)

          expect(input.errors).to contain_exactly(
            '`test_input` input: default value does not match required RegEx pattern'
          )
        end
      end

      context 'when regex is invalid' do
        let(:input) { described_class.new(name: :test_input, spec: { regex: '[' }) }

        it 'adds an error' do
          input.validate_param!('value')

          expect(input.errors).to contain_exactly(
            '`test_input` input: invalid regular expression'
          )
        end
      end

      context 'when regex allows empty string' do
        let(:input) { described_class.new(name: :test_input, spec: { default: '', regex: '^$' }) }

        it 'does not add errors' do
          input.validate_param!('')

          expect(input.errors).to be_empty
        end
      end

      context 'when value is not a string' do
        let(:input) { described_class.new(name: :test_input, spec: { default: '123', regex: '^[0-9]+$' }) }

        it 'does not perform regex validation on non-string values' do
          input.validate_param!(123)

          expect(input.errors).to be_empty
        end
      end
    end

    context 'when input has rules' do
      let(:input) do
        described_class.new(
          name: :test_input,
          spec: {
            default: 'option3',
            rules: [
              { if: '$FOO == "bar"', options: %w[option1 option2] },
              { options: %w[option3 option4] }
            ]
          }
        )
      end

      it 'validates against resolved options from rules' do
        input.validate_param!('option3', { 'FOO' => 'baz' })

        expect(input.errors).to be_empty
      end
    end
  end

  describe '#actual_value' do
    context 'when param is provided' do
      let(:input) { described_class.new(name: :test_input, spec: { default: 'default' }) }

      it 'returns the coerced param value' do
        expect(input.actual_value('value')).to eq('value')
      end
    end

    context 'when param is nil' do
      let(:input) { described_class.new(name: :test_input, spec: { default: 'default' }) }

      it 'returns the coerced default value' do
        expect(input.actual_value(nil)).to eq('default')
      end
    end

    context 'when param is a non-string value' do
      let(:input) { described_class.new(name: :test_input, spec: { default: 'default' }) }

      it 'coerces value to string' do
        expect(input.actual_value(123)).to eq('123')
      end
    end

    context 'when param is a boolean' do
      let(:input) { described_class.new(name: :test_input, spec: { default: 'default' }) }

      it 'coerces boolean to string' do
        expect(input.actual_value(true)).to eq('true')
        expect(input.actual_value(false)).to eq('false')
      end
    end
  end

  describe '#coerced_value' do
    let(:input) { described_class.new(name: :test_input, spec: { default: 'test' }) }

    it 'converts values to string' do
      expect(input.send(:coerced_value, 123)).to eq('123')
    end
  end
end
