# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Input, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory
      .new(described_class)
      .value(input_hash)
      .with(key: input_name)
  end

  let(:input_name) { 'environment' }

  subject(:config) { factory.create!.tap(&:compose!) }

  shared_examples 'a valid input' do
    let(:expected_hash) { input_hash }

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns the value' do
      expect(config.value).to eq(expected_hash)
    end
  end

  shared_examples 'an invalid input' do
    let(:expected_hash) { input_hash }

    it 'fails validations' do
      expect(config).not_to be_valid
      expect(config.errors).to eq(expected_errors)
    end

    it 'returns the value' do
      expect(config.value).to eq(expected_hash)
    end
  end

  describe 'valid configurations' do
    context 'when is a required input' do
      let(:input_hash) { nil }

      it_behaves_like 'a valid input'
    end

    context 'when has a string default value' do
      let(:input_hash) { { default: 'production' } }

      it_behaves_like 'a valid input'
    end

    context 'when has a numeric default value' do
      let(:input_hash) { { default: 6.66 } }

      it_behaves_like 'a valid input'
    end

    context 'when has a boolean default value' do
      let(:input_hash) { { default: true } }

      it_behaves_like 'a valid input'
    end

    context 'when has a description value' do
      let(:input_hash) { { description: 'Target deployment environment' } }

      it_behaves_like 'a valid input'
    end

    context 'when given a valid type' do
      where(:input_type) { ::Ci::Inputs::Builder.input_types }

      with_them do
        let(:input_hash) { { type: input_type } }

        it_behaves_like 'a valid input'
      end
    end

    context 'when the input has RegEx validation' do
      let(:input_hash) { { regex: '\w+' } }

      it_behaves_like 'a valid input'
    end
  end

  describe 'invalid configurations' do
    context 'when has invalid name' do
      let(:input_name) { [123] }
      let(:input_hash) { {} }
      let(:expected_errors) { ['123 key must be an alphanumeric string'] }

      it_behaves_like 'an invalid input'
    end

    context 'when contains unknown keywords' do
      let(:input_hash) { { test: 123 } }
      let(:expected_errors) { ['environment config contains unknown keys: test'] }

      it_behaves_like 'an invalid input'
    end

    context 'when given an invalid type' do
      let(:input_hash) { { type: 'datetime' } }
      let(:expected_errors) { ['environment input type unknown value: datetime'] }

      it_behaves_like 'an invalid input'
    end

    context 'when RegEx validation value is not a string' do
      let(:input_hash) { { regex: [] } }
      let(:expected_errors) { ['environment input regex should be a string'] }

      it_behaves_like 'an invalid input'
    end

    context 'when options exceed the limit' do
      let(:limit) { described_class::ALLOWED_OPTIONS_LIMIT }
      let(:input_hash) { { default: 'value1', options: options } }
      let(:options) { Array.new(limit.next) { |i| "value#{i}" } }
      let(:expected_errors) { ["environment config cannot define more than #{limit} options"] }

      it_behaves_like 'an invalid input'
    end
  end

  describe 'rules configurations' do
    before do
      stub_feature_flags(ci_dynamic_pipeline_inputs: true)
    end

    context 'when rules are valid' do
      let(:input_hash) do
        {
          rules: [
            { if: '$[[ inputs.environment ]] == "production"', options: %w[option_a option_b] },
            { options: %w[option_c option_d] }
          ]
        }
      end

      it_behaves_like 'a valid input'

      it 'processes and returns rules' do
        expect(config.input_rules).to eq(input_hash[:rules])
      end
    end

    context 'with empty rules array' do
      let(:input_hash) { { rules: [] } }

      it_behaves_like 'a valid input'
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(ci_dynamic_pipeline_inputs: false)
      end

      let(:input_hash) do
        {
          rules: [
            { if: '$[[ inputs.environment ]] == "production"', options: %w[option_a option_b] }
          ]
        }
      end

      it 'marks config as invalid' do
        expect(config).not_to be_valid
        expect(config.errors).to include('environment rules is not yet supported')
      end
    end

    describe 'invalid rules configurations' do
      context 'when rules are not an array' do
        let(:input_hash) { { rules: 'invalid' } }
        let(:expected_errors) { ['environment:rules config should be an array'] }

        it_behaves_like 'an invalid input'
      end

      context 'when rule is not a hash' do
        let(:input_hash) { { rules: ['invalid'] } }
        let(:expected_errors) { ['environment:rules:rule config should be a hash'] }

        it_behaves_like 'an invalid input'
      end

      context 'when rule contains invalid keys' do
        let(:input_hash) do
          {
            rules: [
              { if: '$[[ inputs.env ]] == "prod"', invalid_key: 'value' }
            ]
          }
        end

        let(:expected_errors) { ['environment:rules:rule config contains unknown keys: invalid_key'] }

        it_behaves_like 'an invalid input'
      end

      context "when rule has 'if', but no 'options' or 'default'" do
        let(:input_hash) do
          {
            rules: [{ if: '$[[ inputs.environment ]] == "production"' }]
          }
        end

        let(:expected_errors) do
          ['environment:rules:rule config rule with \'if\' must define \'options\' or \'default\'']
        end

        it_behaves_like 'an invalid input'
      end

      context 'when fallback rule has no options' do
        let(:input_hash) do
          {
            rules: [{ default: 'value_a' }]
          }
        end

        let(:expected_errors) { ['environment:rules:rule config fallback rule must define \'options\''] }

        it_behaves_like 'an invalid input'
      end

      context 'when rules conflict with other keys' do
        context 'when rules and options are both present' do
          let(:input_hash) do
            {
              rules: [{ options: %w[option_a] }],
              options: %w[option_b option_c]
            }
          end

          let(:expected_errors) { ['environment config these keys cannot be used together: rules, options'] }

          it_behaves_like 'an invalid input'
        end

        context 'when rules and default are both present' do
          let(:input_hash) do
            {
              rules: [{ options: %w[option_a], default: 'option_a' }],
              default: 'value_b'
            }
          end

          let(:expected_errors) { ['environment config these keys cannot be used together: rules, default'] }

          it_behaves_like 'an invalid input'
        end
      end
    end
  end
end
