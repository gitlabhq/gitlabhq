# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Job, feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  let(:entry) { described_class.new(config, name: :rspec) }

  it_behaves_like 'with inheritable CI config' do
    let(:config) { { script: 'echo' } }
    let(:inheritable_key) { 'default' }
    let(:inheritable_class) { Gitlab::Ci::Config::Entry::Default }

    # These are entries defined in Default
    # that we know that we don't want to inherit
    # as they do not have sense in context of Job
    let(:ignored_inheritable_columns) do
      %i[]
    end

    before do
      allow(entry).to receive_message_chain(:inherit_entry, :default_entry, :inherit?).and_return(true)
    end
  end

  describe '.nodes' do
    context 'when filtering all the entry/node names' do
      subject { described_class.nodes.keys }

      let(:result) do
        %i[before_script script after_script hooks stage cache
           image services only except rules needs variables artifacts
           coverage retry interruptible timeout release tags
           inherit parallel]
      end

      it { is_expected.to include(*result) }
    end
  end

  describe '.matching?' do
    subject { described_class.matching?(name, config) }

    context 'when config is not a hash' do
      let(:name) { :rspec }
      let(:config) { 'string' }

      it { is_expected.to be_falsey }
    end

    context 'when config is a regular job' do
      let(:name) { :rspec }
      let(:config) do
        { script: 'ls -al' }
      end

      it { is_expected.to be_truthy }
    end

    context 'when config is a regular job with run keyword' do
      let(:name) { :rspec }
      let(:config) do
        { run: [{ name: 'step1', step: 'some reference' }] }
      end

      it { is_expected.to be_truthy }
    end

    context 'when config is a bridge job' do
      let(:name) { :rspec }
      let(:config) do
        { trigger: 'other-project' }
      end

      it { is_expected.to be_falsey }
    end

    context 'when config is a hidden job' do
      let(:name) { '.rspec' }
      let(:config) do
        { script: 'ls -al' }
      end

      it { is_expected.to be_falsey }
    end

    context 'when using the default job without script' do
      let(:name) { :default }
      let(:config) do
        { before_script: "cd ${PROJ_DIR} " }
      end

      it { is_expected.to be_falsey }
    end

    context 'when using the default job with script' do
      let(:name) { :default }
      let(:config) do
        {
          before_script: "cd ${PROJ_DIR} ",
          script: "ls"
        }
      end

      it { is_expected.to be_truthy }
    end
  end

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when job name is empty' do
        let(:entry) { described_class.new(config, name: :"") }

        it 'reports error' do
          expect(entry.errors).to include "job name can't be blank"
        end
      end

      context 'when config uses both "when:" and "rules:"' do
        let(:config) do
          {
            script: 'echo',
            when: 'on_failure',
            rules: [{ if: '$VARIABLE', when: 'on_success' }]
          }
        end

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when delayed job' do
        context 'when start_in is specified' do
          let(:config) { { script: 'echo', when: 'delayed', start_in: '1 week' } }

          it { expect(entry).to be_valid }
        end
      end

      context 'when has needs' do
        let(:config) do
          {
            stage: 'test',
            script: 'echo',
            needs: ['another-job']
          }
        end

        it { expect(entry).to be_valid }

        it "returns scheduling_type as :dag" do
          expect(entry.value[:scheduling_type]).to eq(:dag)
        end

        context 'when has dependencies' do
          let(:config) do
            {
              stage: 'test',
              script: 'echo',
              dependencies: ['another-job'],
              needs: ['another-job']
            }
          end

          it { expect(entry).to be_valid }
        end

        context 'when it is a release' do
          let(:config) do
            {
              script: ["make changelog | tee release_changelog.txt"],
              release: {
                tag_name: "v0.06",
                name: "Release $CI_TAG_NAME",
                description: "./release_changelog.txt"
              }
            }
          end

          it { expect(entry).to be_valid }
        end
      end

      context 'when rules are used' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, rules: rules } }

        let(:rules) do
          [
            { if: '$CI_PIPELINE_SOURCE == "schedule"', when: 'never' },
            [
              { if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH' },
              { if: '$CI_PIPELINE_SOURCE == "merge_request_event"' }
            ]
          ]
        end

        it { expect(entry).to be_valid }
      end
    end

    context 'when entry value is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'reports error about a config type' do
            expect(entry.errors)
              .to include 'job config should be a hash'
          end
        end
      end

      context 'when config is empty' do
        let(:config) { {} }

        describe '#valid' do
          it 'is invalid' do
            expect(entry).not_to be_valid
          end
        end
      end

      context 'when unknown keys detected' do
        let(:config) { { unknown: true } }

        describe '#valid' do
          it 'is not valid' do
            expect(entry).not_to be_valid
          end
        end
      end

      context 'when script and run are used together' do
        let(:config) { { script: 'rspec', run: [{ name: 'step1', step: 'some reference' }] } }

        it 'returns error about using script and run' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'job config these keys cannot be used together: script, run'
        end
      end

      context 'when run value is invalid' do
        using RSpec::Parameterized::TableSyntax

        where(:case_name, :config, :error) do
          'when only step is used without name' | {
            stage: 'build',
            run: [{ step: 'some reference' }]
          } | 'job run object at `/0` is missing required properties: name'

          'when only script is used without name' | {
            stage: 'build',
            run: [{ script: 'echo' }]
          } | 'job run object at `/0` is missing required properties: name'

          'when step and script are used together' | {
            stage: 'build',
            run: [{
              name: 'step1',
              step: 'some reference',
              script: 'echo'
            }]
          } | 'job run object property at `/0/script` is a disallowed additional property'

          'when a required subkey is missing' | {
            stage: 'build',
            run: [{ name: 'step1' }]
          } | 'job run object at `/0` is missing required properties: step'

          'when a subkey is invalid' | {
            stage: 'build',
            run: [{ name: 'step1', step: 'some step', invalid_key: 'some value' }]
          } | 'job run object property at `/0/invalid_key` is a disallowed additional property'
        end

        with_them do
          it 'returns error about invalid run' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include(error)
          end
        end

        context 'when run value is not an array' do
          let(:config) { { stage: 'build', run: 'invalid' } }

          it 'returns error about invalid run' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job run value at root is not an array'
          end
        end

        context 'with invalid env value type' do
          let(:config) do
            {
              stage: 'build',
              run: [
                {
                  name: 'step1',
                  script: 'echo $MY_VAR',
                  env: { MY_VAR: 123 }
                }
              ]
            }
          end

          it 'returns error about invalid env' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job run value at `/0/env/my_var` is not a string'
          end
        end

        context 'when run value does not match steps schema' do
          let(:config) { { stage: 'build', run: [{ name: 'step1' }] } }

          it 'returns error about invalid run' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job run object at `/0` is missing required properties: step'
          end
        end
      end

      context 'when script is not provided' do
        let(:config) { { stage: 'test' } }

        it 'returns error about missing script entry' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'job script can\'t be blank'
        end
      end

      context 'when extends key is not a string' do
        let(:config) { { extends: 123 } }

        it 'returns error about wrong value type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'job extends should be an array of strings or a string'
        end
      end

      context 'when parallel value is not correct' do
        context 'when it is not a numeric value' do
          let(:config) { { script: 'echo', parallel: true } }

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'parallel should be an integer or a hash'
          end
        end

        context 'when it is lower than one' do
          let(:config) { { script: 'echo', parallel: 0 } }

          it 'returns error about value too low' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'parallel config must be greater than or equal to 1'
          end
        end

        context 'when it is an empty hash' do
          let(:config) { { script: 'echo', parallel: {} } }

          it 'returns error about missing matrix' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'parallel config missing required keys: matrix'
          end
        end
      end

      context 'when delayed job' do
        context 'when start_in is specified' do
          let(:config) { { script: 'echo', when: 'delayed', start_in: '1 week' } }

          it { expect(entry).to be_valid }
        end

        context 'when start_in is empty' do
          let(:config) { { when: 'delayed', start_in: nil } }

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job start in should be a duration'
          end
        end

        context 'when start_in is not formatted as a duration' do
          let(:config) { { when: 'delayed', start_in: 'test' } }

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job start in should be a duration'
          end
        end

        context 'when start_in is longer than one week' do
          let(:config) { { when: 'delayed', start_in: '8 days' } }

          it 'returns error about exceeding the limit' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job start in should not exceed the limit'
          end
        end
      end

      context 'when the `when` keyword is not a string' do
        context 'when it is an array' do
          let(:config) { { script: 'exit 0', when: ['always'] } }

          it 'returns error' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job when should be a string'
          end
        end

        context 'when it is a boolean' do
          let(:config) { { script: 'exit 0', when: true } }

          it 'returns error' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job when should be a string'
          end
        end
      end

      context 'when start_in specified without delayed specification' do
        let(:config) { { start_in: '1 day' } }

        it 'returns error about invalid type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'job start in must be blank'
        end
      end

      context 'when it has dependencies' do
        context 'that are not a array of strings' do
          let(:config) do
            { script: 'echo', dependencies: 'build-job' }
          end

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job dependencies should be an array of strings'
          end
        end
      end

      context 'when the job has needs' do
        context 'and there are dependencies that are not included in needs' do
          let(:config) do
            {
              stage: 'test',
              script: 'echo',
              dependencies: ['another-job'],
              needs: ['build-job']
            }
          end

          it 'returns error about invalid data' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job dependencies the another-job should be part of needs'
          end

          context 'and they are only cross pipeline needs' do
            let(:config) do
              {
                script: 'echo',
                dependencies: ['rspec'],
                needs: [{
                  job: 'rspec',
                  pipeline: 'other'
                }]
              }
            end

            it 'adds an error for dependency keyword usage' do
              expect(entry).not_to be_valid
              expect(entry.errors).to include 'job needs corresponding to dependencies must be from the same pipeline'
            end
          end
        end
      end

      context 'when timeout value is not correct' do
        context 'when it is higher than instance wide timeout' do
          let(:config) { { timeout: '3 months', script: 'test' } }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include "timeout config should not exceed the limit"
          end
        end

        context 'when it is not a duration' do
          let(:config) { { timeout: 100, script: 'test' } }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'timeout config should be a duration'
          end
        end
      end

      context 'when timeout value is correct' do
        let(:config) { { script: 'echo', timeout: '1m 1s' } }

        it 'returns correct timeout' do
          expect(entry).to be_valid
          expect(entry.errors).to be_empty
          expect(entry.timeout).to eq('1m 1s')
        end
      end

      context 'when it is a release' do
        context 'when `release:description` is missing' do
          let(:config) do
            {
              script: ["make changelog | tee release_changelog.txt"],
              release: {
                tag_name: "v0.06",
                name: "Release $CI_TAG_NAME"
              }
            }
          end

          it "returns error" do
            expect(entry).not_to be_valid
            expect(entry.errors).to include "release description can't be blank"
          end
        end
      end

      context 'when invalid rules are used' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, rules: rules } }

        context 'with rules nested more than max allowed levels' do
          let(:sample_rule) { { if: '$THIS == "other"', when: 'always' } }

          let(:rules) do
            [
              { if: '$THIS == "that"', when: 'always' },
              [
                { if: '$SKIP', when: 'never' },
                [
                  sample_rule,
                  [
                    sample_rule,
                    [
                      sample_rule,
                      [
                        sample_rule,
                        [
                          sample_rule,
                          [
                            sample_rule,
                            [
                              sample_rule,
                              [
                                sample_rule,
                                [
                                  sample_rule,
                                  [
                                    sample_rule,
                                    [sample_rule]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          end

          it { expect(entry).not_to be_valid }
        end

        context 'with rules with invalid keys' do
          let(:rules) do
            [
              { invalid_key: 'invalid' },
              [
                { if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH' },
                { if: '$CI_PIPELINE_SOURCE == "merge_request_event"' }
              ]
            ]
          end

          it { expect(entry).not_to be_valid }
        end
      end
    end

    context 'when only: is used with rules:' do
      let(:config) { { only: ['merge_requests'], rules: [{ if: '$THIS' }], script: 'echo' } }

      it 'returns error about mixing only: with rules:' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include(/may not be used with `rules`: only/)
      end

      context 'and only: is blank' do
        let(:config) { { only: nil, rules: [{ if: '$THIS' }], script: 'echo' } }

        it 'is valid:' do
          expect(entry).to be_valid
        end
      end

      context 'and rules: is blank' do
        let(:config) { { only: ['merge_requests'], rules: nil, script: 'echo' } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when except: is used with rules:' do
      let(:config) { { except: { refs: %w[master] }, rules: [{ if: '$THIS' }], script: 'echo' } }

      it 'returns error about mixing except: with rules:' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include(/may not be used with `rules`: except/)
      end

      context 'and except: is blank' do
        let(:config) { { except: nil, rules: [{ if: '$THIS' }], script: 'echo' } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'and rules: is blank' do
        let(:config) { { except: { refs: %w[master] }, rules: nil, script: 'echo' } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when only: and except: are both used with rules:' do
      let(:config) do
        {
          only: %w[merge_requests],
          except: { refs: %w[master] },
          rules: [{ if: '$THIS' }],
          script: 'echo'
        }
      end

      it 'returns errors about mixing both only: and except: with rules:' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include(/may not be used with `rules`: only, except/)
      end

      context 'when only: and except: as both blank' do
        let(:config) do
          { only: nil, except: nil, rules: [{ if: '$THIS' }], script: 'echo' }
        end

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when rules: is blank' do
        let(:config) do
          { only: %w[merge_requests], except: { refs: %w[master] }, rules: nil, script: 'echo' }
        end

        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when job is not a pages job', feature_category: :pages do
      let(:name) { :rspec }

      context 'if the config contains a publish entry' do
        let(:entry) { described_class.new({ script: 'echo', publish: 'foo' }, name: name) }

        it 'is invalid' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include(/job publish can only be used within a `pages` job/)
        end
      end
    end

    context 'when job is a job named pages', feature_category: :pages do
      let(:name) { :pages }

      context 'when it does not have a publish entry' do
        let(:entry) { described_class.new({ script: 'echo' }, name: name) }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it has a publish entry' do
        let(:entry) { described_class.new({ script: 'echo', publish: 'foo' }, name: name) }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it has a pages entry' do
        let(:entry) { described_class.new({ script: 'echo', pages: { path_prefix: 'foo' } }, name: name) }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when job is a pages job with a custom name', feature_category: :pages do
      let(:name) { :rspec }

      context 'when pages entry is a boolean' do
        let(:entry) { described_class.new({ script: 'echo', pages: true }, name: name) }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when pages entry is a hash' do
        let(:entry) { described_class.new({ script: 'echo', pages: { path_prefix: 'foo' } }, name: name) }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it has a publish entry' do
        let(:entry) { described_class.new({ script: 'echo', pages: true, publish: 'foo' }, name: name) }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end
  end

  describe '#pages_job?', :aggregate_failures, feature_category: :pages do
    where(:name, :config, :result) do
      :pages | {} | true
      :pages | { pages: false } | false
      :pages | { pages: true } | true
      :pages | { pages: nil } | true
      :pages | { pages: { path_prefix: 'foo' } } | true
      :'pages:staging' | {} | false
      :'something:pages:else' | {} | false
      :'something-else' | {} | false
      :'something-else' | { pages: true } | true
      :'something-else' | { pages: { path_prefix: 'foo' } } | true
      :'something-else' | { pages: { publish: '/some-folder' } } | true
      :'something-else' | { pages: false } | false
      :'something-else' | { pages: nil } | false
    end

    with_them do
      subject { described_class.new(config, name: name).pages_job? }

      it { is_expected.to eq(result) }
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      entry = described_class.new({ script: 'rspec' }, name: :rspec)

      expect(entry).to be_relevant
    end
  end

  describe '#compose!' do
    let(:specified) do
      double('specified', 'specified?' => true, value: 'specified')
    end

    let(:unspecified) { double('unspecified', 'specified?' => false) }
    let(:default) { double('default', '[]' => unspecified) }
    let(:workflow) { double('workflow', 'has_rules?' => false) }

    let(:deps) do
      double('deps',
        'default_entry' => default,
        'workflow_entry' => workflow)
    end

    context 'when job config overrides default config' do
      before do
        entry.compose!(deps)
      end

      let(:config) do
        { script: 'rspec', image: 'some_image', cache: { key: 'test' } }
      end

      it 'overrides default config' do
        expect(entry[:image].value).to eq(name: 'some_image')
        expect(entry[:cache].value).to match_array([
          key: 'test',
          policy: 'pull-push',
          when: 'on_success',
          unprotect: false,
          fallback_keys: []
        ])
      end
    end

    context 'when job config does not override default config' do
      before do
        allow(default).to receive('[]').with(:image).and_return(specified)

        entry.compose!(deps)
      end

      let(:config) { { script: 'ls', cache: { key: 'test' } } }

      it 'uses config from default entry' do
        expect(entry[:image].value).to eq 'specified'
        expect(entry[:cache].value).to match_array([
          key: 'test',
          policy: 'pull-push',
          when: 'on_success',
          unprotect: false,
          fallback_keys: []
        ])
      end
    end

    context 'with workflow rules' do
      where(:name, :has_workflow_rules?, :only, :rules, :result) do
        "uses default only"    | false | nil          | nil    | { refs: %w[branches tags] }
        "uses user only"       | false | %w[branches] | nil    | { refs: %w[branches] }
        "does not define only" | false | nil          | []     | nil
        "does not define only" | true  | nil          | nil    | nil
        "uses user only"       | true  | %w[branches] | nil    | { refs: %w[branches] }
        "does not define only" | true  | nil          | []     | nil
      end

      with_them do
        let(:config) { { script: 'ls', rules: rules, only: only }.compact }

        it name.to_s do
          expect(workflow).to receive(:has_rules?) { has_workflow_rules? }

          entry.compose!(deps)

          expect(entry.only_value).to eq(result)
        end
      end
    end

    context 'when workflow rules is used' do
      context 'when rules are used' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, rules: [] } }

        it 'does not define only' do
          expect(entry).not_to be_only_defined
        end
      end

      context 'when rules are not used' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, only: [] } }

        it 'does not define only' do
          expect(entry).not_to be_only_defined
        end
      end
    end
  end

  context 'when composed' do
    before do
      entry.compose!
    end

    describe '#value' do
      before do
        entry.compose!
      end

      context 'when entry is correct' do
        let(:config) do
          { before_script: %w[ls pwd],
            script: 'rspec',
            after_script: %w[cleanup],
            id_tokens: { TEST_ID_TOKEN: { aud: 'https://gitlab.com' } },
            hooks: { pre_get_sources_script: 'echo hello' } }
        end

        it 'returns correct values' do
          expect(entry.value).to eq(
            name: :rspec,
            before_script: %w[ls pwd],
            script: %w[rspec],
            stage: 'test',
            ignore: false,
            after_script: %w[cleanup],
            hooks: { pre_get_sources_script: ['echo hello'] },
            only: { refs: %w[branches tags] },
            job_variables: {},
            root_variables_inheritance: true,
            scheduling_type: :stage,
            id_tokens: { TEST_ID_TOKEN: { aud: 'https://gitlab.com' } }
          )
        end
      end

      context 'when run keyword is used' do
        let(:run_value) do
          [
            { name: 'step1', step: 'some reference' },
            { name: 'step2', script: 'echo' }
          ]
        end

        let(:config) { { run: run_value } }

        it 'returns the run value' do
          expect(entry.value).to include({ run: run_value })
        end

        context 'with valid inputs' do
          let(:config) do
            {
              stage: 'build',
              run: [
                {
                  name: 'step1',
                  script: 'echo ${{env.MY_ENV}}',
                  env: { MY_ENV: 'some value' }
                }
              ]
            }
          end

          it 'is valid' do
            expect(entry).to be_valid
          end

          context 'with valid env key' do
            let(:config) do
              {
                stage: 'build',
                run: [
                  {
                    name: 'step1',
                    script: 'echo $MY_VAR',
                    env: { MY_VAR: 'some value' }
                  }
                ]
              }
            end

            it 'is valid' do
              expect(entry).to be_valid
            end
          end
        end
      end

      context 'with retry present in the config' do
        let(:config) do
          {
            script: 'rspec',
            retry: { max: 1, when: "always" }
          }
        end

        it 'returns correct values' do
          expect(entry.value)
            .to eq(name: :rspec,
              script: %w[rspec],
              stage: 'test',
              ignore: false,
              retry: { max: 1, when: %w[always] },
              only: { refs: %w[branches tags] },
              job_variables: {},
              root_variables_inheritance: true,
              scheduling_type: :stage
            )
        end

        context 'with exit_codes present' do
          let(:config) do
            {
              script: 'rspec',
              retry: { max: 1, when: "always", exit_codes: 255 }
            }
          end

          it 'returns correct values' do
            expect(entry.value)
              .to eq(name: :rspec,
                script: %w[rspec],
                stage: 'test',
                ignore: false,
                retry: { max: 1, when: %w[always], exit_codes: [255] },
                only: { refs: %w[branches tags] },
                job_variables: {},
                root_variables_inheritance: true,
                scheduling_type: :stage
              )
          end
        end
      end
    end

    context 'when job is using tags' do
      context 'when limit is reached' do
        let(:tags) { Array.new(100) { |i| "tag-#{i}" } }
        let(:config) { { tags: tags, script: 'test' } }

        it 'returns error', :aggregate_failures do
          expect(entry).not_to be_valid
          expect(entry.errors)
            .to include "tags config must be less than the limit of #{Gitlab::Ci::Config::Entry::Tags::TAGS_LIMIT} tags"
        end
      end

      context 'when limit is not reached' do
        let(:config) { { tags: %w[tag1 tag2], script: 'test' } }

        it 'returns a valid entry', :aggregate_failures do
          expect(entry).to be_valid
          expect(entry.errors).to be_empty
          expect(entry.tags).to eq(%w[tag1 tag2])
        end
      end
    end
  end

  describe '#manual_action?' do
    context 'when job is a manual action' do
      let(:config) { { script: 'deploy', when: 'manual' } }

      it 'is a manual action' do
        expect(entry).to be_manual_action
      end
    end

    context 'when job is not a manual action' do
      let(:config) { { script: 'deploy' } }

      it 'is not a manual action' do
        expect(entry).not_to be_manual_action
      end
    end
  end

  describe '#delayed?' do
    context 'when job is a delayed' do
      let(:config) { { script: 'deploy', when: 'delayed' } }

      it 'is a delayed' do
        expect(entry).to be_delayed
      end
    end

    context 'when job is not a delayed' do
      let(:config) { { script: 'deploy' } }

      it 'is not a delayed' do
        expect(entry).not_to be_delayed
      end
    end
  end

  describe '#ignored?' do
    before do
      entry.compose!
    end

    context 'when job is a manual action' do
      context 'when it is not specified if job is allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual' }
        end

        it 'is an ignored job' do
          expect(entry).to be_ignored
        end
      end

      context 'when job is allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual', allow_failure: true }
        end

        it 'is an ignored job' do
          expect(entry).to be_ignored
        end
      end

      context 'when job is not allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual', allow_failure: false }
        end

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end
      end

      context 'when job is dynamically allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual', allow_failure: { exit_codes: 42 } }
        end

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end
      end
    end

    context 'when job is not a manual action' do
      context 'when it is not specified if job is allowed to fail' do
        let(:config) { { script: 'deploy' } }

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end

        it 'does not return allow_failure' do
          expect(entry.value.key?(:allow_failure_criteria)).to be_falsey
        end
      end

      context 'when job is allowed to fail' do
        let(:config) { { script: 'deploy', allow_failure: true } }

        it 'is an ignored job' do
          expect(entry).to be_ignored
        end

        it 'does not return allow_failure_criteria' do
          expect(entry.value.key?(:allow_failure_criteria)).to be_falsey
        end
      end

      context 'when job is not allowed to fail' do
        let(:config) { { script: 'deploy', allow_failure: false } }

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end

        it 'does not return allow_failure_criteria' do
          expect(entry.value.key?(:allow_failure_criteria)).to be_falsey
        end
      end

      context 'when job is dynamically allowed to fail' do
        let(:config) { { script: 'deploy', allow_failure: { exit_codes: 42 } } }

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end

        it 'returns allow_failure_criteria' do
          expect(entry.value[:allow_failure_criteria]).to match(exit_codes: [42])
        end
      end
    end
  end
end
