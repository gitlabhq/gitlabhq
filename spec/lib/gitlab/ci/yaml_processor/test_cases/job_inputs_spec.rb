# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    RSpec.describe YamlProcessor, feature_category: :pipeline_composition do
      let_it_be(:project) { create(:project, :repository) }

      let(:result) { processor.execute }
      let(:builds) { result.builds }

      let(:config) do
        <<~YAML
          job_with_inputs:
            script: echo
            inputs:
              string_input:
                default: "hello"
              number_input:
                type: number
                default: 42
              boolean_input:
                type: boolean
                default: true
        YAML
      end

      subject(:processor) { described_class.new(config, user: nil, project: project) }

      it "includes the inputs in build's attributes" do
        expect(builds.first).to include(
          name: 'job_with_inputs',
          inputs: {
            string_input: {
              default: 'hello'
            },
            number_input: {
              type: 'number',
              default: 42
            },
            boolean_input: {
              type: 'boolean',
              default: true
            }
          }
        )
      end

      context 'when the ci_job_inputs feature flag is disabled' do
        before do
          stub_feature_flags(ci_job_inputs: false)
        end

        it 'returns an error about an unknown key' do
          expect(result).not_to be_valid
          expect(result.errors).to contain_exactly('jobs:job_with_inputs config contains unknown keys: inputs')
        end
      end
    end
  end
end
