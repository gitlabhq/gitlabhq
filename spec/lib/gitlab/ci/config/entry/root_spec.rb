# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Root do
  let(:user) {}
  let(:project) {}
  let(:logger) { Gitlab::Ci::Pipeline::Logger.new(project: project) }
  let(:root) { described_class.new(hash, user: user, project: project, logger: logger) }

  describe '.nodes' do
    it 'returns a hash' do
      expect(described_class.nodes).to be_a(Hash)
    end

    context 'when filtering all the entry/node names' do
      it 'contains the expected node names' do
        # No inheritable fields should be added to the `Root`
        #
        # Inheritable configuration can only be added to `default:`
        #
        # The purpose of `Root` is have only globally defined configuration.
        expect(described_class.nodes.keys)
          .to match_array(%i[before_script image services after_script
                             variables cache stages include default workflow])
      end
    end
  end

  context 'when configuration is valid' do
    context 'when top-level entries are defined' do
      let(:hash) do
        {
          before_script: %w[ls pwd],
          image: 'image:1.0',
          default: {},
          services: ['postgres:9.1', 'mysql:5.5'],
          variables: {
            VAR: 'root',
            VAR2: { value: 'val 2', description: 'this is var 2' },
            VAR3: { value: 'val3', options: %w[val3 val4 val5], description: 'this is var 3 and some options' }
          },
          after_script: ['make clean'],
          stages: %w[build pages release],
          cache: { key: 'k', untracked: true, paths: ['public/'] },
          rspec: { script: %w[rspec ls] },
          spinach: { before_script: [], variables: {}, script: 'spinach' },
          release: {
            stage: 'release',
            before_script: [],
            after_script: [],
            variables: { 'VAR' => 'job' },
            script: ["make changelog | tee release_changelog.txt"],
            release: {
              tag_name: 'v0.06',
              name: "Release $CI_TAG_NAME",
              description: "./release_changelog.txt"
            }
          }
        }
      end

      describe '#compose!' do
        before do
          root.compose!
        end

        it 'creates nodes hash' do
          expect(root.descendants).to be_an Array
        end

        it 'creates node object for each entry' do
          expect(root.descendants.count).to eq 11
        end

        it 'creates node object using valid class' do
          expect(root.descendants.first)
            .to be_an_instance_of Gitlab::Ci::Config::Entry::Default
          expect(root.descendants.second)
            .to be_an_instance_of Gitlab::Config::Entry::Unspecified
        end

        it 'sets correct description for nodes' do
          expect(root.descendants.first.description)
            .to eq 'Default configuration for all jobs.'
          expect(root.descendants.second.description)
            .to eq 'List of external YAML files to include.'
        end

        it 'sets correct variables value' do
          expect(root.variables_value).to eq('VAR' => 'root', 'VAR2' => 'val 2', 'VAR3' => 'val3')
        end

        describe '#leaf?' do
          it 'is not leaf' do
            expect(root).not_to be_leaf
          end
        end
      end

      context 'when composed' do
        before do
          root.compose!
        end

        describe '#errors' do
          it 'has no errors' do
            expect(root.errors).to be_empty
          end
        end

        describe '#stages_value' do
          context 'when stages key defined' do
            it 'returns array of stages' do
              expect(root.stages_value).to eq %w[build pages release]
            end
          end
        end

        describe '#jobs_value' do
          it 'returns jobs configuration' do
            expect(root.jobs_value.keys).to eq([:rspec, :spinach, :release])
            expect(root.jobs_value[:rspec]).to eq(
              { name: :rspec,
                script: %w[rspec ls],
                before_script: %w[ls pwd],
                image: { name: 'image:1.0' },
                services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                stage: 'test',
                cache: [{ key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push', when: 'on_success',
                          unprotect: false, fallback_keys: [] }],
                job_variables: {},
                root_variables_inheritance: true,
                ignore: false,
                after_script: ['make clean'],
                only: { refs: %w[branches tags] },
                scheduling_type: :stage }
            )
            expect(root.jobs_value[:spinach]).to eq(
              { name: :spinach,
                before_script: [],
                script: %w[spinach],
                image: { name: 'image:1.0' },
                services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                stage: 'test',
                cache: [{ key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push', when: 'on_success',
                          unprotect: false, fallback_keys: [] }],
                job_variables: {},
                root_variables_inheritance: true,
                ignore: false,
                after_script: ['make clean'],
                only: { refs: %w[branches tags] },
                scheduling_type: :stage }
            )
            expect(root.jobs_value[:release]).to eq(
              { name: :release,
                stage: 'release',
                before_script: [],
                script: ["make changelog | tee release_changelog.txt"],
                release: { name: "Release $CI_TAG_NAME", tag_name: 'v0.06', description: "./release_changelog.txt" },
                image: { name: "image:1.0" },
                services: [{ name: "postgres:9.1" }, { name: "mysql:5.5" }],
                cache: [{ key: "k", untracked: true, paths: ["public/"], policy: "pull-push", when: 'on_success',
                          unprotect: false, fallback_keys: [] }],
                only: { refs: %w[branches tags] },
                job_variables: { 'VAR' => { value: 'job' } },
                root_variables_inheritance: true,
                after_script: [],
                ignore: false,
                scheduling_type: :stage }
            )
          end
        end
      end
    end

    context 'when a mix of top-level and default entries is used' do
      let(:hash) do
        { before_script: %w[ls pwd],
          after_script: ['make clean'],
          default: {
            image: 'image:1.0',
            services: ['postgres:9.1', 'mysql:5.5']
          },
          variables: { VAR: 'root' },
          stages: %w[build pages],
          cache: { key: 'k', untracked: true, paths: ['public/'] },
          rspec: { script: %w[rspec ls] },
          spinach: { before_script: [], variables: { VAR: 'job' }, script: 'spinach' } }
      end

      context 'when composed' do
        before do
          root.compose!
        end

        describe '#errors' do
          it 'has no errors' do
            expect(root.errors).to be_empty
          end
        end

        describe '#jobs_value' do
          it 'returns jobs configuration' do
            expect(root.jobs_value).to eq(
              rspec: { name: :rspec,
                       script: %w[rspec ls],
                       before_script: %w[ls pwd],
                       image: { name: 'image:1.0' },
                       services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                       stage: 'test',
                       cache: [{ key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push', when: 'on_success', unprotect: false, fallback_keys: [] }],
                       job_variables: {},
                       root_variables_inheritance: true,
                       ignore: false,
                       after_script: ['make clean'],
                       only: { refs: %w[branches tags] },
                       scheduling_type: :stage },
              spinach: { name: :spinach,
                         before_script: [],
                         script: %w[spinach],
                         image: { name: 'image:1.0' },
                         services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                         stage: 'test',
                         cache: [{ key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push', when: 'on_success', unprotect: false, fallback_keys: [] }],
                         job_variables: { 'VAR' => { value: 'job' } },
                         root_variables_inheritance: true,
                         ignore: false,
                         after_script: ['make clean'],
                         only: { refs: %w[branches tags] },
                         scheduling_type: :stage }
            )
          end
        end

        it 'tracks log entries' do
          expect(logger.observations_hash).to match(
            a_hash_including(
              'config_root_compose_jobs_factory_duration_s' => a_kind_of(Numeric)
            )
          )
        end
      end
    end

    context 'when most of entires not defined' do
      before do
        root.compose!
      end

      let(:hash) do
        { cache: { key: 'a' }, rspec: { script: %w[ls] } }
      end

      describe '#nodes' do
        it 'instantizes all nodes' do
          expect(root.descendants.count).to eq 11
        end

        it 'contains unspecified nodes' do
          expect(root.descendants.first)
            .not_to be_specified
        end
      end

      describe '#variables_value' do
        it 'returns root value for variables' do
          expect(root.variables_value).to eq({})
        end
      end

      describe '#stages_value' do
        it 'returns an array of root stages' do
          expect(root.stages_value).to eq %w[.pre build test deploy .post]
        end
      end

      describe '#cache_value' do
        it 'returns correct cache definition' do
          expect(root.cache_value).to match_array([
            key: 'a',
            policy: 'pull-push',
            when: 'on_success',
            unprotect: false,
            fallback_keys: []
          ])
        end
      end
    end

    context 'when variables resembles script-type job' do
      before do
        root.compose!
      end

      let(:hash) do
        {
          variables: { script: "ENV_VALUE" },
          rspec: { script: "echo Hello World" }
        }
      end

      describe '#variables_value' do
        it 'returns root value for variables' do
          expect(root.variables_value).to eq("script" => "ENV_VALUE")
        end
      end

      describe '#jobs_value' do
        it 'returns one job' do
          expect(root.jobs_value.keys).to contain_exactly(:rspec)
        end
      end
    end

    ##
    # When nodes are specified but not defined, we assume that
    # configuration is valid, and we assume that entry is simply undefined,
    # despite the fact, that key is present. See issue #18775 for more
    # details.
    #
    context 'when entries are specified but not defined' do
      before do
        root.compose!
      end

      let(:hash) do
        { variables: nil, rspec: { script: 'rspec' } }
      end

      describe '#variables_value' do
        it 'undefined entry returns a root value' do
          expect(root.variables_value).to eq({})
        end
      end
    end

    context 'when variables have `options` data' do
      before do
        root.compose!
      end

      context 'and the value is in the `options` array' do
        let(:hash) do
          {
            variables: { 'VAR' => { value: 'val1', options: %w[val1 val2] } },
            rspec: { script: 'bin/rspec' }
          }
        end

        it 'returns correct value' do
          expect(root.variables_entry.value_with_data).to eq(
            'VAR' => { value: 'val1' }
          )

          expect(root.variables_value).to eq('VAR' => 'val1')
        end
      end

      context 'and the value is not in the `options` array' do
        let(:hash) do
          {
            variables: { 'VAR' => { value: 'val', options: %w[val1 val2] } },
            rspec: { script: 'bin/rspec' }
          }
        end

        it 'returns an error' do
          expect(root.errors).to contain_exactly('variables:var config value must be present in options')
        end
      end
    end

    context 'when variables have "expand" data' do
      let(:hash) do
        {
          variables: { 'VAR1' => 'val 1',
                       'VAR2' => { value: 'val 2', expand: false },
                       'VAR3' => { value: 'val 3', expand: true } },
          rspec: { script: 'rspec' }
        }
      end

      before do
        root.compose!
      end

      it 'returns correct value' do
        expect(root.variables_entry.value_with_data).to eq(
          'VAR1' => { value: 'val 1' },
          'VAR2' => { value: 'val 2', raw: true },
          'VAR3' => { value: 'val 3', raw: false }
        )

        expect(root.variables_value).to eq(
          'VAR1' => 'val 1',
          'VAR2' => 'val 2',
          'VAR3' => 'val 3'
        )
      end
    end
  end

  context 'when configuration is not valid' do
    before do
      root.compose!
    end

    context 'when before script is a number' do
      let(:hash) do
        { before_script: 123 }
      end

      describe '#valid?' do
        it 'is not valid' do
          expect(root).not_to be_valid
        end
      end

      describe '#errors' do
        it 'reports errors from child nodes' do
          expect(root.errors)
            .to include 'before_script config should be a string or a nested array of strings up to 10 levels deep'
        end
      end
    end

    context 'when job does not have commands' do
      let(:hash) do
        { before_script: ['echo 123'], rspec: { stage: 'test' } }
      end

      describe '#errors' do
        it 'reports errors about missing script or trigger' do
          expect(root.errors)
            .to include 'jobs rspec config should implement the script:, run:, or trigger: keyword'
        end
      end
    end

    context 'when a variable has an invalid data key' do
      let(:hash) do
        { variables: { VAR1: { invalid: 'hello' } }, rspec: { script: 'hello' } }
      end

      describe '#errors' do
        it 'reports errors about the invalid variable' do
          expect(root.errors)
            .to include(/var1 config uses invalid data keys: invalid/)
        end
      end
    end
  end

  context 'when value is not a hash' do
    let(:hash) { [] }

    describe '#valid?' do
      it 'is not valid' do
        expect(root).not_to be_valid
      end
    end

    describe '#errors' do
      it 'returns error about invalid type' do
        expect(root.errors.first).to match(/should be a hash/)
      end
    end
  end

  describe '#specified?' do
    it 'is concrete entry that is defined' do
      expect(root.specified?).to be true
    end
  end

  describe '#[]' do
    before do
      root.compose!
    end

    let(:hash) do
      { cache: { key: 'a' }, rspec: { script: 'ls' } }
    end

    context 'when entry exists' do
      it 'returns correct entry' do
        expect(root[:cache])
          .to be_an_instance_of Gitlab::Ci::Config::Entry::Caches
        expect(root[:jobs][:rspec][:script].value).to eq ['ls']
      end
    end

    context 'when entry does not exist' do
      it 'always return unspecified node' do
        expect(root[:some][:unknown][:node])
          .not_to be_specified
      end
    end
  end
end
