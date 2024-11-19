# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    RSpec.describe YamlProcessor, feature_category: :pipeline_composition do
      include StubRequests
      include RepoHelpers

      subject(:processor) { described_class.new(config, user: nil).execute }

      shared_examples 'returns errors' do |error_message|
        it 'adds a message when an error is encountered' do
          expect(subject.errors).to include(error_message)
        end
      end

      describe '#builds' do
        subject(:builds) { described_class.new(config, user: nil).execute.builds }

        let(:rspec_build) { builds.find { |build| build[:name] == 'rspec' } }

        describe 'attributes list' do
          let(:config) do
            YAML.dump(
              before_script: ['pwd'],
              rspec: {
                script: 'rspec',
                interruptible: true
              }
            )
          end

          it 'returns valid build attributes' do
            expect(builds).to eq([{
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"]
              },
              interruptible: true,
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            }])
          end
        end

        context 'with execution config' do
          let(:config) do
            YAML.dump(
              hello_steps: {
                artifacts: { access: 'developer' },
                run: [
                  name: 'hello_steps',
                  step: 'some_step_reference',
                  inputs: {
                    echo: 'hello steps!!'
                  }
                ]
              }
            )
          end

          it 'returns valid build attributes with execution config' do
            expect(builds).to eq([{
              stage: 'test',
              stage_idx: 2,
              name: 'hello_steps',
              options: { artifacts: { access: 'developer' } },
              allow_failure: false,
              execution_config: {
                run_steps: [{
                  inputs: { echo: 'hello steps!!' },
                  name: 'hello_steps',
                  step: 'some_step_reference'
                }]
              },
              when: 'on_success',
              job_variables: [],
              only: { refs: %w[branches tags] },
              root_variables_inheritance: true,
              scheduling_type: :stage
            }])
          end

          context 'when run steps is empty' do
            let(:config) do
              YAML.dump(
                hello_steps: {
                  artifacts: { access: 'developer' },
                  run: []
                }
              )
            end

            it 'returns valid build attributes with empty run config' do
              expect(builds).to eq([{
                stage: 'test',
                stage_idx: 2,
                name: 'hello_steps',
                options: { artifacts: { access: 'developer' } },
                allow_failure: false,
                execution_config: {
                  run_steps: []
                },
                when: 'on_success',
                job_variables: [],
                only: { refs: %w[branches tags] },
                root_variables_inheritance: true,
                scheduling_type: :stage
              }])
            end
          end
        end

        context 'with job rules' do
          let(:config) do
            YAML.dump(
              rspec: {
                script: 'rspec',
                rules: [
                  { if: '$CI_COMMIT_REF_NAME == "master"' },
                  { changes: %w[README.md] }
                ]
              }
            )
          end

          it 'returns valid build attributes' do
            expect(builds).to eq([{
              stage: 'test',
              stage_idx: 2,
              name: 'rspec',
              options: { script: ['rspec'] },
              rules: [
                { if: '$CI_COMMIT_REF_NAME == "master"' },
                { changes: { paths: %w[README.md] } }
              ],
              allow_failure: false,
              when: 'on_success',
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            }])
          end
        end

        describe 'coverage entry' do
          describe 'code coverage regexp' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec',
                                 coverage: '/Code coverage: \d+\.\d+/' })
            end

            it 'includes coverage regexp in build attributes' do
              expect(rspec_build)
                .to include(coverage_regex: 'Code coverage: \d+\.\d+')
            end
          end
        end

        describe 'tags entry with default values' do
          let(:config) do
            YAML.dump(
              default: { tags: %w[A B] },
              rspec: { script: "rspec" }
            )
          end

          it 'applies default values' do
            expect(rspec_build).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: { script: ["rspec"] },
              scheduling_type: :stage,
              tag_list: %w[A B],
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true
            })
          end
        end

        describe 'retry entry' do
          context 'when retry count is specified' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec', retry: { max: 1 } })
            end

            it 'includes retry count in build options attribute' do
              expect(rspec_build[:options]).to include(retry: { max: 1 })
            end
          end

          context 'when retry count is not specified' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec' })
            end

            it 'does not persist retry count in the database' do
              expect(rspec_build[:options]).not_to have_key(:retry)
            end
          end

          context 'when retry count is specified by default' do
            let(:config) do
              YAML.dump(default: { retry: { max: 1 } }, rspec: { script: 'rspec' })
            end

            it 'does use the default value' do
              expect(rspec_build[:options]).to include(retry: { max: 1 })
            end
          end

          context 'when retry count default value is overridden' do
            let(:config) do
              YAML.dump(
                default: { retry: { max: 1 } }, rspec: { script: 'rspec', retry: { max: 2 } }
              )
            end

            it 'does use the job value' do
              expect(rspec_build[:options]).to include(retry: { max: 2 })
            end
          end
        end

        describe 'allow failure entry' do
          context 'when job is a manual action' do
            context 'when allow_failure is defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec', when: 'manual', allow_failure: false })
              end

              it 'is not allowed to fail' do
                expect(rspec_build[:allow_failure]).to be false
              end
            end

            context 'when allow_failure is not defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec', when: 'manual' })
              end

              it 'is allowed to fail' do
                expect(rspec_build[:allow_failure]).to be true
              end
            end

            context 'when allow_failure has exit_codes' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec', when: 'manual', allow_failure: { exit_codes: 1 } })
              end

              it 'is not allowed to fail' do
                expect(rspec_build[:allow_failure]).to be false
              end

              it 'saves allow_failure_criteria into options' do
                expect(rspec_build[:options]).to match(
                  a_hash_including(allow_failure_criteria: { exit_codes: [1] }))
              end
            end
          end

          context 'when job is not a manual action' do
            context 'when allow_failure is defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec', allow_failure: false })
              end

              it 'is not allowed to fail' do
                expect(rspec_build[:allow_failure]).to be false
              end
            end

            context 'when allow_failure is not defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec' })
              end

              it 'is not allowed to fail' do
                expect(rspec_build[:allow_failure]).to be false
              end
            end

            context 'when allow_failure is dynamically specified' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec', allow_failure: { exit_codes: 1 } })
              end

              it 'is not allowed to fail' do
                expect(rspec_build[:allow_failure]).to be false
              end

              it 'saves allow_failure_criteria into options' do
                expect(rspec_build[:options]).to match(
                  a_hash_including(allow_failure_criteria: { exit_codes: [1] }))
              end
            end
          end
        end

        describe 'delayed job entry' do
          context 'when delayed is defined' do
            let(:config) do
              YAML.dump(rspec: {
                script: 'rollout 10%',
                when: 'delayed',
                start_in: '1 day'
              })
            end

            it 'has the attributes' do
              expect(rspec_build[:when]).to eq 'delayed'
              expect(rspec_build[:options][:start_in]).to eq '1 day'
            end
          end
        end

        describe 'resource group' do
          context 'when resource group is defined' do
            let(:config) do
              YAML.dump(rspec: {
                script: 'test',
                resource_group: 'iOS'
              })
            end

            it 'has the attributes' do
              expect(rspec_build[:resource_group_key]).to eq 'iOS'
            end
          end
        end

        describe 'bridge job' do
          let(:config) do
            YAML.dump(rspec: {
              trigger: {
                project: 'namespace/project',
                branch: 'main'
              }
            })
          end

          it 'has the attributes' do
            expect(rspec_build[:options]).to eq(
              trigger: { project: 'namespace/project', branch: 'main' }
            )
          end

          context 'with forward' do
            let(:config) do
              YAML.dump(rspec: {
                trigger: {
                  project: 'namespace/project',
                  forward: { pipeline_variables: true }
                }
              })
            end

            it 'has the attributes' do
              expect(rspec_build[:options]).to eq(
                trigger: { project: 'namespace/project', forward: { pipeline_variables: true } }
              )
            end
          end
        end
      end

      describe '#stages_attributes' do
        let(:config) do
          YAML.dump(
            rspec: { script: 'rspec', stage: 'test', only: ['branches'] },
            prod: { script: 'cap prod', stage: 'deploy', only: ['tags'] }
          )
        end

        let(:attributes) do
          [{ name: ".pre",
             index: 0,
             builds: [] },
           { name: "build",
             index: 1,
             builds: [] },
           { name: "test",
             index: 2,
             builds:
               [{ stage_idx: 2,
                  stage: "test",
                  name: "rspec",
                  allow_failure: false,
                  when: "on_success",
                  job_variables: [],
                  root_variables_inheritance: true,
                  scheduling_type: :stage,
                  options: { script: ["rspec"] },
                  only: { refs: ["branches"] } }] },
           { name: "deploy",
             index: 3,
             builds:
               [{ stage_idx: 3,
                  stage: "deploy",
                  name: "prod",
                  allow_failure: false,
                  when: "on_success",
                  job_variables: [],
                  root_variables_inheritance: true,
                  scheduling_type: :stage,
                  options: { script: ["cap prod"] },
                  only: { refs: ["tags"] } }] },
           { name: ".post",
             index: 4,
             builds: [] }]
        end

        it 'returns stages seed attributes' do
          expect(subject.stages_attributes).to eq attributes
        end
      end

      describe 'workflow attributes' do
        context 'with disallowed workflow:variables' do
          let(:config) do
            <<-EOYML
              workflow:
                rules:
                  - if: $VAR == "value"
                variables:
                  UNSUPPORTED: "unparsed"
            EOYML
          end

          it_behaves_like 'returns errors', 'workflow config contains unknown keys: variables'
        end

        context 'with rules and variables' do
          let(:config) do
            <<-EOYML
              variables:
                SUPPORTED: "parsed"

              workflow:
                rules:
                  - if: $VAR == "value"

              hello:
                script: echo world
            EOYML
          end

          it 'parses the workflow:rules configuration' do
            expect(subject.workflow_rules).to contain_exactly({ if: '$VAR == "value"' })
          end

          it 'parses the root:variables as #root_variables' do
            expect(subject.root_variables)
              .to contain_exactly({ key: 'SUPPORTED', value: 'parsed' })
          end
        end

        context 'with rules and no variables' do
          let(:config) do
            <<-EOYML
              workflow:
                rules:
                  - if: $VAR == "value"

              hello:
                script: echo world
            EOYML
          end

          it 'parses the workflow:rules configuration' do
            expect(subject.workflow_rules).to contain_exactly({ if: '$VAR == "value"' })
          end

          it 'parses the root:variables as #root_variables' do
            expect(subject.root_variables).to eq([])
          end
        end

        context 'with variables and no rules' do
          let(:config) do
            <<-EOYML
              variables:
                SUPPORTED: "parsed"

              hello:
                script: echo world
            EOYML
          end

          it 'parses the workflow:rules configuration' do
            expect(subject.workflow_rules).to be_nil
          end

          it 'parses the root:variables as #root_variables' do
            expect(subject.root_variables)
              .to contain_exactly({ key: 'SUPPORTED', value: 'parsed' })
          end
        end

        context 'with no rules and no variables' do
          let(:config) do
            <<-EOYML
              hello:
                script: echo world
            EOYML
          end

          it 'parses the workflow:rules configuration' do
            expect(subject.workflow_rules).to be_nil
          end

          it 'parses the root:variables as #root_variables' do
            expect(subject.root_variables).to eq([])
          end
        end

        context 'with name' do
          let(:config) do
            <<-EOYML
              workflow:
                name: 'Pipeline name'

              hello:
                script: echo world
            EOYML
          end

          it 'parses the workflow:name as workflow_name' do
            expect(subject.workflow_name).to eq('Pipeline name')
          end
        end

        context 'with no name' do
          let(:config) do
            <<-EOYML
              hello:
                script: echo world
            EOYML
          end

          it 'parses the workflow:name' do
            expect(subject.workflow_name).to be_nil
          end
        end

        context 'with auto_cancel' do
          let(:config) do
            <<-YML
              workflow:
                auto_cancel:
                  on_new_commit: interruptible
                  on_job_failure: all

              hello:
                script: echo world
            YML
          end

          it 'parses the workflow:auto_cancel as workflow_auto_cancel' do
            expect(subject.workflow_auto_cancel).to eq({
              on_new_commit: 'interruptible',
              on_job_failure: 'all'
            })
          end
        end

        context 'with rules and auto_cancel' do
          let(:config) do
            <<-YML
              workflow:
                rules:
                  - if: $VAR == "value"
                    auto_cancel:
                      on_new_commit: none
                      on_job_failure: none

              hello:
                script: echo world
            YML
          end

          it 'parses workflow_rules' do
            expect(subject.workflow_rules).to contain_exactly({
              if: '$VAR == "value"',
              auto_cancel: {
                on_new_commit: 'none',
                on_job_failure: 'none'
              }
            })
          end
        end
      end

      describe '#warnings' do
        context 'when a warning is raised in a given entry' do
          let(:config) do
            <<-EOYML
            rspec:
              script: echo
              rules:
                - when: always
            EOYML
          end

          it 'is propagated all the way up to the processor' do
            expect(subject.warnings).to contain_exactly(/jobs:rspec may allow multiple pipelines to run/)
          end
        end

        context 'when a warning is raised together with errors' do
          let(:config) do
            <<-EOYML
              rspec:
                script: rspec
                rules:
                  - when: always
              invalid:
                script: echo
                artifacts:
                  - wrong_key: value
            EOYML
          end

          it 'is propagated all the way up into the raised exception' do
            expect(subject).not_to be_valid
            expect(subject.warnings).to contain_exactly(/jobs:rspec may allow multiple pipelines to run/)
          end

          it_behaves_like 'returns errors', 'jobs:invalid:artifacts config should be a hash'
        end

        context 'when error is raised before composing the config' do
          let(:config) do
            <<-EOYML
              include: unknown/file.yml
              rspec:
                script: rspec
                rules:
                  - when: always
            EOYML
          end

          it 'has empty warnings' do
            expect(subject.warnings).to be_empty
          end

          it_behaves_like 'returns errors', 'Local file `unknown/file.yml` does not have project!'
        end

        context 'when error is raised after composing the config with warnings' do
          shared_examples 'has warnings and expected error' do |error_message|
            it 'returns errors and warnings', :aggregate_failures do
              expect(subject.errors).to include(error_message)
              expect(subject.warnings).to be_present
            end
          end

          context 'when stage does not exist' do
            let(:config) do
              <<-EOYML
                rspec:
                  stage: custom_stage
                  script: rspec
                  rules:
                    - when: always
              EOYML
            end

            it_behaves_like 'has warnings and expected error', /rspec job: chosen stage custom_stage does not exist/
          end

          context 'job dependency does not exist' do
            let(:config) do
              <<-EOYML
                build:
                  stage: build
                  script: echo
                  rules:
                    - when: always
                test:
                  stage: test
                  script: echo
                  needs: [unknown_job]
              EOYML
            end

            it_behaves_like 'has warnings and expected error', /test job: undefined need: unknown_job/
          end

          context 'job dependency defined in later stage' do
            let(:config) do
              <<-EOYML
                build:
                  stage: build
                  script: echo
                  needs: [test]
                  rules:
                    - when: always
                test:
                  stage: test
                  script: echo
              EOYML
            end

            it_behaves_like 'has warnings and expected error', /build job: need test is not defined in current or prior stages/
          end

          describe '#validate_job_needs!' do
            context "when all validations pass" do
              let(:config) do
                <<-EOYML
                    stages:
                      - lint
                    lint_job:
                      needs: [lint_job_2]
                      stage: lint
                      script: 'echo lint_job'
                      rules:
                        - if: $var == null
                          needs:
                            - lint_job_2
                            - job: lint_job_3
                              optional: true
                    lint_job_2:
                      stage: lint
                      script: 'echo job'
                      rules:
                        - if: $var == null
                    lint_job_3:
                      stage: lint
                      script: 'echo job'
                      rules:
                        - if: $var == null
                EOYML
              end

              it 'returns a valid response' do
                expect(subject).to be_valid
                expect(subject).to be_instance_of(Gitlab::Ci::YamlProcessor::Result)
              end
            end

            context 'needs as array' do
              context 'single need in following stage' do
                let(:config) do
                  <<-EOYML
                      stages:
                        - lint
                        - test
                      lint_job:
                        stage: lint
                        script: 'echo lint_job'
                        rules:
                          - if: $var == null
                            needs: [test_job]
                      test_job:
                        stage: test
                        script: 'echo job'
                        rules:
                          - if: $var == null
                  EOYML
                end

                it_behaves_like 'returns errors', 'lint_job job: need test_job is not defined in current or prior stages'
              end

              context 'multiple needs in the following stage' do
                let(:config) do
                  <<-EOYML
                      stages:
                        - lint
                        - test
                      lint_job:
                        stage: lint
                        script: 'echo lint_job'
                        rules:
                          - if: $var == null
                            needs: [test_job, test_job_2]
                      test_job:
                        stage: test
                        script: 'echo job'
                        rules:
                          - if: $var == null
                      test_job_2:
                        stage: test
                        script: 'echo job'
                        rules:
                          - if: $var == null
                  EOYML
                end

                it_behaves_like 'returns errors', 'lint_job job: need test_job is not defined in current or prior stages'
              end

              context 'single need in following state - hyphen need' do
                let(:config) do
                  <<-EOYML
                      stages:
                        - lint
                        - test
                      lint_job:
                        stage: lint
                        script: 'echo lint_job'
                        rules:
                          - if: $var == null
                            needs:
                              - test_job
                      test_job:
                        stage: test
                        script: 'echo job'
                        rules:
                          - if: $var == null
                  EOYML
                end

                it_behaves_like 'returns errors', 'lint_job job: need test_job is not defined in current or prior stages'
              end

              context 'when there are duplicate needs (string and hash)' do
                let(:config) do
                  <<-EOYML
                      stages:
                        - test
                      test_job_1:
                        stage: test
                        script: 'echo lint_job'
                        rules:
                          - if: $var == null
                            needs:
                              - test_job_2
                              - job: test_job_2
                      test_job_2:
                        stage: test
                        script: 'echo job'
                        rules:
                          - if: $var == null
                  EOYML
                end

                it_behaves_like 'returns errors', 'test_job_1 has the following needs duplicated: test_job_2.'
              end
            end

            context 'rule needs as hash' do
              context 'single hash need in following stage' do
                let(:config) do
                  <<-EOYML
                      stages:
                        - lint
                        - test
                      lint_job:
                        stage: lint
                        script: 'echo lint_job'
                        rules:
                          - if: $var == null
                            needs:
                              - job: test_job
                                artifacts: false
                                optional: false
                      test_job:
                        stage: test
                        script: 'echo job'
                        rules:
                          - if: $var == null
                  EOYML
                end

                it_behaves_like 'returns errors', 'lint_job job: need test_job is not defined in current or prior stages'
              end
            end

            context 'job rule need does not exist' do
              let(:config) do
                <<-EOYML
                  build:
                    stage: build
                    script: echo
                    rules:
                      - when: always
                  test:
                    stage: test
                    script: echo
                    rules:
                      - if: $var == null
                        needs: [unknown_job]
                EOYML
              end

              it_behaves_like 'has warnings and expected error', /test job: undefined need: unknown_job/
            end
          end
        end
      end

      describe 'only / except policies validations' do
        context 'when `only` has an invalid value' do
          let(:config) { { rspec: { script: "rspec", stage: "test", only: only } } }

          subject { described_class.new(YAML.dump(config)).execute }

          context 'when it is integer' do
            let(:only) { 1 }

            it_behaves_like 'returns errors', 'jobs:rspec:only has to be either an array of conditions or a hash'
          end

          context 'when it is an array of integers' do
            let(:only) { [1, 1] }

            it_behaves_like 'returns errors', 'jobs:rspec:only config should be an array of strings or regular expressions using re2 syntax'
          end

          context 'when it is invalid regex' do
            let(:only) { ["/*invalid/"] }

            it_behaves_like 'returns errors', 'jobs:rspec:only config should be an array of strings or regular expressions using re2 syntax'
          end
        end

        context 'when `except` has an invalid value' do
          let(:config) { { rspec: { script: "rspec", except: except } } }

          subject { described_class.new(YAML.dump(config)).execute }

          context 'when it is integer' do
            let(:except) { 1 }

            it_behaves_like 'returns errors', 'jobs:rspec:except has to be either an array of conditions or a hash'
          end

          context 'when it is an array of integers' do
            let(:except) { [1, 1] }

            it_behaves_like 'returns errors', 'jobs:rspec:except config should be an array of strings or regular expressions using re2 syntax'
          end

          context 'when it is invalid regex' do
            let(:except) { ["/*invalid/"] }

            it_behaves_like 'returns errors', 'jobs:rspec:except config should be an array of strings or regular expressions using re2 syntax'
          end
        end
      end

      describe "Scripts handling" do
        let(:config_data) { YAML.dump(config) }
        let(:config_processor) { described_class.new(config_data).execute }

        subject(:test_build) { config_processor.builds.find { |build| build[:name] == 'test' } }

        describe "before_script" do
          context "in global context" do
            using RSpec::Parameterized::TableSyntax

            where(:inherit, :result) do
              nil | ["global script"]
              { default: false } | nil
              { default: true } | ["global script"]
              { default: %w[before_script] } | ["global script"]
              { default: %w[image] } | nil
            end

            with_them do
              let(:config) do
                {
                  before_script: ["global script"],
                  test: { script: ["script"], inherit: inherit }
                }
              end

              it { expect(subject[:options][:before_script]).to eq(result) }
            end

            context "in default context" do
              using RSpec::Parameterized::TableSyntax

              where(:inherit, :result) do
                nil | ["global script"]
                { default: false } | nil
                { default: true } | ["global script"]
                { default: %w[before_script] } | ["global script"]
                { default: %w[image] } | nil
              end

              with_them do
                let(:config) do
                  {
                    default: { before_script: ["global script"] },
                    test: { script: ["script"], inherit: inherit }
                  }
                end

                it { expect(subject[:options][:before_script]).to eq(result) }
              end
            end
          end

          context "overwritten in local context" do
            let(:config) do
              {
                before_script: ["global script"],
                test: { before_script: ["local script"], script: ["script"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:before_script]).to eq(["local script"])
            end
          end

          context 'when script is nested arrays of strings' do
            let(:config) do
              {
                before_script: [[["global script"], "echo 1"], "echo 2", ["ls"], "pwd"],
                test: { script: ["script"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:before_script]).to eq(["global script", "echo 1", "echo 2", "ls", "pwd"])
            end
          end
        end

        describe "script" do
          context 'when script is array of strings' do
            let(:config) do
              {
                test: { script: ["script"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:script]).to eq(["script"])
            end
          end

          context 'when script is nested arrays of strings' do
            let(:config) do
              {
                test: { script: [[["script"], "echo 1", "echo 2"], "ls"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:script]).to eq(["script", "echo 1", "echo 2", "ls"])
            end
          end
        end

        describe "after_script" do
          context "in global context" do
            let(:config) do
              {
                after_script: ["after_script"],
                test: { script: ["script"] }
              }
            end

            it "return after_script in options" do
              expect(subject[:options][:after_script]).to eq(["after_script"])
            end
          end

          context "in default context" do
            let(:config) do
              {
                after_script: ["after_script"],
                test: { script: ["script"] }
              }
            end

            it "return after_script in options" do
              expect(subject[:options][:after_script]).to eq(["after_script"])
            end
          end

          context "overwritten in local context" do
            let(:config) do
              {
                after_script: ["local after_script"],
                test: { after_script: ["local after_script"], script: ["script"] }
              }
            end

            it "return after_script in options" do
              expect(subject[:options][:after_script]).to eq(["local after_script"])
            end
          end

          context 'when script is nested arrays of strings' do
            let(:config) do
              {
                after_script: [[["global script"], "echo 1"], "echo 2", ["ls"], "pwd"],
                test: { script: ["script"] }
              }
            end

            it "return after_script in options" do
              expect(subject[:options][:after_script]).to eq(["global script", "echo 1", "echo 2", "ls", "pwd"])
            end
          end
        end

        describe "hooks" do
          context 'when it is a simple script' do
            let(:config) do
              {
                test: { script: ["script"],
                        hooks: { pre_get_sources_script: ["echo 1", "echo 2", "pwd"] } }
              }
            end

            it "returns hooks in options" do
              expect(subject[:options][:hooks]).to eq(
                { pre_get_sources_script: ["echo 1", "echo 2", "pwd"] }
              )
            end
          end

          context 'when it is nested arrays of strings' do
            let(:config) do
              {
                test: { script: ["script"],
                        hooks: { pre_get_sources_script: [[["global script"], "echo 1"], "echo 2", ["ls"], "pwd"] } }
              }
            end

            it "returns hooks in options" do
              expect(subject[:options][:hooks]).to eq(
                { pre_get_sources_script: ["global script", "echo 1", "echo 2", "ls", "pwd"] }
              )
            end
          end

          context 'when receiving from the default' do
            let(:config) do
              {
                default: { hooks: { pre_get_sources_script: ["echo 1", "echo 2", "pwd"] } },
                test: { script: ["script"] }
              }
            end

            it "inherits hooks" do
              expect(subject[:options][:hooks]).to eq(
                { pre_get_sources_script: ["echo 1", "echo 2", "pwd"] }
              )
            end
          end

          context 'when overriding the default' do
            let(:config) do
              {
                default: { hooks: { pre_get_sources_script: ["echo 1", "echo 2", "pwd"] } },
                test: { script: ["script"],
                        hooks: { pre_get_sources_script: ["echo 3", "echo 4", "pwd"] } }
              }
            end

            it "overrides hooks" do
              expect(subject[:options][:hooks]).to eq(
                { pre_get_sources_script: ["echo 3", "echo 4", "pwd"] }
              )
            end
          end
        end
      end

      describe "Image and service handling" do
        context "when extended docker configuration is used" do
          it "returns image and service when defined" do
            config = YAML.dump({ image: { name: "image:1.0", entrypoint: ["/usr/local/bin/init", "run"] },
                                 services: ["mysql", { name: "docker:dind", alias: "docker",
                                                       entrypoint: ["/usr/local/bin/init", "run"],
                                                       command: ["/usr/local/bin/init", "run"] }],
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec" } })

            config_processor = described_class.new(config).execute
            rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

            expect(rspec_build).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "image:1.0", entrypoint: ["/usr/local/bin/init", "run"] },
                services: [{ name: "mysql" },
                           { name: "docker:dind", alias: "docker", entrypoint: ["/usr/local/bin/init", "run"],
                             command: ["/usr/local/bin/init", "run"] }]
              },
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end

          it "returns image and service when overridden for job" do
            config = YAML.dump({ image: "image:1.0",
                                 services: ["mysql"],
                                 before_script: ["pwd"],
                                 rspec: { image: { name: "image:1.0", entrypoint: ["/usr/local/bin/init", "run"] },
                                          services: [{ name: "postgresql", alias: "db-pg",
                                                       entrypoint: ["/usr/local/bin/init", "run"],
                                                       command: ["/usr/local/bin/init", "run"] }, "docker:dind"],
                                          script: "rspec" } })

            config_processor = described_class.new(config).execute
            rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

            expect(rspec_build).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "image:1.0", entrypoint: ["/usr/local/bin/init", "run"] },
                services: [{ name: "postgresql", alias: "db-pg", entrypoint: ["/usr/local/bin/init", "run"],
                             command: ["/usr/local/bin/init", "run"] },
                           { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end
        end

        context "when etended docker configuration is not used" do
          it "returns image and service when defined" do
            config = YAML.dump({ image: "image:1.0",
                                 services: ["mysql", "docker:dind"],
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec" } })

            config_processor = described_class.new(config).execute
            rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

            expect(rspec_build).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "image:1.0" },
                services: [{ name: "mysql" }, { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end

          it "returns image and service when overridden for job" do
            config = YAML.dump({ image: "image:1.0",
                                 services: ["mysql"],
                                 before_script: ["pwd"],
                                 rspec: { image: "image:1.0", services: ["postgresql", "docker:dind"], script: "rspec" } })

            config_processor = described_class.new(config).execute
            rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

            expect(rspec_build).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "image:1.0" },
                services: [{ name: "postgresql" }, { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end
        end

        context 'when image has pull_policy' do
          let(:config) do
            <<~YAML
            image:
              name: ruby:2.7
              pull_policy: if-not-present

            test:
              script: exit 0
            YAML
          end

          it { is_expected.to be_valid }

          it "returns with image" do
            expect(processor.builds).to contain_exactly({
              stage: "test",
              stage_idx: 2,
              name: "test",
              only: { refs: %w[branches tags] },
              options: {
                script: ["exit 0"],
                image: { name: "ruby:2.7", pull_policy: ["if-not-present"] }
              },
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end
        end

        context 'when a service has pull_policy' do
          let(:config) do
            <<~YAML
            services:
              - name: postgres:11.9
                pull_policy: if-not-present

            test:
              script: exit 0
            YAML
          end

          it { is_expected.to be_valid }

          it "returns with service" do
            expect(processor.builds).to contain_exactly({
              stage: "test",
              stage_idx: 2,
              name: "test",
              only: { refs: %w[branches tags] },
              options: {
                script: ["exit 0"],
                services: [{ name: "postgres:11.9", pull_policy: ["if-not-present"] }]
              },
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end
        end

        context 'when image and service have docker options' do
          let(:config) do
            <<~YAML
            test:
              script: exit 0
              image:
                name: ruby:2.7
                docker:
                  platform: linux/amd64
                  user: dave
              services:
                - name: postgres:11.9
                  docker:
                    platform: linux/amd64
                    user: john
            YAML
          end

          it { is_expected.to be_valid }

          it "returns with image" do
            expect(processor.builds).to contain_exactly({
              stage: "test",
              stage_idx: 2,
              name: "test",
              only: { refs: %w[branches tags] },
              options: {
                script: ["exit 0"],
                image: { name: "ruby:2.7",
                         executor_opts: { docker: { platform: 'linux/amd64', user: 'dave' } } },
                services: [{ name: "postgres:11.9",
                             executor_opts: { docker: { platform: 'linux/amd64', user: 'john' } } }]
              },
              allow_failure: false,
              when: "on_success",
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end
        end
      end

      describe 'Variables' do
        subject(:execute) { described_class.new(config).execute }

        let(:build) { execute.builds.first }
        let(:job_variables) { build[:job_variables] }
        let(:root_variables) { execute.root_variables }
        let(:root_variables_inheritance) { build[:root_variables_inheritance] }

        context 'when global variables are defined' do
          let(:config) do
            <<~YAML
            variables:
              VAR1: value1
              VAR2: value2

            before_script: [pwd]

            rspec:
              script: rspec
            YAML
          end

          it 'returns global variables' do
            expect(job_variables).to eq([])
            expect(root_variables_inheritance).to eq(true)
          end
        end

        context 'when job variables are defined' do
          context 'when syntax is correct' do
            let(:config) do
              <<~YAML
              before_script: [pwd]

              rspec:
                script: rspec
                variables:
                  VAR1: value1
                  VAR2: value2
              YAML
            end

            it 'returns job variables' do
              expect(job_variables).to contain_exactly(
                { key: 'VAR1', value: 'value1' },
                { key: 'VAR2', value: 'value2' }
              )
              expect(root_variables_inheritance).to eq(true)
            end
          end

          context 'when syntax is incorrect' do
            context 'when variables defined but invalid' do
              let(:config) do
                <<~YAML
                before_script: [pwd]

                rspec:
                  script: rspec
                  variables: [VAR1 value1 VAR2 value2]
                YAML
              end

              it_behaves_like 'returns errors', /jobs:rspec:variables config should be a hash/
            end

            context 'when variables key defined but value not specified' do
              let(:config) do
                <<~YAML
                before_script: [pwd]

                rspec:
                  script: rspec
                  variables: null
                YAML
              end

              it 'returns empty array' do
                ##
                # When variables config is empty, we assume this is a valid
                # configuration, see issue #18775
                #
                expect(job_variables).to eq([])
                expect(root_variables_inheritance).to eq(true)
              end
            end
          end
        end

        context 'when job variables are not defined' do
          let(:config) do
            <<~YAML
            before_script: ['pwd']

            rspec:
              script: rspec
            YAML
          end

          it 'returns empty array' do
            expect(job_variables).to eq([])
            expect(root_variables_inheritance).to eq(true)
          end
        end

        context 'when variables have different type of values' do
          let(:config) do
            <<~YAML
            before_script: [pwd]

            rspec:
              variables:
                VAR1: value1
                VAR2: :value2
                VAR3: 123
              script: rspec
            YAML
          end

          it 'returns job variables' do
            expect(job_variables).to contain_exactly(
              { key: 'VAR1', value: 'value1' },
              { key: 'VAR2', value: 'value2' },
              { key: 'VAR3', value: '123' }
            )
            expect(root_variables_inheritance).to eq(true)
          end
        end

        context 'when variables have data other than value' do
          let(:config) do
            <<~YAML
            variables:
              VAR1: value1
              VAR2:
                value: value2
                description: description2
              VAR3:
                value: value3
                expand: false

            rspec:
              script: rspec
              variables:
                VAR4: value4
                VAR5:
                  value: value5
                  expand: false
                VAR6:
                  value: value6
                  expand: true
            YAML
          end

          it 'returns variables' do
            expect(job_variables).to contain_exactly(
              { key: 'VAR4', value: 'value4' },
              { key: 'VAR5', value: 'value5', raw: true },
              { key: 'VAR6', value: 'value6', raw: false }
            )

            expect(execute.root_variables).to contain_exactly(
              { key: 'VAR1', value: 'value1' },
              { key: 'VAR2', value: 'value2' },
              { key: 'VAR3', value: 'value3', raw: true }
            )

            expect(execute.root_variables_with_prefill_data).to eq(
              'VAR1' => { value: 'value1' },
              'VAR2' => { value: 'value2', description: 'description2' },
              'VAR3' => { value: 'value3', raw: true }
            )
          end
        end
      end

      context 'when using `extends`' do
        let(:config_processor) { described_class.new(config).execute }

        subject { config_processor.builds.first }

        context 'when using simple `extends`' do
          let(:config) do
            <<~YAML
              .template:
                script: test

              rspec:
                extends: .template
                image: ruby:alpine
            YAML
          end

          it 'correctly extends rspec job' do
            expect(config_processor.builds).to be_one
            expect(subject.dig(:options, :script)).to eq %w[test]
            expect(subject.dig(:options, :image, :name)).to eq 'ruby:alpine'
          end
        end

        context 'when overriding `extends`' do
          let(:config) do
            <<~YAML
              .base:
                script: test
                variables:
                  VAR1: base var 1

              test1:
                extends: .base
                variables:
                  VAR1: test1 var 1
                  VAR2: test2 var 2

              test2:
                extends: .base
                variables:
                  VAR2: test2 var 2

              test3:
                extends: .base
                variables: {}

              test4:
                extends: .base
                variables: null
            YAML
          end

          it 'correctly extends jobs' do
            expect(config_processor.builds[0]).to include(
              name: 'test1',
              options: { script: ['test'] },
              job_variables: [{ key: 'VAR1', value: 'test1 var 1' },
                              { key: 'VAR2', value: 'test2 var 2' }]
            )

            expect(config_processor.builds[1]).to include(
              name: 'test2',
              options: { script: ['test'] },
              job_variables: [{ key: 'VAR1', value: 'base var 1' },
                              { key: 'VAR2', value: 'test2 var 2' }]
            )

            expect(config_processor.builds[2]).to include(
              name: 'test3',
              options: { script: ['test'] },
              job_variables: [{ key: 'VAR1', value: 'base var 1' }]
            )

            expect(config_processor.builds[3]).to include(
              name: 'test4',
              options: { script: ['test'] },
              job_variables: []
            )
          end
        end

        context 'when using recursive `extends`' do
          let(:config) do
            <<~YAML
              rspec:
                extends: .test
                script: rspec
                when: always

              .template:
                before_script:
                  - bundle install

              .test:
                extends: .template
                script: test
                image: image:test
            YAML
          end

          it 'correctly extends rspec job' do
            expect(config_processor.builds).to be_one
            expect(subject.dig(:options, :before_script)).to eq ["bundle install"]
            expect(subject.dig(:options, :script)).to eq %w[rspec]
            expect(subject.dig(:options, :image, :name)).to eq 'image:test'
            expect(subject[:when]).to eq 'always'
          end
        end
      end

      describe "Include" do
        let(:opts) { {} }

        let(:config) do
          {
            include: include_content,
            rspec: { script: "test" }
          }
        end

        subject { described_class.new(YAML.dump(config), opts).execute }

        context "when validating a ci config file with no project context" do
          context "when a single string is provided" do
            let(:include_content) { "/local.gitlab-ci.yml" }

            it_behaves_like 'returns errors', /does not have project/
          end

          context "when an array is provided" do
            let(:include_content) { ["/local.gitlab-ci.yml"] }

            it_behaves_like 'returns errors', /does not have project/
          end

          context "when an array of wrong keyed object is provided" do
            let(:include_content) { [{ yolo: "/local.gitlab-ci.yml" }] }

            it_behaves_like 'returns errors', /does not have a valid subkey for include/
          end

          context "when an array of mixed typed objects is provided" do
            let(:include_content) do
              [
                'https://gitlab.com/awesome-project/raw/master/.before-script-template.yml',
                { template: 'Auto-DevOps.gitlab-ci.yml' }
              ]
            end

            before do
              stub_full_request('https://gitlab.com/awesome-project/raw/master/.before-script-template.yml')
                .to_return(
                  status: 200,
                  headers: { 'Content-Type' => 'application/json' },
                  body: 'prepare: { script: ls -al }')
            end

            it { is_expected.to be_valid }
          end

          context "when the include type is incorrect" do
            let(:include_content) { { name: "/local.gitlab-ci.yml" } }

            it_behaves_like 'returns errors', /does not have a valid subkey for include/
          end
        end

        context "when validating a ci config file within a project" do
          let(:include_content) { "/local.gitlab-ci.yml" }
          let(:project) { create(:project, :repository) }
          let(:opts) { { project: project, sha: project.commit.sha } }

          context "when the included internal file is present" do
            let(:project_files) do
              {
                'local.gitlab-ci.yml' => <<~YAML
                job1:
                  script: hello
                YAML
              }
            end

            around do |example|
              create_and_delete_files(project, project_files) do
                example.run
              end
            end

            it { is_expected.to be_valid }

            it 'adds the job from the included file' do
              expect(subject.builds.map { |build| build[:name] }).to contain_exactly('job1', 'rspec')
            end
          end

          context "when the included internal file is not present" do
            it_behaves_like 'returns errors', "Local file `local.gitlab-ci.yml` does not exist!"
          end
        end
      end

      describe 'when:' do
        (Gitlab::Ci::Config::Entry::Job::ALLOWED_WHEN - %w[delayed]).each do |when_state|
          it "#{when_state} creates one build and sets when:" do
            config = YAML.dump({
              rspec: { script: 'rspec', when: when_state }
            })

            config_processor = Gitlab::Ci::YamlProcessor.new(config).execute
            builds = config_processor.builds

            expect(builds.size).to eq(1)
            expect(builds.first[:when]).to eq(when_state)
          end
        end

        context 'delayed' do
          context 'with start_in' do
            let(:config) do
              YAML.dump({
                rspec: { script: 'rspec', when: 'delayed', start_in: '1 hour' }
              })
            end

            it 'creates one build and sets when:' do
              builds = processor.builds

              expect(builds.size).to eq(1)
              expect(builds.first[:when]).to eq('delayed')
              expect(builds.first[:options][:start_in]).to eq('1 hour')
            end
          end

          context 'without start_in' do
            let(:config) do
              YAML.dump({
                rspec: { script: 'rspec', when: 'delayed' }
              })
            end

            it_behaves_like 'returns errors', /start in should be a duration/
          end
        end
      end

      describe 'Parallel' do
        let(:config) do
          YAML.dump(rspec: { script: 'rspec',
                             parallel: parallel,
                             variables: { 'VAR1' => 1 } })
        end

        let(:config_processor) { described_class.new(config).execute }
        let(:builds) { config_processor.builds }

        context 'when job is parallelized' do
          let(:parallel) { 5 }

          it 'returns parallelized jobs' do
            build_options = builds.map { |build| build[:options] }

            expect(builds.size).to eq(5)
            expect(build_options).to all(include(:instance, parallel: { number: parallel, total: parallel }))
          end

          it 'does not have the original job' do
            expect(builds).not_to include(:rspec)
          end
        end

        context 'with build matrix' do
          let(:parallel) do
            {
              matrix: [
                { 'PROVIDER' => 'aws', 'STACK' => %w[monitoring app1 app2] },
                { 'PROVIDER' => 'ovh', 'STACK' => %w[monitoring backup app] },
                { 'PROVIDER' => 'gcp', 'STACK' => %w[data processing] }
              ]
            }
          end

          it 'returns the number of parallelized jobs' do
            expect(builds.size).to eq(8)
          end

          it 'returns the parallel config' do
            build_options = builds.map { |build| build[:options] }
            parallel_config = {
              matrix: parallel[:matrix].map { |var| var.transform_values { |v| Array(v).flatten } },
              total: build_options.size
            }

            expect(build_options).to all(include(:instance, parallel: parallel_config))
          end

          it 'sets matrix variables' do
            build_variables = builds.map { |build| build[:job_variables] }
            expected_variables = [
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'aws' },
                { key: 'STACK', value: 'monitoring' }
              ],
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'aws' },
                { key: 'STACK', value: 'app1' }
              ],
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'aws' },
                { key: 'STACK', value: 'app2' }
              ],
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'ovh' },
                { key: 'STACK', value: 'monitoring' }
              ],
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'ovh' },
                { key: 'STACK', value: 'backup' }
              ],
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'ovh' },
                { key: 'STACK', value: 'app' }
              ],
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'gcp' },
                { key: 'STACK', value: 'data' }
              ],
              [
                { key: 'VAR1', value: '1' },
                { key: 'PROVIDER', value: 'gcp' },
                { key: 'STACK', value: 'processing' }
              ]
            ].map { |vars| vars.map { |var| a_hash_including(var) } }

            expect(build_variables).to match(expected_variables)
          end

          it 'does not have the original job' do
            expect(builds).not_to include(:rspec)
          end
        end
      end

      describe 'cache' do
        context 'when cache definition has unknown keys' do
          let(:config) do
            YAML.dump(
              { cache: { untracked: true, invalid: 'key' },
                rspec: { script: 'rspec' } })
          end

          it_behaves_like 'returns errors', 'cache config contains unknown keys: invalid'
        end

        it "returns cache when defined globally" do
          config = YAML.dump({
                              cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'key' },
                              rspec: {
                                script: "rspec"
                              }
                            })

          config_processor = described_class.new(config).execute
          rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

          expect(rspec_build[:cache]).to eq(
            [
              paths: ["logs/", "binaries/"],
              untracked: true,
              key: 'key',
              policy: 'pull-push',
              when: 'on_success',
              unprotect: false,
              fallback_keys: []
            ])
        end

        it "returns cache when defined in default context" do
          config = YAML.dump(
            {
              default: {
                cache: { paths: ["logs/", "binaries/"], untracked: true, key: { files: ['file'] } }
              },
              rspec: {
                script: "rspec"
              }
            })

          config_processor = described_class.new(config).execute
          rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

          expect(rspec_build[:cache]).to eq(
            [
              paths: ["logs/", "binaries/"],
              untracked: true,
              key: { files: ['file'] },
              policy: 'pull-push',
              when: 'on_success',
              unprotect: false,
              fallback_keys: []
            ])
        end

        it 'returns cache key/s when defined in a job' do
          config = YAML.dump(
            {
              rspec: {
                cache: [
                  { paths: ['binaries/'], untracked: true, key: 'keya' },
                  { paths: ['logs/', 'binaries/'], untracked: true, key: 'key' }
                ],
                script: 'rspec'
              }
            })

          config_processor = described_class.new(config).execute
          rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

          expect(rspec_build[:cache]).to eq(
            [
              {
                paths: ['binaries/'],
                untracked: true,
                key: 'keya',
                policy: 'pull-push',
                when: 'on_success',
                unprotect: false,
                fallback_keys: []
              },
              {
                paths: ['logs/', 'binaries/'],
                untracked: true,
                key: 'key',
                policy: 'pull-push',
                when: 'on_success',
                unprotect: false,
                fallback_keys: []
              }
            ]
          )
        end

        it 'returns cache files' do
          config = YAML.dump(
            rspec: {
              cache: {
                  paths: ['binaries/'],
                  untracked: true,
                  key: { files: ['file'] }
                },
              script: 'rspec'
            }
          )

          config_processor = described_class.new(config).execute
          rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

          expect(rspec_build[:cache]).to eq(
            [
              paths: ['binaries/'],
              untracked: true,
              key: { files: ['file'] },
              policy: 'pull-push',
              when: 'on_success',
              unprotect: false,
              fallback_keys: []
            ])
        end

        it 'returns cache files with prefix' do
          config = YAML.dump(
            rspec: {
              cache: {
                paths: ['logs/', 'binaries/'],
                untracked: true,
                key: { files: ['file'], prefix: 'prefix' }
              },
              script: 'rspec'
            }
          )

          config_processor = described_class.new(config).execute
          rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

          expect(rspec_build[:cache]).to eq(
            [
              paths: ['logs/', 'binaries/'],
              untracked: true,
              key: { files: ['file'], prefix: 'prefix' },
              policy: 'pull-push',
              when: 'on_success',
              unprotect: false,
              fallback_keys: []
            ])
        end

        it "overwrite cache when defined for a job and globally" do
          config = YAML.dump(
            {
              cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'global' },
              rspec: {
                script: "rspec",
                cache: { paths: ["test/"], untracked: false, key: 'local' }
              }
            })

          config_processor = described_class.new(config).execute
          rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

          expect(rspec_build[:cache]).to eq(
            [
              paths: ["test/"],
              untracked: false,
              key: 'local',
              policy: 'pull-push',
              when: 'on_success',
              unprotect: false,
              fallback_keys: []
            ])
        end
      end

      describe 'id_tokens' do
        subject(:execute) { described_class.new(config).execute }

        let(:build) { execute.builds.first }
        let(:id_tokens_vars) { { ID_TOKEN_1: { aud: 'http://gcp.com' } } }
        let(:job_id_tokens_vars) { { ID_TOKEN_2: { aud: 'http://job.com' } } }

        context 'when defined on job level' do
          let(:config) do
            YAML.dump({
              rspec: { script: 'rspec', id_tokens: id_tokens_vars }
            })
          end

          it 'returns defined id_tokens' do
            expect(build[:id_tokens]).to eq(id_tokens_vars)
          end
        end

        context 'when defined as default' do
          let(:config) do
            YAML.dump({
              default: { id_tokens: id_tokens_vars },
              rspec: { script: 'rspec' }
            })
          end

          it 'returns inherited by default id_tokens' do
            expect(build[:id_tokens]).to eq(id_tokens_vars)
          end
        end

        context 'when defined as default and on job level' do
          let(:config) do
            YAML.dump({
              default: { id_tokens: id_tokens_vars },
              rspec: { script: 'rspec', id_tokens: job_id_tokens_vars }
            })
          end

          it 'overrides default and returns defined on job level' do
            expect(build[:id_tokens]).to eq(job_id_tokens_vars)
          end
        end
      end

      describe "Artifacts" do
        it "returns artifacts when defined" do
          config = YAML.dump(
            {
              image: "image:1.0",
              services: ["mysql"],
              before_script: ["pwd"],
              rspec: {
                artifacts: {
                  paths: ["logs/", "binaries/"],
                  expose_as: "Exposed artifacts",
                  untracked: true,
                  name: "custom_name",
                  expire_in: "7d"
                },
                script: "rspec"
              }
            })

          config_processor = described_class.new(config).execute
          rspec_build = config_processor.builds.find { |build| build[:name] == 'rspec' }

          expect(rspec_build).to eq({
            stage: "test",
            stage_idx: 2,
            name: "rspec",
            only: { refs: %w[branches tags] },
            options: {
              before_script: ["pwd"],
              script: ["rspec"],
              image: { name: "image:1.0" },
              services: [{ name: "mysql" }],
              artifacts: {
                name: "custom_name",
                paths: ["logs/", "binaries/"],
                expose_as: "Exposed artifacts",
                untracked: true,
                expire_in: "7d"
              }
            },
            when: "on_success",
            allow_failure: false,
            job_variables: [],
            root_variables_inheritance: true,
            scheduling_type: :stage
          })
        end

        it "returns artifacts with expire_in never keyword" do
          config = YAML.dump({
                                rspec: {
                                  script: "rspec",
                                  artifacts: { paths: ["releases/"], expire_in: "never" }
                                }
                              })

          config_processor = described_class.new(config).execute
          builds = config_processor.builds

          expect(builds.size).to eq(1)
          expect(builds.first[:options][:artifacts][:expire_in]).to eq('never')
        end

        %w[on_success on_failure always].each do |when_state|
          it "returns artifacts for when #{when_state}  defined" do
            config = YAML.dump({
                                 rspec: {
                                   script: "rspec",
                                   artifacts: { paths: ["logs/", "binaries/"], when: when_state }
                                 }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config).execute
            builds = config_processor.builds

            expect(builds.size).to eq(1)
            expect(builds.first[:options][:artifacts][:when]).to eq(when_state)
          end
        end

        context 'when artifacts syntax is wrong' do
          let(:config) do
            <<~YAML
            test:
              script:
                - echo "Hello world"
              artifacts:
                - paths:
                - test/
            YAML
          end

          it_behaves_like 'returns errors', 'jobs:test:artifacts config should be a hash'
        end

        it 'populates a build options with complete artifacts configuration' do
          config = <<~YAML
            test:
              script: echo "Hello World"
              artifacts:
                paths:
                  - my/test
                exclude:
                  - my/test/something
          YAML

          attributes = Gitlab::Ci::YamlProcessor.new(config).execute.builds.find { |build| build[:name] == 'test' }

          expect(attributes.dig(*%i[options artifacts exclude])).to eq(%w[my/test/something])
        end
      end

      describe "release" do
        let(:processor) { described_class.new(YAML.dump(config)).execute }
        let(:config) do
          {
            stages: %w[build test release],
            release: {
              stage: "release",
              only: ["tags"],
              script: ["make changelog | tee release_changelog.txt"],
              release: {
                tag_name: "$CI_COMMIT_TAG",
                tag_message: "Annotated tag message",
                name: "Release $CI_TAG_NAME",
                description: "./release_changelog.txt",
                ref: 'b3235930aa443112e639f941c69c578912189bdd',
                released_at: '2019-03-15T08:00:00Z',
                milestones: %w[m1 m2 m3],
                assets: {
                  links: [
                    {
                      name: "cool-app.zip",
                      url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip"
                    },
                    {
                      name: "cool-app.exe",
                      url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.exe"
                    }
                  ]
                }
              }
            }
          }
        end

        it "returns release info" do
          expect(processor.builds.first[:options])
            .to eq(config[:release].except(:stage, :only))
        end
      end

      describe '#environment' do
        let(:config) do
          {
            deploy_to_production: { stage: 'deploy', script: 'test', environment: environment }
          }
        end

        subject { described_class.new(YAML.dump(config)).execute }

        let(:builds) { subject.builds }

        context 'when a production environment is specified' do
          let(:environment) { 'production' }

          it 'does return production' do
            expect(builds.size).to eq(1)
            expect(builds.first[:environment]).to eq(environment)
            expect(builds.first[:options]).to include(environment: { name: environment, action: "start" })
          end
        end

        context 'when hash is specified' do
          let(:environment) do
            { name: 'production',
              url: 'http://production.gitlab.com' }
          end

          it 'does return production and URL' do
            expect(builds.size).to eq(1)
            expect(builds.first[:environment]).to eq(environment[:name])
            expect(builds.first[:options]).to include(environment: environment)
          end

          context 'the url has a port as variable' do
            let(:environment) do
              { name: 'production',
                url: 'http://production.gitlab.com:$PORT' }
            end

            it 'allows a variable for the port' do
              expect(builds.size).to eq(1)
              expect(builds.first[:environment]).to eq(environment[:name])
              expect(builds.first[:options]).to include(environment: environment)
            end
          end
        end

        context 'when no environment is specified' do
          let(:environment) { nil }

          it 'does return nil environment' do
            expect(builds.size).to eq(1)
            expect(builds.first[:environment]).to be_nil
          end
        end

        context 'is not a string' do
          let(:environment) { 1 }

          it_behaves_like 'returns errors', 'jobs:deploy_to_production:environment config should be a hash or a string'
        end

        context 'is not a valid string' do
          let(:environment) { 'production:staging' }

          it_behaves_like 'returns errors', "jobs:deploy_to_production:environment name #{Gitlab::Regex.environment_name_regex_message}"
        end

        context 'when on_stop is specified' do
          let(:review) { { stage: 'deploy', script: 'test', environment: { name: 'review', on_stop: 'close_review' } } }
          let(:config) { { review: review, close_review: close_review }.compact }

          context 'with matching job' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: { name: 'review', action: 'stop' } } }

            it 'does return a list of builds' do
              expect(builds.size).to eq(2)
              expect(builds.first[:environment]).to eq('review')
            end
          end

          context 'without matching job' do
            let(:close_review) { nil }

            it_behaves_like 'returns errors', 'review job: on_stop job close_review is not defined'
          end

          context 'with close job without environment' do
            let(:close_review) { { stage: 'deploy', script: 'test' } }

            it_behaves_like 'returns errors', 'review job: on_stop job close_review does not have environment defined'
          end

          context 'with close job for different environment' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: 'production' } }

            it_behaves_like 'returns errors', 'review job: on_stop job close_review have different environment name'
          end

          context 'with close job without stop action' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: { name: 'review' } } }

            it_behaves_like 'returns errors', 'review job: on_stop job close_review needs to have action stop defined'
          end
        end
      end

      describe "Timeout" do
        let(:config) do
          {
            deploy_to_production: {
              stage: 'deploy',
              script: 'test'
            }
          }
        end

        subject { described_class.new(YAML.dump(config)).execute }

        let(:builds) { subject.builds }

        context 'when no timeout was provided' do
          it 'does not include job_timeout' do
            expect(builds.size).to eq(1)
            expect(builds.first[:options]).not_to include(:job_timeout)
          end
        end

        context 'when an invalid timeout was provided' do
          before do
            config[:deploy_to_production][:timeout] = 'not-a-number'
          end

          it_behaves_like 'returns errors', 'jobs:deploy_to_production:timeout config should be a duration'
        end

        context 'when some valid timeout was provided' do
          before do
            config[:deploy_to_production][:timeout] = '1m 3s'
          end

          it 'returns provided timeout value' do
            expect(builds.size).to eq(1)
            expect(builds.first[:options]).to include(job_timeout: 63)
          end
        end
      end

      describe "Dependencies" do
        let(:config) do
          {
            build1: { stage: 'build', script: 'test' },
            build2: { stage: 'build', script: 'test' },
            test1: { stage: 'test', script: 'test', dependencies: dependencies },
            test2: { stage: 'test', script: 'test' },
            deploy: { stage: 'deploy', script: 'test' }
          }
        end

        subject { described_class.new(YAML.dump(config)).execute }

        context 'no dependencies' do
          let(:dependencies) {}

          it { is_expected.to be_valid }
        end

        context 'dependencies to builds' do
          let(:dependencies) { %w[build1 build2] }

          it { is_expected.to be_valid }
        end

        context 'dependencies to builds defined as symbols' do
          let(:dependencies) { [:build1, :build2] }

          it { is_expected.to be_valid }
        end

        context 'undefined dependency' do
          let(:dependencies) { ['undefined'] }

          it_behaves_like 'returns errors', 'test1 job: undefined dependency: undefined'
        end

        context 'dependencies to deploy' do
          let(:dependencies) { ['deploy'] }

          it_behaves_like 'returns errors', 'test1 job: dependency deploy is not defined in current or prior stages'
        end

        context 'when a job depends on another job that references a not-yet defined stage' do
          let(:config) do
            {
              "stages" => [
                "version"
              ],
              "version" => {
                "stage" => "version",
                "dependencies" => ["release:components:versioning"],
                "script" => ["./versioning/versioning"]
              },
              ".release_go" => {
                "stage" => "build",
                "script" => ["cd versioning"]
              },
              "release:components:versioning" => {
                "stage" => "build",
                "script" => ["cd versioning"]
              }
            }
          end

          it_behaves_like 'returns errors', /is not defined in current or prior stages/
        end
      end

      describe "Job Needs" do
        let(:needs) {}
        let(:dependencies) {}

        let(:config) do
          {
            build1: { stage: 'build', script: 'test' },
            build2: { stage: 'build', script: 'test' },
            parallel: { stage: 'build', script: 'test', parallel: 2 },
            test1: { stage: 'test', script: 'test', needs: needs, dependencies: dependencies },
            test2: { stage: 'test', script: 'test' },
            deploy: { stage: 'deploy', script: 'test' }
          }
        end

        subject { described_class.new(YAML.dump(config)).execute }

        context 'no needs' do
          it { is_expected.to be_valid }
        end

        context 'needs a job from the same stage' do
          let(:needs) { %w[test2] }

          it 'creates jobs with valid specifications' do
            expect(subject.builds.size).to eq(7)
            expect(subject.builds[0]).to eq(
              stage: 'build',
              stage_idx: 1,
              name: 'build1',
              only: { refs: %w[branches tags] },
              options: {
                script: ['test']
              },
              when: 'on_success',
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            )
            expect(subject.builds[4]).to eq(
              stage: 'test',
              stage_idx: 2,
              name: 'test1',
              only: { refs: %w[branches tags] },
              options: { script: ['test'] },
              needs_attributes: [
                { name: 'test2', artifacts: true, optional: false }
              ],
              when: 'on_success',
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :dag
            )
          end
        end

        context 'needs two builds' do
          let(:needs) { %w[build1 build2] }

          it "does create jobs with valid specification" do
            expect(subject.builds.size).to eq(7)
            expect(subject.builds[0]).to eq(
              stage: "build",
              stage_idx: 1,
              name: "build1",
              only: { refs: %w[branches tags] },
              options: {
                script: ["test"]
              },
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            )
            expect(subject.builds[4]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "build1", artifacts: true, optional: false },
                { name: "build2", artifacts: true, optional: false }
              ],
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :dag
            )
          end
        end

        context 'needs two builds' do
          let(:needs) do
            [
              { job: 'parallel', artifacts: false },
              { job: 'build1',   artifacts: true, optional: true },
              'build2'
            ]
          end

          it "does create jobs with valid specification" do
            expect(subject.builds.size).to eq(7)
            expect(subject.builds[0]).to eq(
              stage: "build",
              stage_idx: 1,
              name: "build1",
              only: { refs: %w[branches tags] },
              options: {
                script: ["test"]
              },
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            )
            expect(subject.builds[4]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "parallel 1/2", artifacts: false, optional: false },
                { name: "parallel 2/2", artifacts: false, optional: false },
                { name: "build1", artifacts: true, optional: true },
                { name: "build2", artifacts: true, optional: false }
              ],
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :dag
            )
          end
        end

        context 'needs parallel job' do
          let(:needs) { %w[parallel] }

          it "does create jobs with valid specification" do
            expect(subject.builds.size).to eq(7)
            expect(subject.builds[4]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "parallel 1/2", artifacts: true, optional: false },
                { name: "parallel 2/2", artifacts: true, optional: false }
              ],
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :dag
            )
          end

          context 'when expanded job name is too long' do
            let(:parallel_job_name) { 'a' * ::Ci::BuildNeed::MAX_JOB_NAME_LENGTH }
            let(:needs) { [parallel_job_name] }

            before do
              config[parallel_job_name] = { stage: 'build', script: 'test', parallel: 1 }
            end

            it 'returns an error' do
              expect(subject.errors).to include(
                "test1 job: need `#{parallel_job_name} 1/1` name is too long (maximum is #{::Ci::BuildNeed::MAX_JOB_NAME_LENGTH} characters)"
              )
            end
          end

          context 'when parallel job has matrix specified' do
            let(:var1) { '1' }
            let(:var2) { '2' }

            before do
              config[:parallel] = { stage: 'build', script: 'test', parallel: { matrix: [{ VAR1: var1, VAR2: var2 }] } }
            end

            it 'does create jobs with valid specification' do
              expect(subject.builds.size).to eq(6)
              expect(subject.builds[3]).to eq(
                stage: 'test',
                stage_idx: 2,
                name: 'test1',
                only: { refs: %w[branches tags] },
                options: { script: ['test'] },
                needs_attributes: [
                  { name: 'parallel: [1, 2]', artifacts: true, optional: false }
                ],
                when: "on_success",
                allow_failure: false,
                job_variables: [],
                root_variables_inheritance: true,
                scheduling_type: :dag
              )
            end

            context 'when expanded job name is too long' do
              let(:var1) { '1' * (::Ci::BuildNeed::MAX_JOB_NAME_LENGTH / 2) }
              let(:var2) { '2' * (::Ci::BuildNeed::MAX_JOB_NAME_LENGTH / 2) }

              it 'returns an error' do
                expect(subject.errors).to include(
                  "test1 job: need `parallel: [#{var1}, #{var2}]` name is too long (maximum is #{::Ci::BuildNeed::MAX_JOB_NAME_LENGTH} characters)"
                )
              end
            end
          end
        end

        context 'needs dependencies artifacts' do
          let(:needs) do
            [
              "build1",
              { job: "build2" },
              { job: "parallel", artifacts: true }
            ]
          end

          it "does create jobs with valid specification" do
            expect(subject.builds.size).to eq(7)
            expect(subject.builds[4]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "build1", artifacts: true, optional: false },
                { name: "build2", artifacts: true, optional: false },
                { name: "parallel 1/2", artifacts: true, optional: false },
                { name: "parallel 2/2", artifacts: true, optional: false }
              ],
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :dag
            )
          end
        end

        context 'when need is an undefined job' do
          let(:needs) { ['undefined'] }

          it_behaves_like 'returns errors', 'test1 job: undefined need: undefined'

          context 'when need is optional' do
            let(:needs) { [{ job: 'undefined', optional: true }] }

            it { is_expected.to be_valid }
          end
        end

        context 'needs to deploy' do
          let(:needs) { ['deploy'] }

          it_behaves_like 'returns errors', 'test1 job: need deploy is not defined in current or prior stages'
        end

        context 'duplicate needs' do
          context 'when needs are specified in an array' do
            let(:needs) { %w[build1 build1] }

            it_behaves_like 'returns errors', 'test1 has the following needs duplicated: build1.'
          end

          context 'when a job is specified multiple times' do
            let(:needs) do
              [
                { job: "build2", artifacts: true, optional: false },
                { job: "build2", artifacts: true, optional: false }
              ]
            end

            it_behaves_like 'returns errors', 'test1 has the following needs duplicated: build2.'
          end

          context 'when job is specified multiple times with different attributes' do
            let(:needs) do
              [
                { job: "build2", artifacts: false, optional: true },
                { job: "build2", artifacts: true, optional: false }
              ]
            end

            it_behaves_like 'returns errors', 'test1 has the following needs duplicated: build2.'
          end
        end

        context 'needs and dependencies that are mismatching' do
          let(:needs) { %w[build1] }
          let(:dependencies) { %w[build2] }

          it_behaves_like 'returns errors', 'jobs:test1 dependencies the build2 should be part of needs'
        end

        context 'needs with a Hash type and dependencies with a string type that are mismatching' do
          let(:needs) do
            [
              "build1",
              { job: "build2" }
            ]
          end

          let(:dependencies) { %w[build3] }

          it_behaves_like 'returns errors', 'jobs:test1 dependencies the build3 should be part of needs'
        end

        context 'needs with an array type and dependency with a string type' do
          let(:needs) { %w[build1] }
          let(:dependencies) { 'deploy' }

          it_behaves_like 'returns errors', 'jobs:test1 dependencies should be an array of strings'
        end

        context 'needs with a string type and dependency with an array type' do
          let(:needs) { 'build1' }
          let(:dependencies) { %w[deploy] }

          it_behaves_like 'returns errors', 'jobs:test1:needs config can only be a hash or an array'
        end

        context 'needs with a Hash type and dependency with a string type' do
          let(:needs) { { job: 'build1' } }
          let(:dependencies) { 'deploy' }

          it_behaves_like 'returns errors', 'jobs:test1 dependencies should be an array of strings'
        end

        context 'needs with parallel:matrix' do
          let(:config) do
            {
              build1: {
                stage: 'build',
                script: 'build',
                parallel: { matrix: [{ PROVIDER: ['aws'], STACK: %w[monitoring app1 app2] }] }
              },
              test1: {
                stage: 'test',
                script: 'test',
                needs: [{ job: 'build1', parallel: { matrix: [{ PROVIDER: ['aws'], STACK: ['app1'] }] } }]
              }
            }
          end

          it "does create jobs with valid specification" do
            expect(subject.builds.size).to eq(4)
            expect(subject.builds[3]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "build1: [aws, app1]", artifacts: true, optional: false }
              ],
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :dag
            )
          end
        end
      end

      context 'with when/rules' do
        subject { described_class.new(YAML.dump(config)).execute }

        let(:config) do
          {
            var_default: { stage: 'build', script: 'test', rules: [{ if: '$VAR == null' }] },
            var_when: { stage: 'build', script: 'test', rules: [{ if: '$VAR == null', when: 'always' }] },
            var_and_changes: { stage: 'build',  script: 'test', rules: [{ if: '$VAR == null', changes: %w[README], when: 'always' }] },
            changes_not_var: { stage: 'test',   script: 'test', rules: [{ if: '$VAR != null', changes: %w[README] }] },
            var_not_changes: { stage: 'test',   script: 'test', rules: [{ if: '$VAR == null', changes: %w[other/file.rb], when: 'always' }] },
            nothing: { stage: 'test', script: 'test', rules: [{ when: 'manual' }] },
            var_never: { stage: 'deploy', script: 'test', rules: [{ if: '$VAR == null', when: 'never' }] },
            var_delayed: { stage: 'deploy', script: 'test', rules: [{ if: '$VAR == null', when: 'delayed', start_in: '3 hours' }] },
            two_rules: { stage: 'deploy', script: 'test', rules: [{ if: '$VAR == null', when: 'on_success' }, { changes: %w[README], when: 'manual' }] }
          }
        end

        it { is_expected.to be_valid }

        it 'returns all jobs regardless of their inclusion' do
          expect(subject.builds.count).to eq(config.keys.count)
        end

        context 'used with job-level when' do
          let(:config) do
            {
              var_default: {
                stage: 'build',
                script: 'test',
                when: 'always',
                rules: [{ if: '$VAR == null' }]
              }
            }
          end

          it { is_expected.to be_valid }
        end

        context 'used with job-level when:delayed' do
          let(:config) do
            {
              var_default: {
                stage: 'build',
                script: 'test',
                when: 'delayed',
                start_in: '10 minutes',
                rules: [{ if: '$VAR == null' }]
              }
            }
          end

          it_behaves_like 'returns errors', /may not be used with `rules`: start_in/
        end
      end

      describe 'cross pipeline needs' do
        context 'when configuration is valid' do
          let(:config) do
            <<~YAML
            rspec:
              stage: test
              script: rspec
              needs:
                - pipeline: $THE_PIPELINE_ID
                  job: dependency-job
            YAML
          end

          it 'returns a valid configuration and sets artifacts: true by default' do
            expect(subject).to be_valid

            rspec_build = subject.builds.find { |build| build[:name] == 'rspec' }
            expect(rspec_build.dig(:options, :cross_dependencies)).to eq(
              [{ pipeline: '$THE_PIPELINE_ID', job: 'dependency-job', artifacts: true }]
            )
          end

          context 'when pipeline ID is hard-coded' do
            let(:config) do
              <<~YAML
              rspec:
                stage: test
                script: rspec
                needs:
                  - pipeline: "123"
                    job: dependency-job
              YAML
            end

            it 'returns a valid configuration and sets artifacts: true by default' do
              expect(subject).to be_valid

              rspec_build = subject.builds.find { |build| build[:name] == 'rspec' }
              expect(rspec_build.dig(:options, :cross_dependencies)).to eq(
                [{ pipeline: '123', job: 'dependency-job', artifacts: true }]
              )
            end
          end
        end

        context 'when configuration is not valid' do
          let(:config) do
            <<~YAML
            rspec:
              stage: test
              script: rspec
              needs:
                - pipeline: $THE_PIPELINE_ID
                  job: dependency-job
                  something: else
            YAML
          end

          it 'returns an error' do
            expect(subject).not_to be_valid
            expect(subject.errors).to include(/:need config contains unknown keys: something/)
          end
        end
      end

      describe "Hidden jobs" do
        let(:config_processor) { described_class.new(config).execute }

        subject { config_processor.builds }

        shared_examples 'hidden_job_handling' do
          it "doesn't create jobs that start with dot" do
            expect(subject.size).to eq(1)
            expect(subject.first).to eq({
              stage: "test",
              stage_idx: 2,
              name: "normal_job",
              only: { refs: %w[branches tags] },
              options: {
                script: ["test"]
              },
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end
        end

        context 'when hidden job have a script definition' do
          let(:config) do
            YAML.dump({
                        '.hidden_job' => { image: 'image:1.0', script: 'test' },
                        'normal_job' => { script: 'test' }
                      })
          end

          it_behaves_like 'hidden_job_handling'
        end

        context "when hidden job doesn't have a script definition" do
          let(:config) do
            YAML.dump({
                        '.hidden_job' => { image: 'image:1.0' },
                        'normal_job' => { script: 'test' }
                      })
          end

          it_behaves_like 'hidden_job_handling'
        end
      end

      describe "YAML Alias/Anchor" do
        let(:config_processor) { described_class.new(config).execute }

        subject { config_processor.builds }

        shared_examples 'job_templates_handling' do
          it "is correctly supported for jobs" do
            expect(subject.size).to eq(2)
            expect(subject.first).to eq({
              stage: "build",
              stage_idx: 1,
              name: "job1",
              only: { refs: %w[branches tags] },
              options: {
                script: ["execute-script-for-job"]
              },
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
            expect(subject.second).to eq({
              stage: "build",
              stage_idx: 1,
              name: "job2",
              only: { refs: %w[branches tags] },
              options: {
                script: ["execute-script-for-job"]
              },
              when: "on_success",
              allow_failure: false,
              job_variables: [],
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
          end
        end

        context 'when template is a job' do
          let(:config) do
            <<~EOT
            job1: &JOBTMPL
              stage: build
              script: execute-script-for-job

            job2: *JOBTMPL
            EOT
          end

          it_behaves_like 'job_templates_handling'
        end

        context 'when template is a hidden job' do
          let(:config) do
            <<~EOT
            .template: &JOBTMPL
              stage: build
              script: execute-script-for-job

            job1: *JOBTMPL

            job2: *JOBTMPL
            EOT
          end

          it_behaves_like 'job_templates_handling'
        end

        context 'when job adds its own keys to a template definition' do
          let(:config) do
            <<~EOT
            .template: &JOBTMPL
              stage: build

            job1:
              <<: *JOBTMPL
              script: execute-script-for-job

            job2:
              <<: *JOBTMPL
              script: execute-script-for-job
            EOT
          end

          it_behaves_like 'job_templates_handling'
        end
      end

      describe 'with parent-child pipeline' do
        let(:config) do
          YAML.dump({
            build1: { stage: 'build', script: 'test' },
            test1: {
              stage: 'test',
              trigger: {
                include: includes
              }
            }
          })
        end

        context 'when artifact and job are specified' do
          let(:includes) { [{ artifact: 'generated.yml', job: 'build1' }] }

          it { is_expected.to be_valid }
        end

        context 'when job is not specified while artifact is' do
          let(:includes) { [{ artifact: 'generated.yml' }] }

          it_behaves_like 'returns errors', /include config must specify the job where to fetch the artifact from/
        end

        context 'when project and file are specified' do
          let(:includes) do
            [{ file: 'generated.yml', project: 'my-namespace/my-project' }]
          end

          it { is_expected.to be_valid }
        end

        context 'when file is not specified while project is' do
          let(:includes) { [{ project: 'something' }] }

          it_behaves_like 'returns errors', /include config must specify the file where to fetch the config from/
        end

        context 'when include is a string' do
          let(:includes) { 'generated.yml' }

          it { is_expected.to be_valid }
        end
      end

      describe "Error handling" do
        subject { described_class.new(config).execute }

        context 'when YAML syntax is invalid' do
          let(:config) { 'invalid: yaml: test' }

          it_behaves_like 'returns errors', /mapping values are not allowed/
        end

        context 'when object is invalid' do
          let(:config) { 'invalid_yaml' }

          it_behaves_like 'returns errors', /Invalid configuration format/
        end

        context 'returns errors if tags parameter is invalid' do
          let(:config) { YAML.dump({ rspec: { script: "test", tags: "mysql" } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:tags config should be an array of strings'
        end

        context 'returns errors if job before_script parameter is not an array of strings' do
          let(:config) { YAML.dump({ rspec: { script: "test", before_script: [10, "test"] } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:before_script config should be a string or a nested array of strings up to 10 levels deep'
        end

        context 'returns errors if job after_script parameter is not an array of strings' do
          let(:config) { YAML.dump({ rspec: { script: "test", after_script: [10, "test"] } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:after_script config should be a string or a nested array of strings up to 10 levels deep'
        end

        context 'returns errors if image parameter is invalid' do
          let(:config) { YAML.dump({ image: ["test"], rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'image config should be a hash or a string'
        end

        context 'returns errors if job name is blank' do
          let(:config) { YAML.dump({ '' => { script: "test" } }) }

          it_behaves_like 'returns errors', "jobs:job name can't be blank"
        end

        context 'returns errors if job name is non-string' do
          let(:config) { YAML.dump({ 10 => { script: "test" } }) }

          it_behaves_like 'returns errors', 'jobs:10 name should be a symbol'
        end

        context 'returns errors if job image parameter is invalid' do
          let(:config) { YAML.dump({ rspec: { script: "test", image: ["test"] } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:image config should be a hash or a string'
        end

        context 'returns errors if services parameter is not an array' do
          let(:config) { YAML.dump({ services: "test", rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'services config should be a array'
        end

        context 'returns errors if services parameter is not an array of strings' do
          let(:config) { YAML.dump({ services: [10, "test"], rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'services:service config should be a hash or a string'
        end

        context 'returns errors if job services parameter is not an array' do
          let(:config) { YAML.dump({ rspec: { script: "test", services: "test" } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:services config should be a array'
        end

        context 'returns errors if job services parameter is not an array of strings' do
          let(:config) { YAML.dump({ rspec: { script: "test", services: [10, "test"] } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:services:service config should be a hash or a string'
        end

        context 'returns error if job configuration is invalid' do
          let(:config) { YAML.dump({ extra: "bundle update" }) }

          it_behaves_like 'returns errors', 'jobs extra config should implement the script:, run:, or trigger: keyword'
        end

        context 'returns errors if services configuration is not correct' do
          let(:config) { YAML.dump({ extra: { script: 'rspec', services: "test" } }) }

          it_behaves_like 'returns errors', 'jobs:extra:services config should be a array'
        end

        context 'returns errors if there are no jobs defined' do
          let(:config) { YAML.dump({ before_script: ["bundle update"] }) }

          it_behaves_like 'returns errors', 'jobs config should contain at least one visible job'
        end

        context 'returns errors if the job script is not defined' do
          let(:config) { YAML.dump({ rspec: { before_script: "test" } }) }

          it_behaves_like 'returns errors', 'jobs rspec config should implement the script:, run:, or trigger: keyword'
        end

        context 'returns errors if there are no visible jobs defined' do
          let(:config) { YAML.dump({ before_script: ["bundle update"], ".hidden": { script: 'ls' } }) }

          it_behaves_like 'returns errors', 'jobs config should contain at least one visible job'
        end

        context 'returns errors if job allow_failure parameter is not an boolean' do
          let(:config) { YAML.dump({ rspec: { script: "test", allow_failure: "string" } }) }

          it_behaves_like 'returns errors', 'jobs:rspec allow failure should be a hash or a boolean value'
        end

        context 'returns errors if job exit_code parameter from allow_failure is not an integer' do
          let(:config) { YAML.dump({ rspec: { script: "test", allow_failure: { exit_codes: 'string' } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:allow_failure exit codes should be an array of integers or an integer'
        end

        context 'returns errors if job stage is not a string' do
          let(:config) { YAML.dump({ rspec: { script: "test", stage: 1 } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:stage config should be a string'
        end

        context 'returns errors if job stage is not a pre-defined stage' do
          let(:config) { YAML.dump({ rspec: { script: "test", stage: "acceptance" } }) }

          it_behaves_like 'returns errors', 'rspec job: chosen stage acceptance does not exist; available stages are .pre, build, test, deploy, .post'
        end

        context 'returns errors if job stage is not a defined stage' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", stage: "acceptance" } }) }

          it_behaves_like 'returns errors', 'rspec job: chosen stage acceptance does not exist; available stages are .pre, build, test, .post'
        end

        context 'returns errors if stages is not an array' do
          let(:config) { YAML.dump({ stages: "test", rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'stages config should be an array of strings or a nested array of strings up to 10 levels deep'
        end

        context 'returns errors if stages is not an array of strings' do
          let(:config) { YAML.dump({ stages: [true, "test"], rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'stages config should be an array of strings or a nested array of strings up to 10 levels deep'
        end

        context 'returns errors if variables is not a map' do
          let(:config) { YAML.dump({ variables: "test", rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'variables config should be a hash'
        end

        context 'returns errors if variables is not a map of scalars' do
          let(:config) { YAML.dump({ variables: { test: [] }, rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'variable definition must be either a string or a hash'
        end

        context 'returns errors if job when is not on_success, on_failure or always' do
          let(:config) { YAML.dump({ rspec: { script: "test", when: 1 } }) }

          it_behaves_like 'returns errors', "jobs:rspec when should be one of: #{Gitlab::Ci::Config::Entry::Job::ALLOWED_WHEN.join(', ')}"
        end

        context 'returns errors if job artifacts:name is not an a string' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", artifacts: { name: 1 } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:artifacts name should be a string'
        end

        context 'returns errors if job artifacts:when is not an a predefined value' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", artifacts: { when: 1 } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:artifacts when should be one of: on_success, on_failure, always'
        end

        context 'returns errors if job artifacts:expire_in is not an a string' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", artifacts: { expire_in: 1 } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:artifacts expire in should be a duration'
        end

        context 'returns errors if job artifacts:expire_in is not an a valid duration' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", artifacts: { expire_in: "7 elephants" } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:artifacts expire in should be a duration'
        end

        context 'returns errors if job artifacts:untracked is not an array of strings' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", artifacts: { untracked: "string" } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:artifacts untracked should be a boolean value'
        end

        context 'returns errors if job artifacts:paths is not an array of strings' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", artifacts: { paths: "string" } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:artifacts paths should be an array of strings'
        end

        context 'returns errors if cache:untracked is not an array of strings' do
          let(:config) { YAML.dump({ cache: { untracked: "string" }, rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'cache:untracked config should be a boolean value'
        end

        context 'returns errors if cache:paths is not an array of strings' do
          let(:config) { YAML.dump({ cache: { paths: "string" }, rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', 'cache:paths config should be an array of strings'
        end

        context 'returns errors if cache:key is not a string' do
          let(:config) { YAML.dump({ cache: { key: 1 }, rspec: { script: "test" } }) }

          it_behaves_like 'returns errors', "cache:key should be a hash, a string or a symbol"
        end

        context 'returns errors if job cache:key is not an a string' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", cache: { key: 1 } } }) }

          it_behaves_like 'returns errors', "jobs:rspec:cache:key should be a hash, a string or a symbol"
        end

        context 'returns errors if job cache:key:files is not an array of strings' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", cache: { key: { files: [1] } } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:cache:key:files config should be an array of strings'
        end

        context 'returns errors if job cache:key:files is an empty array' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", cache: { key: { files: [] } } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:cache:key:files config requires at least 1 item'
        end

        context 'returns errors if job defines only cache:key:prefix' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", cache: { key: { prefix: 'prefix-key' } } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:cache:key config missing required keys: files'
        end

        context 'returns errors if job cache:key:prefix is not an a string' do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", cache: { key: { prefix: 1, files: ['file'] } } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:cache:key:prefix config should be a string or symbol'
        end

        context "returns errors if job cache:untracked is not an array of strings" do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", cache: { untracked: "string" } } }) }

          it_behaves_like 'returns errors', "jobs:rspec:cache:untracked config should be a boolean value"
        end

        context "returns errors if job cache:paths is not an array of strings" do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", cache: { paths: "string" } } }) }

          it_behaves_like 'returns errors', "jobs:rspec:cache:paths config should be an array of strings"
        end

        context "returns errors if job dependencies is not an array of strings" do
          let(:config) { YAML.dump({ stages: %w[build test], rspec: { script: "test", dependencies: "string" } }) }

          it_behaves_like 'returns errors', "jobs:rspec dependencies should be an array of strings"
        end

        context 'returns errors if pipeline variables expression policy is invalid' do
          let(:config) { YAML.dump({ rspec: { script: 'test', only: { variables: ['== null'] } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:only variables invalid expression syntax'
        end

        context 'returns errors if pipeline changes policy is invalid' do
          let(:config) { YAML.dump({ rspec: { script: 'test', only: { changes: [1] } } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:only changes should be an array of strings'
        end

        context 'returns errors if extended hash configuration is invalid' do
          let(:config) { YAML.dump({ rspec: { extends: 'something', script: 'test' } }) }

          it_behaves_like 'returns errors', 'rspec: unknown keys in `extends` (something)'
        end

        context 'returns errors if parallel is invalid' do
          let(:config) { YAML.dump({ rspec: { parallel: 'test', script: 'test' } }) }

          it_behaves_like 'returns errors', 'jobs:rspec:parallel should be an integer or a hash'
        end

        context 'when the pipeline has a circular dependency' do
          let(:config) do
            <<~YAML
            job_a:
              stage: test
              script: build
              needs: [job_c]

            job_b:
              stage: test
              script: test
              needs: [job_a]

            job_c:
              stage: test
              script: deploy
              needs: [job_b]
            YAML
          end

          it_behaves_like 'returns errors', 'The pipeline has circular dependencies: topological sort failed: ["job_a", "job_c", "job_b"]'

          context 'when a job has a self-dependency' do
            let(:config) do
              <<~YAML
              job_0:
                stage: test
                script: build

              job:
                stage: test
                script: build
                needs: [job_0, job]
              YAML
            end

            it_behaves_like 'returns errors', 'The pipeline has circular dependencies: self-dependency: job'
          end
        end
      end

      describe 'Job rules' do
        context 'changes' do
          let(:config) do
            <<~YAML
            rspec:
              script: exit 0
              rules:
                - changes: [README.md]
            YAML
          end

          it 'returns builds with correct rules' do
            expect(processor.builds.size).to eq(1)
            expect(processor.builds[0]).to match(
              hash_including(
                name: "rspec",
                rules: [{ changes: { paths: ["README.md"] } }]
              )
            )
          end

          context 'with paths' do
            let(:config) do
              <<~YAML
              rspec:
                script: exit 0
                rules:
                  - changes:
                      paths: [README.md]
              YAML
            end

            it 'returns builds with correct rules' do
              expect(processor.builds.size).to eq(1)
              expect(processor.builds[0]).to match(
                hash_including(
                  name: "rspec",
                  rules: [{ changes: { paths: ["README.md"] } }]
                )
              )
            end
          end
        end
      end

      describe 'Workflow rules' do
        context 'changes' do
          let(:config) do
            <<~YAML
            workflow:
              rules:
                - changes: [README.md]

            rspec:
              script: exit 0
            YAML
          end

          it 'returns pipeline with correct rules' do
            expect(processor.builds.size).to eq(1)
            expect(processor.workflow_rules).to eq(
              [{ changes: { paths: ["README.md"] } }]
            )
          end

          context 'with paths' do
            let(:config) do
              <<~YAML
              workflow:
                rules:
                - changes:
                    paths: [README.md]

              rspec:
                script: exit 0
              YAML
            end

            it 'returns pipeline with correct rules' do
              expect(processor.builds.size).to eq(1)
              expect(processor.workflow_rules).to eq(
                [{ changes: { paths: ["README.md"] } }]
              )
            end
          end
        end
      end

      describe '#execute' do
        subject { described_class.new(content).execute }

        context 'when the YAML could not be parsed' do
          let(:content) { YAML.dump('invalid: yaml: test') }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['Invalid configuration format'])
          end
        end

        context 'when the tags parameter is invalid' do
          let(:content) { YAML.dump({ rspec: { script: 'test', tags: 'mysql' } }) }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['jobs:rspec:tags config should be an array of strings'])
          end
        end

        context 'when the configuration contains multiple keyword-syntax errors' do
          let(:content) { YAML.dump({ rspec: { script: 'test', bad_tags: 'mysql', rules: { wrong: 'format' } } }) }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to contain_exactly(
              'jobs:rspec config contains unknown keys: bad_tags',
              'jobs:rspec rules should be an array containing hashes and arrays of hashes')
          end
        end

        context 'when YAML content is empty' do
          let(:content) { '' }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['Please provide content of .gitlab-ci.yml'])
          end
        end

        context 'when the YAML contains an unknown alias' do
          let(:content) { 'steps: *bad_alias' }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to all match(%r{unknown .+ bad_alias}i)
          end
        end

        context 'when the YAML is valid' do
          let(:content) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(true)
            expect(subject.errors).to be_empty
            expect(subject.builds).to be_present
          end
        end
      end

      describe 'verify project sha', :use_clean_rails_redis_caching do
        include_context 'when a project repository contains a forked commit'

        let(:config) { YAML.dump(job: { script: 'echo' }) }
        let(:verify_project_sha) { true }
        let(:sha) { forked_commit_sha }

        let(:processor) { described_class.new(config, project: project, sha: sha, verify_project_sha: verify_project_sha) }

        subject { processor.execute }

        shared_examples 'when the processor is executed twice consecutively' do |branch_names_contains_sha = false|
          it 'calls Gitaly only once for each ref type' do
            expect(repository).to receive(:branch_names_contains).once.and_call_original
            expect(repository).to receive(:tag_names_contains).once.and_call_original unless branch_names_contains_sha

            2.times { processor.execute }
          end
        end

        context 'when a project branch contains the forked commit sha' do
          before_all do
            repository.add_branch(project.owner, 'branch1', forked_commit_sha)
          end

          after(:all) do
            repository.rm_branch(project.owner, 'branch1')
          end

          it { is_expected.to be_valid }

          it_behaves_like 'when the processor is executed twice consecutively', true
        end

        context 'when a project tag contains the forked commit sha' do
          before_all do
            repository.add_tag(project.owner, 'tag1', forked_commit_sha)
          end

          after(:all) do
            repository.rm_tag(project.owner, 'tag1')
          end

          it { is_expected.to be_valid }

          it_behaves_like 'when the processor is executed twice consecutively'
        end

        context 'when a project ref does not contain the forked commit sha' do
          it 'returns an error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(
              /configuration originates from an external project or a commit not associated with a Git reference/)
          end

          it_behaves_like 'when the processor is executed twice consecutively'
        end

        context 'when verify_project_sha option is false' do
          let(:verify_project_sha) { false }

          it { is_expected.to be_valid }
        end

        context 'when project is not provided' do
          let(:project) { nil }

          it { is_expected.to be_valid }
        end

        context 'when sha is not provided' do
          let(:sha) { nil }

          it { is_expected.to be_valid }
        end

        context 'when sha is invalid' do
          let(:sha) { 'invalid-sha' }

          it { is_expected.to be_valid }
        end
      end

      context 'for pages jobs', feature_category: :pages do
        context 'on publish option' do
          context 'when not in a pages job' do
            let(:config) do
              <<-EOYML
              not-pages:
                script: echo
                publish: 'foo'
              EOYML
            end

            it_behaves_like 'returns errors', 'jobs:not-pages publish can only be used within a `pages` job'
          end

          context 'when in a pages job' do
            let(:config) do
              <<-EOYML
              pages:
                script: echo
                publish: 'foo'
              EOYML
            end

            it { is_expected.to be_valid }

            it 'sets the publish configuration' do
              expect(subject.builds.first[:options][:publish]).to eq('foo')
            end
          end
        end

        context 'on pages option' do
          context 'when in a pages job' do
            let(:config) do
              <<-EOYML
              pages:
                script: echo
                pages:
                  path_prefix: 'foo'
              EOYML
            end

            it { is_expected.to be_valid }

            it 'sets the pages configuration' do
              expect(subject.builds.first[:options][:pages]).to eq(path_prefix: 'foo')
            end
          end
        end
      end
    end
  end
end
