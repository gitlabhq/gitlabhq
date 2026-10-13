# frozen_string_literal: true

require 'fast_spec_helper'
require_relative Rails.root.join('lib/ci/inputs/base_input.rb')
require_relative Rails.root.join('lib/ci/inputs/array_input.rb')
require_relative Rails.root.join('lib/ci/inputs/rules_evaluator.rb')

RSpec.describe Ci::Inputs::ArrayInput, feature_category: :pipeline_composition do
  describe '#validate_param!' do
    context 'when validating type' do
      context 'when value is an array' do
        let(:input) { described_class.new(name: :test_input, spec: { default: ['item1'] }) }

        it 'does not add errors' do
          input.validate_param!(%w[item1 item2])

          expect(input.errors).to be_empty
        end
      end

      context 'when value is not an array' do
        let(:input) { described_class.new(name: :test_input, spec: { default: ['item1'] }) }

        it 'adds an error' do
          input.validate_param!('not_an_array')

          expect(input.errors).to contain_exactly(
            '`test_input` input: provided value is not an array'
          )
        end
      end

      context 'when value is not an array and options are specified' do
        let(:input) do
          described_class.new(name: :test_input, spec: { default: ['dev'], options: %w[dev staging production] })
        end

        it 'only adds a type error' do
          input.validate_param!('dev')

          expect(input.errors).to contain_exactly(
            '`test_input` input: provided value is not an array'
          )
        end
      end
    end

    context 'when validating options' do
      context 'when all values are in the allowed options' do
        let(:input) do
          described_class.new(name: :test_input, spec: { default: ['dev'], options: %w[dev staging production] })
        end

        it 'does not add errors' do
          input.validate_param!(%w[dev production])

          expect(input.errors).to be_empty
        end
      end

      context 'when value is not in the allowed options' do
        let(:input) do
          described_class.new(name: :test_input, spec: { default: ['dev'], options: %w[dev staging production] })
        end

        it 'adds an error' do
          input.validate_param!(%w[dev invalid])

          expect(input.errors).to contain_exactly(
            '`test_input` input: invalid cannot be used because it is not in the list of allowed options'
          )
        end
      end

      context 'when options are not specified' do
        let(:input) { described_class.new(name: :test_input, spec: { default: ['item1'] }) }

        it 'does not add errors' do
          input.validate_param!(%w[any values])

          expect(input.errors).to be_empty
        end
      end

      context 'when value is nil and options are specified' do
        let(:input) do
          described_class.new(name: :test_input, spec: { default: ['dev'], options: %w[dev staging production] })
        end

        it 'does not validate options for nil values' do
          input.validate_param!(nil)

          expect(input.errors).to be_empty
        end
      end

      context 'when default value is not in the allowed options' do
        let(:input) do
          described_class.new(name: :test_input, spec: { default: ['invalid'], options: %w[dev staging production] })
        end

        it 'adds an error' do
          input.validate_param!(nil)

          expect(input.errors).to contain_exactly(
            '`test_input` input: invalid cannot be used because it is not in the list of allowed options'
          )
        end
      end

      context 'when value is an empty array' do
        let(:input) do
          described_class.new(name: :test_input, spec: { default: ['dev'], options: %w[dev staging production] })
        end

        it 'does not add errors' do
          input.validate_param!([])

          expect(input.errors).to be_empty
        end
      end
    end

    context 'when input has rules' do
      let(:input) do
        described_class.new(
          name: :test_input,
          spec: {
            default: ['option3'],
            rules: [
              { if: '$FOO == "bar"', options: %w[option1 option2] },
              { options: %w[option3 option4] }
            ]
          }
        )
      end

      it 'validates against resolved options from rules' do
        input.validate_param!(['option3'], { 'FOO' => 'baz' })

        expect(input.errors).to be_empty
      end

      it 'rejects values not in resolved options' do
        input.validate_param!(['option1'], { 'FOO' => 'baz' })

        expect(input.errors).to contain_exactly(
          '`test_input` input: option1 cannot be used because it is not in the list of allowed options'
        )
      end
    end
  end
end
