# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Root do
  let(:root) { described_class.new(hash) }

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
                             variables cache stages types include default workflow])
      end
    end
  end

  context 'when configuration is valid' do
    context 'when top-level entries are defined' do
      let(:hash) do
        {
          before_script: %w(ls pwd),
          image: 'ruby:2.2',
          default: {},
          services: ['postgres:9.1', 'mysql:5.5'],
          variables: { VAR: 'value' },
          after_script: ['make clean'],
          stages: %w(build pages release),
          cache: { key: 'k', untracked: true, paths: ['public/'] },
          rspec: { script: %w[rspec ls] },
          spinach: { before_script: [], variables: {}, script: 'spinach' },
          release: {
            stage: 'release',
            before_script: [],
            after_script: [],
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

          context 'when deprecated types key defined' do
            let(:hash) do
              { types: %w(test deploy),
                rspec: { script: 'rspec' } }
            end

            it 'returns array of types as stages' do
              expect(root.stages_value).to eq %w[test deploy]
            end
          end
        end

        describe '#jobs_value' do
          it 'returns jobs configuration' do
            expect(root.jobs_value.keys).to eq([:rspec, :spinach, :release])
            expect(root.jobs_value[:rspec]).to eq(
              { name: :rspec,
                       script: %w[rspec ls],
                       before_script: %w(ls pwd),
                       image: { name: 'ruby:2.2' },
                       services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                       stage: 'test',
                       cache: { key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push' },
                       variables: {},
                       ignore: false,
                       after_script: ['make clean'],
                       only: { refs: %w[branches tags] } }
            )
            expect(root.jobs_value[:spinach]).to eq(
              { name: :spinach,
                         before_script: [],
                         script: %w[spinach],
                         image: { name: 'ruby:2.2' },
                         services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                         stage: 'test',
                         cache: { key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push' },
                         variables: {},
                         ignore: false,
                         after_script: ['make clean'],
                         only: { refs: %w[branches tags] } }
            )
            expect(root.jobs_value[:release]).to eq(
              { name: :release,
                         stage: 'release',
                         before_script: [],
                         script: ["make changelog | tee release_changelog.txt"],
                         release: { name: "Release $CI_TAG_NAME", tag_name: 'v0.06', description: "./release_changelog.txt" },
                         image: { name: "ruby:2.2" },
                         services: [{ name: "postgres:9.1" }, { name: "mysql:5.5" }],
                         cache: { key: "k", untracked: true, paths: ["public/"], policy: "pull-push" },
                         only: { refs: %w(branches tags) },
                         variables: {},
                         after_script: [],
                         ignore: false }
            )
          end
        end
      end
    end

    context 'when a mix of top-level and default entries is used' do
      let(:hash) do
        { before_script: %w(ls pwd),
          after_script: ['make clean'],
          default: {
            image: 'ruby:2.1',
            services: ['postgres:9.1', 'mysql:5.5']
          },
          variables: { VAR: 'value' },
          stages: %w(build pages),
          cache: { key: 'k', untracked: true, paths: ['public/'] },
          rspec: { script: %w[rspec ls] },
          spinach: { before_script: [], variables: { VAR: 'AA' }, script: 'spinach' } }
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
                       before_script: %w(ls pwd),
                       image: { name: 'ruby:2.1' },
                       services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                       stage: 'test',
                       cache: { key: 'k', untracked: true, paths: ['public/'], policy: "pull-push" },
                       variables: {},
                       ignore: false,
                       after_script: ['make clean'],
                       only: { refs: %w[branches tags] } },
              spinach: { name: :spinach,
                         before_script: [],
                         script: %w[spinach],
                         image: { name: 'ruby:2.1' },
                         services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                         stage: 'test',
                         cache: { key: 'k', untracked: true, paths: ['public/'], policy: "pull-push" },
                         variables: { 'VAR' => 'AA' },
                         ignore: false,
                         after_script: ['make clean'],
                         only: { refs: %w[branches tags] } }
            )
          end
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
          expect(root.cache_value).to eq(key: 'a', policy: 'pull-push')
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
  end

  context 'when configuration is not valid' do
    before do
      root.compose!
    end

    context 'when before script is not an array' do
      let(:hash) do
        { before_script: 'ls' }
      end

      describe '#valid?' do
        it 'is not valid' do
          expect(root).not_to be_valid
        end
      end

      describe '#errors' do
        it 'reports errors from child nodes' do
          expect(root.errors)
            .to include 'before_script config should be an array containing strings and arrays of strings'
        end
      end
    end

    context 'when job does not have commands' do
      let(:hash) do
        { before_script: ['echo 123'], rspec: { stage: 'test' } }
      end

      describe '#errors' do
        it 'reports errors about missing script' do
          expect(root.errors)
            .to include "root config contains unknown keys: rspec"
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
        expect(root.errors.first).to match /should be a hash/
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
          .to be_an_instance_of Gitlab::Ci::Config::Entry::Cache
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
