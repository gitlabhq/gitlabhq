# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Inputs::Validator, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(Gitlab::Ci::Config::Header::Inputs)
      .value(inputs_hash)
      .with(key: :inputs)
  end

  let(:inputs) { factory.create! }
  let(:entries) { inputs.instance_variable_get(:@entries) }

  subject(:validator) { described_class.new(entries) }

  describe '#validate!' do
    before do
      inputs.compose!
    end

    context 'when inputs are valid' do
      let(:inputs_hash) do
        {
          environment: {
            options: %w[development staging production]
          },
          region: {
            options: %w[us eu asia]
          }
        }
      end

      it 'does not add errors' do
        validator.validate!
        expect(inputs).to be_valid
      end
    end

    context 'when rules reference undefined inputs' do
      let(:inputs_hash) do
        {
          environment: {
            options: %w[development production]
          },
          resource_tier: {
            rules: [
              {
                if: '$[[ inputs.undefined_input ]] == "value"',
                options: %w[small medium]
              }
            ]
          }
        }
      end

      it 'adds an error for undefined input reference' do
        validator.validate!
        expect(inputs).not_to be_valid
        expect(inputs.errors).to include(match(/rule\[0\] references undefined inputs: undefined_input/))
      end
    end

    context 'when rules reference multiple undefined inputs' do
      let(:inputs_hash) do
        {
          environment: {
            options: %w[development production]
          },
          resource_tier: {
            rules: [
              {
                if: '$[[ inputs.undefined_one ]] == "value" && $[[ inputs.undefined_two ]] == "other"',
                options: %w[small medium]
              }
            ]
          }
        }
      end

      it 'adds an error listing all undefined inputs' do
        validator.validate!
        expect(inputs).not_to be_valid
        expect(inputs.errors).to include(match(/rule\[0\] references undefined inputs: undefined_one, undefined_two/))
      end
    end

    context 'when multiple rules have undefined inputs' do
      let(:inputs_hash) do
        {
          environment: {
            options: %w[development production]
          },
          resource_tier: {
            rules: [
              {
                if: '$[[ inputs.undefined_one ]] == "value"',
                options: %w[small]
              },
              {
                if: '$[[ inputs.undefined_two ]] == "value"',
                options: %w[medium]
              }
            ]
          }
        }
      end

      it 'adds errors for each rule' do
        validator.validate!
        expect(inputs).not_to be_valid
        expect(inputs.errors).to include(
          match(/rule\[0\] references undefined inputs: undefined_one/),
          match(/rule\[1\] references undefined inputs: undefined_two/)
        )
      end
    end

    context 'when rules reference CI variables' do
      let(:inputs_hash) do
        {
          environment: {
            options: %w[development production]
          },
          region: {
            rules: [
              {
                if: '$[[ inputs.environment ]] == "production" && $CI_COMMIT_BRANCH == "main"',
                options: %w[us eu]
              }
            ]
          }
        }
      end

      it 'allows CI variable references' do
        validator.validate!
        expect(inputs).to be_valid
      end
    end

    context 'when expression has invalid syntax' do
      let(:inputs_hash) do
        {
          region: {
            rules: [{ if: '&&&&', options: %w[us] }]
          }
        }
      end

      it 'handles StatementError gracefully and does not fail validation' do
        allow(Gitlab::Ci::Pipeline::Expression::Statement).to receive(:new)
          .and_raise(Gitlab::Ci::Pipeline::Expression::Statement::StatementError.new('Invalid'))

        validator.validate!
        expect(inputs).to be_valid
      end
    end

    context 'when rule has no if clause' do
      let(:inputs_hash) do
        {
          region: {
            rules: [{ options: %w[local] }]
          }
        }
      end

      it 'does not fail validation for fallback rules' do
        validator.validate!
        expect(inputs).to be_valid
      end
    end

    context 'when there is a circular dependency' do
      let(:inputs_hash) do
        {
          region: {
            rules: [{ if: '$[[ inputs.size ]] == "large"', options: %w[us] }]
          },
          size: {
            rules: [{ if: '$[[ inputs.region ]] == "us"', options: %w[large] }]
          }
        }
      end

      it 'detects and reports circular dependency' do
        validator.validate!
        expect(inputs).not_to be_valid
        expect(inputs.errors).to include(match(/circular dependency detected/))
      end
    end

    context 'when there is a self-referencing input' do
      let(:inputs_hash) do
        {
          region: {
            rules: [{ if: '$[[ inputs.region ]] == "us"', options: %w[us eu] }]
          }
        }
      end

      it 'detects self-reference as circular dependency' do
        validator.validate!
        expect(inputs).not_to be_valid
        expect(inputs.errors).to include(match(/circular dependency detected/))
      end
    end

    context 'when there is a longer circular dependency chain' do
      let(:inputs_hash) do
        {
          input_a: {
            rules: [{ if: '$[[ inputs.input_b ]] == "value"', options: %w[a] }]
          },
          input_b: {
            rules: [{ if: '$[[ inputs.input_c ]] == "value"', options: %w[b] }]
          },
          input_c: {
            rules: [{ if: '$[[ inputs.input_a ]] == "value"', options: %w[c] }]
          }
        }
      end

      it 'reports circular dependency only once' do
        validator.validate!
        expect(inputs).not_to be_valid

        circular_errors = inputs.errors.select { |error| error.include?('circular dependency detected') }
        expect(circular_errors.size).to eq(1)
      end
    end

    context 'when there is a valid dependency chain' do
      let(:inputs_hash) do
        {
          environment: { options: %w[dev staging prod] },
          region: {
            rules: [{ if: '$[[ inputs.environment ]] == "prod"', options: %w[us eu] }]
          },
          size: {
            rules: [{ if: '$[[ inputs.region ]] == "us"', options: %w[large xlarge] }]
          }
        }
      end

      it 'allows valid dependency chains' do
        validator.validate!
        expect(inputs).to be_valid
      end
    end

    context 'when combining undefined inputs and circular dependencies' do
      let(:inputs_hash) do
        {
          input_a: {
            rules: [{ if: '$[[ inputs.input_b ]] == "value"', options: %w[a] }]
          },
          input_b: {
            rules: [{ if: '$[[ inputs.input_a ]] == "value" && $[[ inputs.undefined ]] == "x"', options: %w[b] }]
          }
        }
      end

      it 'reports both types of errors' do
        validator.validate!
        expect(inputs).not_to be_valid
        expect(inputs.errors).to include(
          match(/references undefined inputs/),
          match(/circular dependency detected/)
        )
      end
    end
  end
end
