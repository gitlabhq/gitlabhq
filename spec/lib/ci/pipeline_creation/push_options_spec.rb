# frozen_string_literal: true

require 'fast_spec_helper'
require 'oj'

RSpec.describe Ci::PipelineCreation::PushOptions, feature_category: :pipeline_composition do
  let(:ci_push_options) { {} }

  subject(:push_options) { described_class.new(ci_push_options) }

  describe '#skips_ci?' do
    context 'when there is no ci skip push option' do
      it 'returns false' do
        expect(push_options.skips_ci?).to be_falsey
      end
    end

    context 'when there is a ci skip push option' do
      let(:ci_push_options) { { ci: { skip: true } } }

      it 'returns true' do
        expect(push_options.skips_ci?).to be_truthy
      end
    end
  end

  describe '#variables' do
    context 'when push options contain variables' do
      let(:ci_push_options) do
        {
          ci: {
            variable: {
              "FOO=123": 1,
              "BAR=456": 1,
              "MNO=890=ABC": 1
            }
          }
        }
      end

      it 'returns the extracted key value variable pairs from the push options' do
        extracted_variables = [
          { "key" => "FOO", "variable_type" => "env_var", "secret_value" => "123" },
          { "key" => "BAR", "variable_type" => "env_var", "secret_value" => "456" },
          { "key" => "MNO", "variable_type" => "env_var", "secret_value" => "890=ABC" }
        ]

        expect(push_options.variables).to eq(extracted_variables)
      end
    end

    context 'when there are no variables in the push options' do
      it 'returns an empty array' do
        expect(push_options.variables).to eq([])
      end
    end

    context 'when there are variables with a missing `key` or `value`' do
      let(:ci_push_options) do
        {
          ci: {
            variable: {
              "=123": 1,
              ABC: 1,
              "ABC=": 1
            }
          }
        }
      end

      it 'returns an empty string for the only valid format `KEY=`' do
        variable = ["key" => "ABC", "secret_value" => "", "variable_type" => "env_var"]
        expect(push_options.variables).to match_array(variable)
      end
    end
  end

  describe '#inputs' do
    context 'when there are inputs in the push options' do
      let(:ci_push_options) do
        {
          ci: {
            input: {
              'security_scan=false': 1,
              'stage=test': 1,
              'level=20': 1,
              'environments=["staging", "production"]': 1,
              'rules=[{"if": "$CI_MERGE_REQUEST_ID"}, {"if": "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"}]': 1
            }
          }
        }
      end

      it 'returns the extracted key value input pairs from the push options' do
        extracted_inputs =
          {
            security_scan: false,
            stage: 'test',
            level: 20,
            environments: %w[
              staging production
            ],
            rules: [
              { if: "$CI_MERGE_REQUEST_ID" },
              { if: "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH" }
            ]
          }
        expect(push_options.inputs).to eq(extracted_inputs)
      end
    end

    context 'when there are no inputs in the push options' do
      it 'returns an empty hash' do
        expect(push_options.inputs).to eq({})
      end
    end
  end

  describe '.fabricate' do
    context 'when push options are a Hash' do
      it 'creates a new instance of the PushOptions class' do
        push_options = described_class.fabricate({ ci: { skip: true } })

        expect(push_options.skips_ci?).to be_truthy
        expect(push_options).to be_a described_class
      end
    end

    context 'when push options are blank' do
      it 'initalizes an empty instance of the PushOptions class' do
        push_options = described_class.fabricate(nil)

        expect(push_options).to be_a described_class
      end
    end

    context 'when push options are already an instance of PushOption' do
      it 'returns that instance' do
        inputs =
          {
            ci: {
              input: {
                'security_scan=false': 1
              }
            }
          }

        existing_push_option = described_class.new(inputs)
        push_options = described_class.fabricate(existing_push_option)

        expect(push_options).to be(existing_push_option)
      end
    end

    context 'when push options are none of these' do
      it 'raises an Argument Error' do
        expect { described_class.fabricate(1) }.to raise_error(ArgumentError, 'Unknown type of push_option')
      end
    end
  end
end
