# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Yaml::Loader, feature_category: :pipeline_composition do
  describe '#load' do
    let_it_be(:project) { create(:project) }

    let(:inputs) { { test_input: 'hello test' } }
    let(:variables) { [] }

    let(:yaml) do
      <<~YAML
      ---
      spec:
        inputs:
          test_input:
      ---
      test_job:
        script:
          - echo "$[[ inputs.test_input ]]"
      YAML
    end

    subject(:result) { described_class.new(yaml, inputs: inputs, variables: variables).load }

    it 'loads and interpolates CI config YAML' do
      expected_config = { test_job: { script: ['echo "hello test"'] } }

      expect(result).to be_valid
      expect(result).to be_interpolated
      expect(result.content).to eq(expected_config)
    end

    it 'allows the use of YAML reference tags' do
      expect(Psych).to receive(:add_tag).once.with(
        ::Gitlab::Ci::Config::Yaml::Tags::Reference.tag,
        ::Gitlab::Ci::Config::Yaml::Tags::Reference
      )

      result
    end

    context 'when there is an error loading the YAML' do
      let(:yaml) { 'invalid...yaml' }

      it 'returns an error result' do
        expect(result).not_to be_valid
        expect(result.error).to eq('Invalid configuration format')
      end
    end

    context 'when there is an error interpolating the YAML' do
      let(:inputs) { {} }

      it 'returns an error result' do
        expect(result).not_to be_valid
        expect(result.error).to eq('`test_input` input: required value has not been provided')
      end
    end

    context 'when interpolating into a YAML key' do
      let(:yaml) do
        <<~YAML
        ---
        spec:
          inputs:
            test_input:
        ---
        "$[[ inputs.test_input ]]_job":
          script:
            - echo "test"
        YAML
      end

      it 'loads and interpolates CI config YAML' do
        expected_config = { 'hello test_job': { script: ['echo "test"'] } }

        expect(result).to be_valid
        expect(result).to be_interpolated
        expect(result.content).to eq(expected_config)
      end
    end

    context 'when interpolating values of different types' do
      let(:inputs) do
        {
          test_boolean: true,
          test_number: 8,
          test_string: 'test'
        }
      end

      let(:yaml) do
        <<~YAML
        ---
        spec:
          inputs:
            test_string:
              type: string
            test_boolean:
              type: boolean
            test_number:
              type: number
        ---
        "$[[ inputs.test_string ]]_job":
          allow_failure: $[[ inputs.test_boolean ]]
          parallel: $[[ inputs.test_number ]]
        YAML
      end

      it 'loads and interpolates CI config YAML' do
        expected_config = { test_job: { allow_failure: true, parallel: 8 } }

        expect(result).to be_valid
        expect(result).to be_interpolated
        expect(result.content).to eq(expected_config)
      end
    end

    context 'when interpolating and expanding variables' do
      let(:inputs) { { test_input: '$TEST_VAR' } }

      let(:variables) do
        Gitlab::Ci::Variables::Collection.new([
          { key: 'TEST_VAR', value: 'test variable', masked: false }
        ])
      end

      let(:yaml) do
        <<~YAML
        ---
        spec:
          inputs:
            test_input:
        ---
        "test_job":
          script:
            - echo "$[[ inputs.test_input | expand_vars ]]"
        YAML
      end

      it 'loads and interpolates CI config YAML' do
        expected_config = { test_job: { script: ['echo "test variable"'] } }

        expect(result).to be_valid
        expect(result).to be_interpolated
        expect(result.content).to eq(expected_config)
      end
    end

    context 'when there are too many interpolation blocks' do
      let(:inputs) { { first_input: 'first', second_input: 'second' } }

      let(:yaml) do
        <<~YAML
        ---
        spec:
          inputs:
            first_input:
            second_input:
        ---
        test_job:
          script:
            - echo "$[[ inputs.first_input ]]"
            - echo "$[[ inputs.second_input ]]"
        YAML
      end

      it 'returns an error result' do
        stub_const('::Gitlab::Ci::Config::Interpolation::Template::MAX_BLOCKS', 1)

        expect(result).not_to be_valid
        expect(result.error).to eq('too many interpolation blocks')
      end
    end

    context 'when a block is invalid' do
      let(:yaml) do
        <<~YAML
        ---
        spec:
          inputs:
            test_input:
        ---
        test_job:
          script:
            - echo "$[[ inputs.test_input | expand_vars | truncate(0,1) ]]"
        YAML
      end

      it 'returns an error result' do
        stub_const('::Gitlab::Ci::Config::Interpolation::Block::MAX_FUNCTIONS', 1)

        expect(result).not_to be_valid
        expect(result.error).to eq('too many functions in interpolation block')
      end
    end

    context 'when a node is too large' do
      it 'returns an error result' do
        stub_const('::Gitlab::Ci::Config::Interpolation::Config::MAX_NODE_SIZE', 1)

        expect(result).not_to be_valid
        expect(result.error).to eq('config node too large')
      end
    end

    context 'when given an empty YAML file' do
      let(:inputs) { {} }
      let(:yaml) { '' }

      it 'returns an empty result' do
        expect(result).to be_valid
        expect(result.content).to eq({})
      end
    end
  end

  describe '#load_uninterpolated_yaml' do
    let(:yaml) do
      <<~YAML
      ---
      spec:
        inputs:
          test_input:
      ---
      test_job:
        script:
          - echo "$[[ inputs.test_input ]]"
      YAML
    end

    subject(:result) { described_class.new(yaml).load_uninterpolated_yaml }

    it 'returns the config' do
      expected_content = { test_job: { script: ["echo \"$[[ inputs.test_input ]]\""] } }
      expect(result).to be_valid
      expect(result.content).to eq(expected_content)
    end

    context 'when there is a format error in the yaml' do
      let(:yaml) { 'invalid: yaml: all the time' }

      it 'returns an error' do
        expect(result).not_to be_valid
        expect(result.error).to include('mapping values are not allowed in this context')
      end
    end
  end
end
