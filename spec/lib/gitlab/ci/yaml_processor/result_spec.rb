# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    class YamlProcessor
      RSpec.describe Result do
        include StubRequests

        let(:user) { create(:user) }
        let(:ci_config) { Gitlab::Ci::Config.new(config_content, user: user) }
        let(:result) { described_class.new(ci_config: ci_config, warnings: ci_config&.warnings) }

        describe '#merged_yaml' do
          subject(:merged_yaml) { result.merged_yaml }

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
            expanded_config = YAML.safe_load(merged_yaml, [Symbol])
            included_config = YAML.safe_load(included_yml, [Symbol])

            expect(expanded_config).to include(*included_config.keys)
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
            is_expected.to match_array([
              { key: 'VAR1', value: 'value 11', public: true },
              { key: 'VAR2', value: 'value 2', public: true }
            ])
          end

          context 'when an absent job is sent' do
            let(:job_name) { :invalid_job }

            it { is_expected.to eq([]) }
          end
        end

        describe '#stage_for' do
          let(:config_content) do
            <<~YAML
              job:
                script: echo 'hello'
            YAML
          end

          let(:job_name) { :job }

          subject(:stage_for) { result.stage_for(job_name) }

          it { is_expected.to eq('test') }

          context 'when an absent job is sent' do
            let(:job_name) { :invalid_job }

            it { is_expected.to be_nil }
          end
        end
      end
    end
  end
end
