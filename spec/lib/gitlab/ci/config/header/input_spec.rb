# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Input, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory
      .new(described_class)
      .value(config)
      .with(key: input_name)
  end

  let(:input_name) { 'environment' }

  subject(:entry) { factory.create!.tap(&:compose!) }

  describe 'validations' do
    let(:required_config) { {} }

    it_behaves_like 'BaseInput'
  end

  describe 'rules configurations' do
    before do
      stub_feature_flags(ci_dynamic_pipeline_inputs: true)
    end

    context 'when rules are valid' do
      let(:config) do
        {
          rules: [
            { if: '$[[ inputs.environment ]] == "production"', options: %w[option_a option_b] },
            { options: %w[option_c option_d] }
          ]
        }
      end

      it 'is valid' do
        expect(entry).to be_valid
        expect(entry.errors).to be_empty
      end

      it 'processes and returns rules' do
        expect(entry.input_rules).to eq(config[:rules])
      end
    end

    context 'with empty rules array' do
      let(:config) { { rules: [] } }

      it 'is valid' do
        expect(entry).to be_valid
        expect(entry.errors).to be_empty
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(ci_dynamic_pipeline_inputs: false)
      end

      let(:config) do
        {
          rules: [
            { if: '$[[ inputs.environment ]] == "production"', options: %w[option_a option_b] }
          ]
        }
      end

      it 'is not valid' do
        expect(entry).not_to be_valid
      end

      it 'reports error about rules not being supported' do
        expect(entry.errors).to include('environment rules is not yet supported')
      end
    end

    describe 'invalid rules configurations' do
      context 'when rules are not an array' do
        let(:config) { { rules: 'invalid' } }

        it 'is not valid' do
          expect(entry).not_to be_valid
        end

        it 'reports error about rules type' do
          expect(entry.errors).to eq(['environment:rules config should be an array'])
        end
      end

      context 'when rule is not a hash' do
        let(:config) { { rules: ['invalid'] } }

        it 'is not valid' do
          expect(entry).not_to be_valid
        end

        it 'reports error about rule type' do
          expect(entry.errors).to eq(['environment:rules:rule config should be a hash'])
        end
      end

      context 'when rule contains invalid keys' do
        let(:config) do
          {
            rules: [
              { if: '$[[ inputs.env ]] == "prod"', invalid_key: 'value' }
            ]
          }
        end

        it 'is not valid' do
          expect(entry).not_to be_valid
        end

        it 'reports error about unknown keys' do
          expect(entry.errors).to eq(['environment:rules:rule config contains unknown keys: invalid_key'])
        end
      end

      context "when rule has 'if', but no 'options' or 'default'" do
        let(:config) do
          {
            rules: [{ if: '$[[ inputs.environment ]] == "production"' }]
          }
        end

        it 'is not valid' do
          expect(entry).not_to be_valid
        end

        it 'reports error about missing options or default' do
          expect(entry.errors).to eq([
            'environment:rules:rule config rule with \'if\' must define \'options\' or \'default\''
          ])
        end
      end

      context 'when fallback rule has no options' do
        let(:config) do
          {
            rules: [{ default: 'value_a' }]
          }
        end

        it 'is not valid' do
          expect(entry).not_to be_valid
        end

        it 'reports error about missing options' do
          expect(entry.errors).to eq(['environment:rules:rule config fallback rule must define \'options\''])
        end
      end

      context 'when rules conflict with other keys' do
        context 'when rules and options are both present' do
          let(:config) do
            {
              rules: [{ options: %w[option_a] }],
              options: %w[option_b option_c]
            }
          end

          it 'is not valid' do
            expect(entry).not_to be_valid
          end

          it 'reports error about mutually exclusive keys' do
            expect(entry.errors).to eq(['environment config these keys cannot be used together: rules, options'])
          end
        end

        context 'when rules and default are both present' do
          let(:config) do
            {
              rules: [{ options: %w[option_a], default: 'option_a' }],
              default: 'value_b'
            }
          end

          it 'is not valid' do
            expect(entry).not_to be_valid
          end

          it 'reports error about mutually exclusive keys' do
            expect(entry.errors).to eq(['environment config these keys cannot be used together: rules, default'])
          end
        end
      end
    end
  end
end
