# frozen_string_literal: true

require 'spec_helper'

module Ci
  RSpec.describe CreatePipelineService, feature_category: :pipeline_composition do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }

    let(:pipeline) { service.execute(:push).payload }

    let(:config) do
      <<~YAML
      rspec:
        script: echo
        inputs:
          test_string:
            default: "hello world"
          test_number:
            type: number
            default: 42
          test_boolean:
            type: boolean
            default: true
          test_array:
            type: array
            default: ["item1", "item2"]
      YAML
    end

    subject(:service) { described_class.new(project, user, { ref: 'master' }) }

    before do
      stub_ci_pipeline_yaml_file(config)
    end

    it 'stores inputs spec in build options' do
      expect(pipeline).to be_created_successfully

      rspec_job = pipeline.processables.find_by(name: 'rspec')
      expect(rspec_job.options[:inputs]).to eq(
        test_string: {
          default: 'hello world'
        },
        test_number: {
          type: 'number',
          default: 42
        },
        test_boolean: {
          type: 'boolean',
          default: true
        },
        test_array: {
          type: 'array',
          default: %w[item1 item2]
        }
      )
    end

    context 'with invalid inputs' do
      let(:config) do
        <<~YAML
          rspec:
            script: echo
            inputs:
              invalid_input:
                type: number
                default: "not a number"
        YAML
      end

      it 'creates the pipeline with a failed status and validation error' do
        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.errors.full_messages).to contain_exactly(
          'jobs:rspec inputs `invalid_input`: default value is not a number'
        )
      end
    end

    context 'when the ci_job_inputs feature flag is disabled' do
      let(:config) do
        <<~YAML
          rspec:
            script: echo
            inputs:
              test_input:
                default: "hello"
        YAML
      end

      before do
        stub_feature_flags(ci_job_inputs: false)
      end

      it 'creates a failed pipeline with a config error' do
        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.errors.full_messages).to contain_exactly('jobs:rspec config contains unknown keys: inputs')
      end
    end
  end
end
