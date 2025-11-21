# frozen_string_literal: true

require 'fast_spec_helper'
require_relative Rails.root.join('lib/ci/inputs/base_input.rb')
require_relative Rails.root.join('lib/ci/inputs/number_input.rb')
require_relative Rails.root.join('lib/ci/inputs/rules_evaluator.rb')

RSpec.describe Ci::Inputs::NumberInput, feature_category: :pipeline_composition do
  describe '.matches?' do
    context 'when spec is a hash with type: number' do
      it 'returns true' do
        expect(described_class.matches?({ type: 'number' })).to be_truthy
      end
    end

    context 'when spec is a hash with a different type' do
      it 'returns false' do
        expect(described_class.matches?({ type: 'string' })).to be_falsey
      end
    end

    context 'when spec is not a hash' do
      it 'returns false' do
        expect(described_class.matches?([])).to be_falsey
      end
    end

    context 'when spec is nil' do
      it 'returns false' do
        expect(described_class.matches?(nil)).to be_falsey
      end
    end
  end

  describe '.type_name' do
    it 'returns number' do
      expect(described_class.type_name).to eq('number')
    end
  end

  describe '#validate_param!' do
    context 'when validating type' do
      context 'when value is a valid number' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 42 }) }

        it 'does not add errors' do
          input.validate_param!(42)

          expect(input.errors).to be_empty
        end
      end

      context 'when value is an integer' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 10 }) }

        it 'does not add errors' do
          input.validate_param!(10)

          expect(input.errors).to be_empty
        end
      end

      context 'when value is a float' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 3.14 }) }

        it 'does not add errors' do
          input.validate_param!(3.14)

          expect(input.errors).to be_empty
        end
      end

      context 'when value is not a number' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 'not a number' }) }

        it 'adds an error' do
          input.validate_param!(nil)

          expect(input.errors).to contain_exactly('`test_input` input: default value is not a number')
        end
      end

      context 'when provided value is not a number' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 42 }) }

        it 'adds an error' do
          input.validate_param!('not a number')

          expect(input.errors).to contain_exactly('`test_input` input: provided value is not a number')
        end
      end
    end

    context 'when validating options' do
      context 'when value is in the allowed options' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 1, options: [1, 2, 3] }) }

        it 'does not add errors' do
          input.validate_param!(2)

          expect(input.errors).to be_empty
        end
      end

      context 'when value is not in the allowed options' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 1, options: [1, 2, 3] }) }

        it 'adds an error' do
          input.validate_param!(5)

          expect(input.errors).to contain_exactly(
            '`test_input` input: `5` cannot be used because it is not in the list of the allowed options'
          )
        end
      end

      context 'when options are not specified' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 1 }) }

        it 'does not add errors' do
          input.validate_param!(999)

          expect(input.errors).to be_empty
        end
      end

      context 'when value is nil and options are specified' do
        let(:input) { described_class.new(name: :test_input, spec: { default: 1, options: [1, 2, 3] }) }

        it 'does not validate options for nil values' do
          input.validate_param!(nil)

          expect(input.errors).to be_empty
        end
      end
    end

    context 'when input has rules' do
      let(:input) do
        described_class.new(
          name: :test_input,
          spec: {
            default: 3,
            rules: [
              { if: '$FOO == "bar"', options: [1, 2] },
              { options: [3, 4] }
            ]
          }
        )
      end

      it 'validates against resolved options from rules' do
        input.validate_param!(3, { 'FOO' => 'baz' })

        expect(input.errors).to be_empty
      end
    end
  end

  describe '#actual_value' do
    context 'when param is provided' do
      let(:input) { described_class.new(name: :test_input, spec: { default: 1 }) }

      it 'returns the coerced param value' do
        expect(input.actual_value(42)).to eq(42)
      end
    end

    context 'when param is nil' do
      let(:input) { described_class.new(name: :test_input, spec: { default: 10 }) }

      it 'returns the coerced default value' do
        expect(input.actual_value(nil)).to eq(10)
      end
    end

    context 'when param is a string representation of a number' do
      let(:input) { described_class.new(name: :test_input, spec: { default: 1 }) }

      it 'coerces string to number via JSON parsing' do
        expect(input.actual_value('42')).to eq(42)
      end
    end
  end
end
