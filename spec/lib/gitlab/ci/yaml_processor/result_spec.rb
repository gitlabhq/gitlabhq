# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    class YamlProcessor
      RSpec.describe Result, feature_category: :pipeline_composition do
        include StubRequests

        let(:user) { create(:user) }
        let(:ci_config) { Gitlab::Ci::Config.new(config_content, user: user) }
        let(:result) { described_class.new(ci_config: ci_config, warnings: ci_config&.warnings) }

        let(:config_content) do
          <<~YAML
            job:
              script: echo 'hello'
          YAML
        end

        describe '#builds' do
          context 'when a job has ID tokens' do
            let(:config_content) do
              YAML.dump(
                test: { stage: 'test', script: 'echo', id_tokens: { TEST_ID_TOKEN: { aud: 'https://gitlab.com' } } }
              )
            end

            it 'includes `id_tokens`' do
              expect(result.builds.first[:id_tokens]).to eq({ TEST_ID_TOKEN: { aud: 'https://gitlab.com' } })
            end
          end
        end

        describe '#config_metadata' do
          subject(:config_metadata) { result.config_metadata }

          let(:config_content) do
            YAML.dump(
              include: { remote: 'https://example.com/sample.yml' },
              test: { stage: 'test', script: 'echo' }
            )
          end

          let(:included_yml) do
            YAML.dump(
              { another_test: { stage: 'test', script: 'echo 2' } }.deep_stringify_keys
            )
          end

          before do
            stub_full_request('https://example.com/sample.yml').to_return(body: included_yml)
          end

          it 'returns expanded yaml config' do
            expanded_config = YAML.safe_load(config_metadata[:merged_yaml], permitted_classes: [Symbol])
            included_config = YAML.safe_load(included_yml, permitted_classes: [Symbol])

            expect(expanded_config).to include(*included_config.keys)
          end

          it 'returns includes' do
            expect(config_metadata[:includes]).to contain_exactly(
              { type: :remote,
                location: 'https://example.com/sample.yml',
                blob: nil,
                raw: 'https://example.com/sample.yml',
                extra: {},
                context_project: nil,
                context_sha: nil }
            )
          end
        end

        describe '#yaml_variables_for' do
          let(:config_content) do
            <<~YAML
              variables:
                VAR1: value 1
                VAR2: value 2

              job:
                script: echo 'hello'
                variables:
                  VAR1: value 11
            YAML
          end

          let(:job_name) { :job }

          subject(:yaml_variables_for) { result.yaml_variables_for(job_name) }

          it 'returns calculated variables with root and job variables' do
            is_expected.to match_array(
              [
                { key: 'VAR1', value: 'value 11' },
                { key: 'VAR2', value: 'value 2' }
              ])
          end

          context 'when an absent job is sent' do
            let(:job_name) { :invalid_job }

            it { is_expected.to eq([]) }
          end
        end

        describe '#stage_for' do
          let(:job_name) { :job }

          subject(:stage_for) { result.stage_for(job_name) }

          it { is_expected.to eq('test') }

          context 'when an absent job is sent' do
            let(:job_name) { :invalid_job }

            it { is_expected.to be_nil }
          end
        end

        describe '#included_components' do
          it 'delegates to ci_config and memoizes the result' do
            expect(ci_config).to receive(:included_components).once

            result.included_components
            result.included_components
          end
        end
      end
    end
  end
end
