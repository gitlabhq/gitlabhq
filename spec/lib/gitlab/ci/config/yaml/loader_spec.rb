# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Yaml::Loader, feature_category: :pipeline_composition do
  describe '#load' do
    let_it_be(:yaml) do
      File.read(Rails.root.join('spec/lib/gitlab/ci/config/yaml/fixtures/complex-included-ci.yml'))
    end

    let(:expected_config) do
      {
        variables: {
          ALLOW_FAILURE: false
        },
        'my-job-build': {
          stage: 'build',
          script: [
            'echo "Building with clang and optimization level 3"',
            'echo "1.0.0"'
          ],
          parallel: 2
        },
        'my-job-test': {
          stage: 'build',
          script: [
            'echo "Testing with pytest"',
            'if [ true == true ]; then echo "Coverage is enabled"; fi'
          ],
          allow_failure: false
        },
        'my-job-test-2': {
          stage: 'build',
          script: [
            'array item script 1',
            'array item script 2'
          ],
          rules: [
            { if: '$CI_PIPELINE_SOURCE == "merge_request_event"', changes: ['.gitlab-ci.yml'] },
            { if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/', when: 'never' },
            { if: '$CI_MERGE_REQUEST_TARGET_BRANCH_NAME != $CI_DEFAULT_BRANCH', when: 'manual' }
          ]
        },
        'my-job-deploy': {
          stage: 'build',
          script: ['echo "Deploying to production using blue-green strategy"'],
          rules: [
            { if: '$CI_PIPELINE_SOURCE != "merge_request_event"' }
          ]
        }
      }
    end

    let(:inputs) do
      {
        compiler: 'clang',
        optimization_level: 3,
        test_framework: '$TEST_FRAMEWORK',
        coverage_enabled: true,
        environment: 'production',
        deploy_strategy: 'blue-green',
        job_stage: 'build',
        test_script: [
          'array item script 1',
          'array item script 2'
        ],
        test_rules: [
          { if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/', when: 'never' },
          { if: '$CI_MERGE_REQUEST_TARGET_BRANCH_NAME != $CI_DEFAULT_BRANCH', when: 'manual' }
        ]
      }
    end

    let(:variables) do
      Gitlab::Ci::Variables::Collection.new([
        { key: 'TEST_FRAMEWORK', value: 'pytest', masked: false }
      ])
    end

    subject(:result) { described_class.new(yaml, inputs: inputs, variables: variables).load }

    it 'loads and interpolates CI config YAML' do
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

    context 'when there are errors with the inputs' do
      let(:inputs) do
        {
          coverage_enabled: 'true',
          deploy_strategy: 'not-an-option',
          version: 'test-version'
        }
      end

      it 'returns up to 3 error messages for input errors' do
        expect(result).not_to be_valid
        expect(result.error).to eq(
          '`coverage_enabled` input: provided value is not a boolean, ' \
          '`deploy_strategy` input: `not-an-option` cannot be used because it is not in the list of allowed options, ' \
          '`job_stage` input: required value has not been provided'
        )
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

      let(:inputs) { { test_input: 'test' } }

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
