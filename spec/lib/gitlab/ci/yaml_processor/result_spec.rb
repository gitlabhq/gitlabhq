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

          context 'when a job has manual_confirmation' do
            let(:config_content) do
              YAML.dump(
                test: { stage: 'test', script: 'echo', manual_confirmation: 'manual confirmation message' }
              )
            end

            it 'includes `manual_confirmation`' do
              expect(result.builds.first[:options][:manual_confirmation]).to eq('manual confirmation message')
            end
          end
        end

        describe '#uses_keyword?' do
          subject { result.uses_keyword?(keyword) }

          using_table = {
            run: {
              present: <<~YAML,
                job1:
                  script: echo
                job2:
                  run:
                    - name: test_run
                      script: echo run step
              YAML
              absent: <<~YAML
                job1:
                  script: echo
                job2:
                  script: echo
              YAML
            },
            only: {
              present: <<~YAML,
                job1:
                  script: echo
                  only:
                    - main
                    - /^issue-.*$/
                    - merge_requests
                job2:
                  script: echo
              YAML
              absent: <<~YAML
                job1:
                  script: echo
                  rules:
                    - if: $CI_COMMIT_BRANCH
                    - if: $CI_COMMIT_TAG
                job2:
                  script: echo
                  rules:
                    - if: $CI_COMMIT_BRANCH
                    - if: $CI_COMMIT_TAG
              YAML
            },
            except: {
              present: <<~YAML,
                job1:
                  script: echo
                job2:
                  script: echo
                  except:
                    - main
                    - /^stable-branch.*$/
                    - schedules
              YAML
              absent: <<~YAML
                job1:
                  script: echo
                job2:
                  script: echo
              YAML
            }
          }

          using_table.each do |tested_keyword, configs|
            context "when checking for :#{tested_keyword} keyword" do
              let(:keyword) { tested_keyword }

              context "when the :#{tested_keyword} keyword is present in a job" do
                let(:config_content) { configs[:present] }

                it { is_expected.to be_truthy }
              end

              context "when the :#{tested_keyword} keyword is not present in any job" do
                let(:config_content) { configs[:absent] }

                it { is_expected.to be_falsey }
              end
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

        describe '#clear_jobs!' do
          it 'clears jobs' do
            expect { result.clear_jobs! }.to change { result.jobs }.to eq({})
          end

          it 'keeps stages' do
            expect { result.clear_jobs! }.not_to change { result.stages }
          end
        end
      end
    end
  end
end
