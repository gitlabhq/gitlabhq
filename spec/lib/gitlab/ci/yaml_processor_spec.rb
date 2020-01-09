# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    describe YamlProcessor do
      include StubRequests

      subject { described_class.new(config, user: nil) }

      describe '#build_attributes' do
        subject { described_class.new(config, user: nil).build_attributes(:rspec) }

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
            expect(subject).to eq({
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
              yaml_variables: []
            })
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
            expect(subject).to eq({
              stage: 'test',
              stage_idx: 2,
              name: 'rspec',
              options: { script: ['rspec'] },
              rules: [
                { if: '$CI_COMMIT_REF_NAME == "master"' },
                { changes: %w[README.md] }
              ],
              allow_failure: false,
              when: 'on_success',
              yaml_variables: []
            })
          end
        end

        describe 'coverage entry' do
          describe 'code coverage regexp' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec',
                                 coverage: '/Code coverage: \d+\.\d+/' })
            end

            it 'includes coverage regexp in build attributes' do
              expect(subject)
                .to include(coverage_regex: 'Code coverage: \d+\.\d+')
            end
          end
        end

        describe 'interruptible entry' do
          describe 'interruptible job' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec', interruptible: true })
            end

            it { expect(subject[:interruptible]).to be_truthy }
          end

          describe 'interruptible job with default value' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec' })
            end

            it { expect(subject).not_to have_key(:interruptible) }
          end

          describe 'uninterruptible job' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec', interruptible: false })
            end

            it { expect(subject[:interruptible]).to be_falsy }
          end

          it "returns interruptible when overridden for job" do
            config = YAML.dump({ default: { interruptible: true },
                                 rspec: { script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.stage_builds_attributes("test").size).to eq(1)
            expect(config_processor.stage_builds_attributes("test").first).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: { script: ["rspec"] },
              interruptible: true,
              allow_failure: false,
              when: "on_success",
              yaml_variables: []
            })
          end
        end

        describe 'retry entry' do
          context 'when retry count is specified' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec', retry: { max: 1 } })
            end

            it 'includes retry count in build options attribute' do
              expect(subject[:options]).to include(retry: { max: 1 })
            end
          end

          context 'when retry count is not specified' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec' })
            end

            it 'does not persist retry count in the database' do
              expect(subject[:options]).not_to have_key(:retry)
            end
          end

          context 'when retry count is specified by default' do
            let(:config) do
              YAML.dump(default: { retry: { max: 1 } },
                        rspec: { script: 'rspec' })
            end

            it 'does use the default value' do
              expect(subject[:options]).to include(retry: { max: 1 })
            end
          end

          context 'when retry count default value is overridden' do
            let(:config) do
              YAML.dump(default: { retry: { max: 1 } },
                        rspec: { script: 'rspec', retry: { max: 2 } })
            end

            it 'does use the job value' do
              expect(subject[:options]).to include(retry: { max: 2 })
            end
          end
        end

        describe 'allow failure entry' do
          context 'when job is a manual action' do
            context 'when allow_failure is defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec',
                                   when: 'manual',
                                   allow_failure: false })
              end

              it 'is not allowed to fail' do
                expect(subject[:allow_failure]).to be false
              end
            end

            context 'when allow_failure is not defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec',
                                   when: 'manual' })
              end

              it 'is allowed to fail' do
                expect(subject[:allow_failure]).to be true
              end
            end
          end

          context 'when job is not a manual action' do
            context 'when allow_failure is defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec',
                                   allow_failure: false })
              end

              it 'is not allowed to fail' do
                expect(subject[:allow_failure]).to be false
              end
            end

            context 'when allow_failure is not defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec' })
              end

              it 'is not allowed to fail' do
                expect(subject[:allow_failure]).to be false
              end
            end
          end
        end

        describe 'delayed job entry' do
          context 'when delayed is defined' do
            let(:config) do
              YAML.dump(rspec: {
                script:   'rollout 10%',
                when:     'delayed',
                start_in: '1 day'
              })
            end

            it 'has the attributes' do
              expect(subject[:when]).to eq 'delayed'
              expect(subject[:options][:start_in]).to eq '1 day'
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
                  yaml_variables: [],
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
                  yaml_variables: [],
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

      describe '#workflow_attributes' do
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

          it 'parses the workflow:rules configuration' do
            expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'workflow config contains unknown keys: variables')
          end
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
            expect(subject.workflow_attributes[:rules]).to contain_exactly({ if: '$VAR == "value"' })
          end

          it 'parses the root:variables as yaml_variables:' do
            expect(subject.workflow_attributes[:yaml_variables])
              .to contain_exactly({ key: 'SUPPORTED', value: 'parsed', public: true })
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
            expect(subject.workflow_attributes[:rules]).to contain_exactly({ if: '$VAR == "value"' })
          end

          it 'parses the root:variables as yaml_variables:' do
            expect(subject.workflow_attributes[:yaml_variables]).to eq([])
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
            expect(subject.workflow_attributes[:rules]).to be_nil
          end

          it 'parses the root:variables as yaml_variables:' do
            expect(subject.workflow_attributes[:yaml_variables])
              .to contain_exactly({ key: 'SUPPORTED', value: 'parsed', public: true })
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
            expect(subject.workflow_attributes[:rules]).to be_nil
          end

          it 'parses the root:variables as yaml_variables:' do
            expect(subject.workflow_attributes[:yaml_variables]).to eq([])
          end
        end
      end

      describe 'only / except policies validations' do
        context 'when `only` has an invalid value' do
          let(:config) { { rspec: { script: "rspec", type: "test", only: only } } }
          let(:processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

          context 'when it is integer' do
            let(:only) { 1 }

            it do
              expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                  'jobs:rspec:only has to be either an array of conditions or a hash')
            end
          end

          context 'when it is an array of integers' do
            let(:only) { [1, 1] }

            it do
              expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                  'jobs:rspec:only config should be an array of strings or regexps')
            end
          end

          context 'when it is invalid regex' do
            let(:only) { ["/*invalid/"] }

            it do
              expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                  'jobs:rspec:only config should be an array of strings or regexps')
            end
          end
        end

        context 'when `except` has an invalid value' do
          let(:config) { { rspec: { script: "rspec", except: except } } }
          let(:processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

          context 'when it is integer' do
            let(:except) { 1 }

            it do
              expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                  'jobs:rspec:except has to be either an array of conditions or a hash')
            end
          end

          context 'when it is an array of integers' do
            let(:except) { [1, 1] }

            it do
              expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                  'jobs:rspec:except config should be an array of strings or regexps')
            end
          end

          context 'when it is invalid regex' do
            let(:except) { ["/*invalid/"] }

            it do
              expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                  'jobs:rspec:except config should be an array of strings or regexps')
            end
          end
        end
      end

      describe "Scripts handling" do
        let(:config_data) { YAML.dump(config) }
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(config_data) }

        subject { config_processor.stage_builds_attributes('test').first }

        describe "before_script" do
          context "in global context" do
            let(:config) do
              {
                before_script: ["global script"],
                test: { script: ["script"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:before_script]).to eq(["global script"])
            end
          end

          context "in default context" do
            let(:config) do
              {
                default: { before_script: ["global script"] },
                test: { script: ["script"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:before_script]).to eq(["global script"])
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

          context 'when script is array of arrays of strings' do
            let(:config) do
              {
                before_script: [["global script", "echo 1"], ["ls"], "pwd"],
                test: { script: ["script"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:before_script]).to eq(["global script", "echo 1", "ls", "pwd"])
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

          context 'when script is array of arrays of strings' do
            let(:config) do
              {
                test: { script: [["script"], ["echo 1"], "ls"] }
              }
            end

            it "return commands with scripts concatenated" do
              expect(subject[:options][:script]).to eq(["script", "echo 1", "ls"])
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

          context 'when script is array of arrays of strings' do
            let(:config) do
              {
                after_script: [["global script", "echo 1"], ["ls"], "pwd"],
                test: { script: ["script"] }
              }
            end

            it "return after_script in options" do
              expect(subject[:options][:after_script]).to eq(["global script", "echo 1", "ls", "pwd"])
            end
          end
        end
      end

      describe "Image and service handling" do
        context "when extended docker configuration is used" do
          it "returns image and service when defined" do
            config = YAML.dump({ image: { name: "ruby:2.1", entrypoint: ["/usr/local/bin/init", "run"] },
                                 services: ["mysql", { name: "docker:dind", alias: "docker",
                                                       entrypoint: ["/usr/local/bin/init", "run"],
                                                       command: ["/usr/local/bin/init", "run"] }],
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.stage_builds_attributes("test").size).to eq(1)
            expect(config_processor.stage_builds_attributes("test").first).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.1", entrypoint: ["/usr/local/bin/init", "run"] },
                services: [{ name: "mysql" },
                           { name: "docker:dind", alias: "docker", entrypoint: ["/usr/local/bin/init", "run"],
                             command: ["/usr/local/bin/init", "run"] }]
              },
              allow_failure: false,
              when: "on_success",
              yaml_variables: []
            })
          end

          it "returns image and service when overridden for job" do
            config = YAML.dump({ image: "ruby:2.1",
                                 services: ["mysql"],
                                 before_script: ["pwd"],
                                 rspec: { image: { name: "ruby:2.5", entrypoint: ["/usr/local/bin/init", "run"] },
                                          services: [{ name: "postgresql", alias: "db-pg",
                                                       entrypoint: ["/usr/local/bin/init", "run"],
                                                       command: ["/usr/local/bin/init", "run"] }, "docker:dind"],
                                          script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.stage_builds_attributes("test").size).to eq(1)
            expect(config_processor.stage_builds_attributes("test").first).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.5", entrypoint: ["/usr/local/bin/init", "run"] },
                services: [{ name: "postgresql", alias: "db-pg", entrypoint: ["/usr/local/bin/init", "run"],
                             command: ["/usr/local/bin/init", "run"] },
                           { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              yaml_variables: []
            })
          end
        end

        context "when etended docker configuration is not used" do
          it "returns image and service when defined" do
            config = YAML.dump({ image: "ruby:2.1",
                                 services: ["mysql", "docker:dind"],
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.stage_builds_attributes("test").size).to eq(1)
            expect(config_processor.stage_builds_attributes("test").first).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.1" },
                services: [{ name: "mysql" }, { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              yaml_variables: []
            })
          end

          it "returns image and service when overridden for job" do
            config = YAML.dump({ image: "ruby:2.1",
                                 services: ["mysql"],
                                 before_script: ["pwd"],
                                 rspec: { image: "ruby:2.5", services: ["postgresql", "docker:dind"], script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.stage_builds_attributes("test").size).to eq(1)
            expect(config_processor.stage_builds_attributes("test").first).to eq({
              stage: "test",
              stage_idx: 2,
              name: "rspec",
              only: { refs: %w[branches tags] },
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.5" },
                services: [{ name: "postgresql" }, { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              yaml_variables: []
            })
          end
        end
      end

      describe 'Variables' do
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

        subject { config_processor.builds.first[:yaml_variables] }

        context 'when global variables are defined' do
          let(:variables) do
            { 'VAR1' => 'value1', 'VAR2' => 'value2' }
          end
          let(:config) do
            {
              variables: variables,
              before_script: ['pwd'],
              rspec: { script: 'rspec' }
            }
          end

          it 'returns global variables' do
            expect(subject).to contain_exactly(
              { key: 'VAR1', value: 'value1', public: true },
              { key: 'VAR2', value: 'value2', public: true }
            )
          end
        end

        context 'when job and global variables are defined' do
          let(:global_variables) do
            { 'VAR1' => 'global1', 'VAR3' => 'global3' }
          end
          let(:job_variables) do
            { 'VAR1' => 'value1', 'VAR2' => 'value2' }
          end
          let(:config) do
            {
              before_script: ['pwd'],
              variables: global_variables,
              rspec: { script: 'rspec', variables: job_variables }
            }
          end

          it 'returns all unique variables' do
            expect(subject).to contain_exactly(
              { key: 'VAR3', value: 'global3', public: true },
              { key: 'VAR1', value: 'value1', public: true },
              { key: 'VAR2', value: 'value2', public: true }
            )
          end
        end

        context 'when job variables are defined' do
          let(:config) do
            {
              before_script: ['pwd'],
              rspec: { script: 'rspec', variables: variables }
            }
          end

          context 'when syntax is correct' do
            let(:variables) do
              { 'VAR1' => 'value1', 'VAR2' => 'value2' }
            end

            it 'returns job variables' do
              expect(subject).to contain_exactly(
                { key: 'VAR1', value: 'value1', public: true },
                { key: 'VAR2', value: 'value2', public: true }
              )
            end
          end

          context 'when syntax is incorrect' do
            context 'when variables defined but invalid' do
              let(:variables) do
                %w(VAR1 value1 VAR2 value2)
              end

              it 'raises error' do
                expect { subject }
                  .to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                   /jobs:rspec:variables config should be a hash of key value pairs/)
              end
            end

            context 'when variables key defined but value not specified' do
              let(:variables) do
                nil
              end

              it 'returns empty array' do
                ##
                # When variables config is empty, we assume this is a valid
                # configuration, see issue #18775
                #
                expect(subject).to be_an_instance_of(Array)
                expect(subject).to be_empty
              end
            end
          end
        end

        context 'when job variables are not defined' do
          let(:config) do
            {
              before_script: ['pwd'],
              rspec: { script: 'rspec' }
            }
          end

          it 'returns empty array' do
            expect(subject).to be_an_instance_of(Array)
            expect(subject).to be_empty
          end
        end
      end

      context 'when using `extends`' do
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(config) }

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
            expect(subject.dig(:options, :script)).to eq %w(test)
            expect(subject.dig(:options, :image, :name)).to eq 'ruby:alpine'
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
            expect(subject.dig(:options, :script)).to eq %w(rspec)
            expect(subject.dig(:options, :image, :name)).to eq 'image:test'
            expect(subject.dig(:when)).to eq 'always'
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

        subject { Gitlab::Ci::YamlProcessor.new(YAML.dump(config), opts) }

        context "when validating a ci config file with no project context" do
          context "when a single string is provided" do
            let(:include_content) { "/local.gitlab-ci.yml" }

            it "returns a validation error" do
              expect { subject }.to raise_error /does not have project/
            end
          end

          context "when an array is provided" do
            let(:include_content) { ["/local.gitlab-ci.yml"] }

            it "returns a validation error" do
              expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, /does not have project/)
            end
          end

          context "when an array of wrong keyed object is provided" do
            let(:include_content) { [{ yolo: "/local.gitlab-ci.yml" }] }

            it "returns a validation error" do
              expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError)
            end
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

            it "does not return any error" do
              expect { subject }.not_to raise_error
            end
          end

          context "when the include type is incorrect" do
            let(:include_content) { { name: "/local.gitlab-ci.yml" } }

            it "returns an invalid configuration error" do
              expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError)
            end
          end
        end

        context "when validating a ci config file within a project" do
          let(:include_content) { "/local.gitlab-ci.yml" }
          let(:project) { create(:project, :repository) }
          let(:opts) { { project: project, sha: project.commit.sha } }

          context "when the included internal file is present" do
            before do
              expect(project.repository).to receive(:blob_data_at)
                .and_return(YAML.dump({ job1: { script: 'hello' } }))
            end

            it "does not return an error" do
              expect { subject }.not_to raise_error
            end
          end

          context "when the included internal file is not present" do
            it "returns an error with missing file details" do
              expect { subject }.to raise_error(
                Gitlab::Ci::YamlProcessor::ValidationError,
                "Local file `#{include_content}` does not exist!"
              )
            end
          end
        end
      end

      describe 'when:' do
        (Gitlab::Ci::Config::Entry::Job::ALLOWED_WHEN - %w[delayed]).each do |when_state|
          it "#{when_state} creates one build and sets when:" do
            config = YAML.dump({
              rspec: { script: 'rspec', when: when_state }
            })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)
            builds = config_processor.stage_builds_attributes("test")

            expect(builds.size).to eq(1)
            expect(builds.first[:when]).to eq(when_state)
          end
        end

        context 'delayed' do
          context 'with start_in' do
            it 'creates one build and sets when:' do
              config = YAML.dump({
                rspec: { script: 'rspec', when: 'delayed', start_in: '1 hour' }
              })

              config_processor = Gitlab::Ci::YamlProcessor.new(config)
              builds = config_processor.stage_builds_attributes("test")

              expect(builds.size).to eq(1)
              expect(builds.first[:when]).to eq('delayed')
              expect(builds.first[:options][:start_in]).to eq('1 hour')
            end
          end

          context 'without start_in' do
            it 'raises an error' do
              config = YAML.dump({
                rspec: { script: 'rspec', when: 'delayed' }
              })

              expect do
                Gitlab::Ci::YamlProcessor.new(config)
              end.to raise_error(YamlProcessor::ValidationError, /start in should be a duration/)
            end
          end
        end
      end

      describe 'Parallel' do
        context 'when job is parallelized' do
          let(:parallel) { 5 }

          let(:config) do
            YAML.dump(rspec: { script: 'rspec',
                               parallel: parallel })
          end

          it 'returns parallelized jobs' do
            config_processor = Gitlab::Ci::YamlProcessor.new(config)
            builds = config_processor.stage_builds_attributes('test')
            build_options = builds.map { |build| build[:options] }

            expect(builds.size).to eq(5)
            expect(build_options).to all(include(:instance, parallel: parallel))
          end

          it 'does not have the original job' do
            config_processor = Gitlab::Ci::YamlProcessor.new(config)
            builds = config_processor.stage_builds_attributes('test')

            expect(builds).not_to include(:rspec)
          end
        end
      end

      describe 'cache' do
        context 'when cache definition has unknown keys' do
          it 'raises relevant validation error' do
            config = YAML.dump(
              { cache: { untracked: true, invalid: 'key' },
                rspec: { script: 'rspec' } })

            expect { Gitlab::Ci::YamlProcessor.new(config) }.to raise_error(
              Gitlab::Ci::YamlProcessor::ValidationError,
              'cache config contains unknown keys: invalid'
            )
          end
        end

        it "returns cache when defined globally" do
          config = YAML.dump({
                               cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'key' },
                               rspec: {
                                 script: "rspec"
                               }
                             })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.stage_builds_attributes("test").size).to eq(1)
          expect(config_processor.stage_builds_attributes("test").first[:cache]).to eq(
            paths: ["logs/", "binaries/"],
            untracked: true,
            key: 'key',
            policy: 'pull-push'
          )
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

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.stage_builds_attributes("test").size).to eq(1)
          expect(config_processor.stage_builds_attributes("test").first[:cache]).to eq(
            paths: ["logs/", "binaries/"],
            untracked: true,
            key: { files: ['file'] },
            policy: 'pull-push'
          )
        end

        it 'returns cache key when defined in a job' do
          config = YAML.dump({
                               rspec: {
                                 cache: { paths: ['logs/', 'binaries/'], untracked: true, key: 'key' },
                                 script: 'rspec'
                               }
                             })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.stage_builds_attributes('test').size).to eq(1)
          expect(config_processor.stage_builds_attributes('test').first[:cache]).to eq(
            paths: ['logs/', 'binaries/'],
            untracked: true,
            key: 'key',
            policy: 'pull-push'
          )
        end

        it 'returns cache files' do
          config = YAML.dump(
            rspec: {
              cache: {
                paths: ['logs/', 'binaries/'],
                untracked: true,
                key: { files: ['file'] }
              },
              script: 'rspec'
            }
          )

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.stage_builds_attributes('test').size).to eq(1)
          expect(config_processor.stage_builds_attributes('test').first[:cache]).to eq(
            paths: ['logs/', 'binaries/'],
            untracked: true,
            key: { files: ['file'] },
            policy: 'pull-push'
          )
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

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.stage_builds_attributes('test').size).to eq(1)
          expect(config_processor.stage_builds_attributes('test').first[:cache]).to eq(
            paths: ['logs/', 'binaries/'],
            untracked: true,
            key: { files: ['file'], prefix: 'prefix' },
            policy: 'pull-push'
          )
        end

        it "overwrite cache when defined for a job and globally" do
          config = YAML.dump({
                               cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'global' },
                               rspec: {
                                 script: "rspec",
                                 cache: { paths: ["test/"], untracked: false, key: 'local' }
                               }
                             })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.stage_builds_attributes("test").size).to eq(1)
          expect(config_processor.stage_builds_attributes("test").first[:cache]).to eq(
            paths: ["test/"],
            untracked: false,
            key: 'local',
            policy: 'pull-push'
          )
        end
      end

      describe "Artifacts" do
        it "returns artifacts when defined" do
          config = YAML.dump({
                               image:         "ruby:2.1",
                               services:      ["mysql"],
                               before_script: ["pwd"],
                               rspec:         {
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

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.stage_builds_attributes("test").size).to eq(1)
          expect(config_processor.stage_builds_attributes("test").first).to eq({
            stage: "test",
            stage_idx: 2,
            name: "rspec",
            only: { refs: %w[branches tags] },
            options: {
              before_script: ["pwd"],
              script: ["rspec"],
              image: { name: "ruby:2.1" },
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
            yaml_variables: []
          })
        end

        %w[on_success on_failure always].each do |when_state|
          it "returns artifacts for when #{when_state}  defined" do
            config = YAML.dump({
                                 rspec: {
                                   script: "rspec",
                                   artifacts: { paths: ["logs/", "binaries/"], when: when_state }
                                 }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)
            builds = config_processor.stage_builds_attributes("test")

            expect(builds.size).to eq(1)
            expect(builds.first[:options][:artifacts][:when]).to eq(when_state)
          end
        end

        it "gracefully handles errors in artifacts type" do
          config = <<~YAML
          test:
            script:
              - echo "Hello world"
            artifacts:
              - paths:
              - test/
          YAML

          expect { described_class.new(config) }.to raise_error(described_class::ValidationError)
        end
      end

      describe '#environment' do
        let(:config) do
          {
            deploy_to_production: { stage: 'deploy', script: 'test', environment: environment }
          }
        end

        let(:processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }
        let(:builds) { processor.stage_builds_attributes('deploy') }

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

          it 'raises error' do
            expect { builds }.to raise_error(
              'jobs:deploy_to_production:environment config should be a hash or a string')
          end
        end

        context 'is not a valid string' do
          let(:environment) { 'production:staging' }

          it 'raises error' do
            expect { builds }.to raise_error("jobs:deploy_to_production:environment name #{Gitlab::Regex.environment_name_regex_message}")
          end
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

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review is not defined')
            end
          end

          context 'with close job without environment' do
            let(:close_review) { { stage: 'deploy', script: 'test' } }

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review does not have environment defined')
            end
          end

          context 'with close job for different environment' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: 'production' } }

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review have different environment name')
            end
          end

          context 'with close job without stop action' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: { name: 'review' } } }

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review needs to have action stop defined')
            end
          end
        end
      end

      describe "Timeout" do
        let(:config) do
          {
            deploy_to_production: {
              stage:  'deploy',
              script: 'test'
            }
          }
        end

        let(:processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }
        let(:builds) { processor.stage_builds_attributes('deploy') }

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

          it 'raises an error for invalid number' do
            expect { builds }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'jobs:deploy_to_production:timeout config should be a duration')
          end
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
            deploy: { stage: 'test', script: 'test' }
          }
        end

        subject { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

        context 'no dependencies' do
          let(:dependencies) { }

          it { expect { subject }.not_to raise_error }
        end

        context 'dependencies to builds' do
          let(:dependencies) { %w(build1 build2) }

          it { expect { subject }.not_to raise_error }
        end

        context 'dependencies to builds defined as symbols' do
          let(:dependencies) { [:build1, :build2] }

          it { expect { subject }.not_to raise_error }
        end

        context 'undefined dependency' do
          let(:dependencies) { ['undefined'] }

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'test1 job: undefined dependency: undefined') }
        end

        context 'dependencies to deploy' do
          let(:dependencies) { ['deploy'] }

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'test1 job: dependency deploy is not defined in prior stages') }
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

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, /is not defined in prior stages/) }
        end
      end

      describe "Job Needs" do
        let(:needs) { }
        let(:dependencies) { }

        let(:config) do
          {
            build1: { stage: 'build', script: 'test' },
            build2: { stage: 'build', script: 'test' },
            parallel: { stage: 'build', script: 'test', parallel: 2 },
            test1: { stage: 'test', script: 'test', needs: needs, dependencies: dependencies },
            test2: { stage: 'test', script: 'test' },
            deploy: { stage: 'test', script: 'test' }
          }
        end

        subject { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

        context 'no needs' do
          it { expect { subject }.not_to raise_error }
        end

        context 'needs two builds' do
          let(:needs) { %w(build1 build2) }

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
              yaml_variables: []
            )
            expect(subject.builds[4]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "build1", artifacts: true },
                { name: "build2", artifacts: true }
              ],
              when: "on_success",
              allow_failure: false,
              yaml_variables: []
            )
          end
        end

        context 'needs two builds' do
          let(:needs) do
            [
              { job: 'parallel', artifacts: false },
              { job: 'build1',   artifacts: true },
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
              yaml_variables: []
            )
            expect(subject.builds[4]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "parallel 1/2", artifacts: false },
                { name: "parallel 2/2", artifacts: false },
                { name: "build1", artifacts: true },
                { name: "build2", artifacts: true }
              ],
              when: "on_success",
              allow_failure: false,
              yaml_variables: []
            )
          end
        end

        context 'needs parallel job' do
          let(:needs) { %w(parallel) }

          it "does create jobs with valid specification" do
            expect(subject.builds.size).to eq(7)
            expect(subject.builds[4]).to eq(
              stage: "test",
              stage_idx: 2,
              name: "test1",
              only: { refs: %w[branches tags] },
              options: { script: ["test"] },
              needs_attributes: [
                { name: "parallel 1/2", artifacts: true },
                { name: "parallel 2/2", artifacts: true }
              ],
              when: "on_success",
              allow_failure: false,
              yaml_variables: []
            )
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
                { name: "build1", artifacts: true },
                { name: "build2", artifacts: true },
                { name: "parallel 1/2", artifacts: true },
                { name: "parallel 2/2", artifacts: true }
              ],
              when: "on_success",
              allow_failure: false,
              yaml_variables: []
            )
          end
        end

        context 'undefined need' do
          let(:needs) { ['undefined'] }

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'test1 job: undefined need: undefined') }
        end

        context 'needs to deploy' do
          let(:needs) { ['deploy'] }

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'test1 job: need deploy is not defined in prior stages') }
        end

        context 'needs and dependencies that are mismatching' do
          let(:needs) { %w(build1) }
          let(:dependencies) { %w(build2) }

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'jobs:test1 dependencies the build2 should be part of needs') }
        end
      end

      context 'with when/rules conflict' do
        subject { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

        let(:config) do
          {
            var_default:     { stage: 'build',  script: 'test', rules: [{ if: '$VAR == null' }] },
            var_when:        { stage: 'build',  script: 'test', rules: [{ if: '$VAR == null', when: 'always' }] },
            var_and_changes: { stage: 'build',  script: 'test', rules: [{ if: '$VAR == null', changes: %w[README], when: 'always' }] },
            changes_not_var: { stage: 'test',   script: 'test', rules: [{ if: '$VAR != null', changes: %w[README] }] },
            var_not_changes: { stage: 'test',   script: 'test', rules: [{ if: '$VAR == null', changes: %w[other/file.rb], when: 'always' }] },
            nothing:         { stage: 'test',   script: 'test', rules: [{ when: 'manual' }] },
            var_never:       { stage: 'deploy', script: 'test', rules: [{ if: '$VAR == null', when: 'never' }] },
            var_delayed:     { stage: 'deploy', script: 'test', rules: [{ if: '$VAR == null', when: 'delayed', start_in: '3 hours' }] },
            two_rules:       { stage: 'deploy', script: 'test', rules: [{ if: '$VAR == null', when: 'on_success' }, { changes: %w[README], when: 'manual' }] }
          }
        end

        it 'raises no exceptions' do
          expect { subject }.not_to raise_error
        end

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

          it 'raises a ValidationError' do
            expect { subject }.to raise_error(YamlProcessor::ValidationError, /may not be used with `rules`: when/)
          end
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

          it 'raises a ValidationError' do
            expect { subject }.to raise_error(YamlProcessor::ValidationError, /may not be used with `rules`: when, start_in/)
          end
        end
      end

      describe "Hidden jobs" do
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(config) }

        subject { config_processor.stage_builds_attributes("test") }

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
              yaml_variables: []
            })
          end
        end

        context 'when hidden job have a script definition' do
          let(:config) do
            YAML.dump({
                        '.hidden_job' => { image: 'ruby:2.1', script: 'test' },
                        'normal_job' => { script: 'test' }
                      })
          end

          it_behaves_like 'hidden_job_handling'
        end

        context "when hidden job doesn't have a script definition" do
          let(:config) do
            YAML.dump({
                        '.hidden_job' => { image: 'ruby:2.1' },
                        'normal_job' => { script: 'test' }
                      })
          end

          it_behaves_like 'hidden_job_handling'
        end
      end

      describe "YAML Alias/Anchor" do
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(config) }

        subject { config_processor.stage_builds_attributes("build") }

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
              yaml_variables: []
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
              yaml_variables: []
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

      describe "Error handling" do
        it "fails to parse YAML" do
          expect do
            Gitlab::Ci::YamlProcessor.new("invalid: yaml: test")
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError)
        end

        it "indicates that object is invalid" do
          expect do
            Gitlab::Ci::YamlProcessor.new("invalid_yaml")
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError)
        end

        it "returns errors if tags parameter is invalid" do
          config = YAML.dump({ rspec: { script: "test", tags: "mysql" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:tags config should be an array of strings")
        end

        it "returns errors if before_script parameter is invalid" do
          config = YAML.dump({ before_script: "bundle update", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "before_script config should be an array containing strings and arrays of strings")
        end

        it "returns errors if job before_script parameter is not an array of strings" do
          config = YAML.dump({ rspec: { script: "test", before_script: [10, "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:before_script config should be an array containing strings and arrays of strings")
        end

        it "returns errors if job before_script parameter is multi-level nested array of strings" do
          config = YAML.dump({ rspec: { script: "test", before_script: [["ls", ["pwd"]], "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:before_script config should be an array containing strings and arrays of strings")
        end

        it "returns errors if after_script parameter is invalid" do
          config = YAML.dump({ after_script: "bundle update", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "after_script config should be an array containing strings and arrays of strings")
        end

        it "returns errors if job after_script parameter is not an array of strings" do
          config = YAML.dump({ rspec: { script: "test", after_script: [10, "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:after_script config should be an array containing strings and arrays of strings")
        end

        it "returns errors if job after_script parameter is multi-level nested array of strings" do
          config = YAML.dump({ rspec: { script: "test", after_script: [["ls", ["pwd"]], "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:after_script config should be an array containing strings and arrays of strings")
        end

        it "returns errors if image parameter is invalid" do
          config = YAML.dump({ image: ["test"], rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "image config should be a hash or a string")
        end

        it "returns errors if job name is blank" do
          config = YAML.dump({ '' => { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:job name can't be blank")
        end

        it "returns errors if job name is non-string" do
          config = YAML.dump({ 10 => { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:10 name should be a symbol")
        end

        it "returns errors if job image parameter is invalid" do
          config = YAML.dump({ rspec: { script: "test", image: ["test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:image config should be a hash or a string")
        end

        it "returns errors if services parameter is not an array" do
          config = YAML.dump({ services: "test", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "services config should be a array")
        end

        it "returns errors if services parameter is not an array of strings" do
          config = YAML.dump({ services: [10, "test"], rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "services:service config should be a hash or a string")
        end

        it "returns errors if job services parameter is not an array" do
          config = YAML.dump({ rspec: { script: "test", services: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:services config should be a array")
        end

        it "returns errors if job services parameter is not an array of strings" do
          config = YAML.dump({ rspec: { script: "test", services: [10, "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:services:service config should be a hash or a string")
        end

        it "returns error if job configuration is invalid" do
          config = YAML.dump({ extra: "bundle update" })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "root config contains unknown keys: extra")
        end

        it "returns errors if services configuration is not correct" do
          config = YAML.dump({ extra: { script: 'rspec', services: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:extra:services config should be a array")
        end

        it "returns errors if there are no jobs defined" do
          config = YAML.dump({ before_script: ["bundle update"] })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs config should contain at least one visible job")
        end

        it "returns errors if there are no visible jobs defined" do
          config = YAML.dump({ before_script: ["bundle update"], '.hidden'.to_sym => { script: 'ls' } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs config should contain at least one visible job")
        end

        it "returns errors if job allow_failure parameter is not an boolean" do
          config = YAML.dump({ rspec: { script: "test", allow_failure: "string" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec allow failure should be a boolean value")
        end

        it "returns errors if job stage is not a string" do
          config = YAML.dump({ rspec: { script: "test", type: 1 } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:type config should be a string")
        end

        it "returns errors if job stage is not a pre-defined stage" do
          config = YAML.dump({ rspec: { script: "test", type: "acceptance" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "rspec job: stage parameter should be .pre, build, test, deploy, .post")
        end

        it "returns errors if job stage is not a defined stage" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", type: "acceptance" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "rspec job: stage parameter should be .pre, build, test, .post")
        end

        it "returns errors if stages is not an array" do
          config = YAML.dump({ stages: "test", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "stages config should be an array of strings")
        end

        it "returns errors if stages is not an array of strings" do
          config = YAML.dump({ stages: [true, "test"], rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "stages config should be an array of strings")
        end

        it "returns errors if variables is not a map" do
          config = YAML.dump({ variables: "test", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "variables config should be a hash of key value pairs")
        end

        it "returns errors if variables is not a map of key-value strings" do
          config = YAML.dump({ variables: { test: false }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "variables config should be a hash of key value pairs")
        end

        it "returns errors if job when is not on_success, on_failure or always" do
          config = YAML.dump({ rspec: { script: "test", when: 1 } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec when should be one of: #{Gitlab::Ci::Config::Entry::Job::ALLOWED_WHEN.join(', ')}")
        end

        it "returns errors if job artifacts:name is not an a string" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { name: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts name should be a string")
        end

        it "returns errors if job artifacts:when is not an a predefined value" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { when: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts when should be on_success, on_failure or always")
        end

        it "returns errors if job artifacts:expire_in is not an a string" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { expire_in: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts expire in should be a duration")
        end

        it "returns errors if job artifacts:expire_in is not an a valid duration" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { expire_in: "7 elephants" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts expire in should be a duration")
        end

        it "returns errors if job artifacts:untracked is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { untracked: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts untracked should be a boolean value")
        end

        it "returns errors if job artifacts:paths is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { paths: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts paths should be an array of strings")
        end

        it "returns errors if cache:untracked is not an array of strings" do
          config = YAML.dump({ cache: { untracked: "string" }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "cache:untracked config should be a boolean value")
        end

        it "returns errors if cache:paths is not an array of strings" do
          config = YAML.dump({ cache: { paths: "string" }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "cache:paths config should be an array of strings")
        end

        it "returns errors if cache:key is not a string" do
          config = YAML.dump({ cache: { key: 1 }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "cache:key should be a hash, a string or a symbol")
        end

        it "returns errors if job cache:key is not an a string" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { key: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:cache:key should be a hash, a string or a symbol")
        end

        it 'returns errors if job cache:key:files is not an array of strings' do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { key: { files: [1] } } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'jobs:rspec:cache:key:files config should be an array of strings')
        end

        it 'returns errors if job cache:key:files is an empty array' do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { key: { files: [] } } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'jobs:rspec:cache:key:files config requires at least 1 item')
        end

        it 'returns errors if job defines only cache:key:prefix' do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { key: { prefix: 'prefix-key' } } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'jobs:rspec:cache:key config missing required keys: files')
        end

        it 'returns errors if job cache:key:prefix is not an a string' do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { key: { prefix: 1, files: ['file'] } } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'jobs:rspec:cache:key:prefix config should be a string or symbol')
        end

        it "returns errors if job cache:untracked is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { untracked: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:cache:untracked config should be a boolean value")
        end

        it "returns errors if job cache:paths is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { paths: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:cache:paths config should be an array of strings")
        end

        it "returns errors if job dependencies is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", dependencies: "string" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec dependencies should be an array of strings")
        end

        it 'returns errors if pipeline variables expression policy is invalid' do
          config = YAML.dump({ rspec: { script: 'test', only: { variables: ['== null'] } } })

          expect { Gitlab::Ci::YamlProcessor.new(config) }
            .to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                            'jobs:rspec:only variables invalid expression syntax')
        end

        it 'returns errors if pipeline changes policy is invalid' do
          config = YAML.dump({ rspec: { script: 'test', only: { changes: [1] } } })

          expect { Gitlab::Ci::YamlProcessor.new(config) }
            .to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                            'jobs:rspec:only changes should be an array of strings')
        end

        it 'returns errors if extended hash configuration is invalid' do
          config = YAML.dump({ rspec: { extends: 'something', script: 'test' } })

          expect { Gitlab::Ci::YamlProcessor.new(config) }
            .to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                            'rspec: unknown keys in `extends` (something)')
        end
      end

      describe "#validation_message" do
        subject { Gitlab::Ci::YamlProcessor.validation_message(content) }

        context "when the YAML could not be parsed" do
          let(:content) { YAML.dump("invalid: yaml: test") }

          it { is_expected.to eq "Invalid configuration format" }
        end

        context "when the tags parameter is invalid" do
          let(:content) { YAML.dump({ rspec: { script: "test", tags: "mysql" } }) }

          it { is_expected.to eq "jobs:rspec:tags config should be an array of strings" }
        end

        context "when YAML content is empty" do
          let(:content) { '' }

          it { is_expected.to eq "Please provide content of .gitlab-ci.yml" }
        end

        context 'when the YAML contains an unknown alias' do
          let(:content) { 'steps: *bad_alias' }

          it { is_expected.to eq "Unknown alias: bad_alias" }
        end

        context "when the YAML is valid" do
          let(:content) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

          it { is_expected.to be_nil }
        end
      end

      describe '.new_with_validation_errors' do
        subject { Gitlab::Ci::YamlProcessor.new_with_validation_errors(content) }

        context 'when the YAML could not be parsed' do
          let(:content) { YAML.dump('invalid: yaml: test') }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['Invalid configuration format'])
            expect(subject.content).to be_blank
          end
        end

        context 'when the tags parameter is invalid' do
          let(:content) { YAML.dump({ rspec: { script: 'test', tags: 'mysql' } }) }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['jobs:rspec:tags config should be an array of strings'])
            expect(subject.content).to be_blank
          end
        end

        context 'when the configuration contains multiple keyword-syntax errors' do
          let(:content) { YAML.dump({ rspec: { script: 'test', bad_tags: 'mysql', rules: { wrong: 'format' } } }) }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['jobs:rspec config contains unknown keys: bad_tags', 'jobs:rspec rules should be an array of hashes'])
            expect(subject.content).to be_blank
          end
        end

        context 'when YAML content is empty' do
          let(:content) { '' }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['Please provide content of .gitlab-ci.yml'])
            expect(subject.content).to be_blank
          end
        end

        context 'when the YAML contains an unknown alias' do
          let(:content) { 'steps: *bad_alias' }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to eq(['Unknown alias: bad_alias'])
            expect(subject.content).to be_blank
          end
        end

        context 'when the YAML is valid' do
          let(:content) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

          it 'returns errors and empty configuration' do
            expect(subject.valid?).to eq(true)
            expect(subject.errors).to be_empty
            expect(subject.content).to be_present
          end
        end
      end
    end
  end
end
