require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Global do
  let(:global) { described_class.new(hash) }

  describe '.nodes' do
    it 'returns a hash' do
      expect(described_class.nodes).to be_a(Hash)
    end

    context 'when filtering all the entry/node names' do
      it 'contains the expected node names' do
        expect(described_class.nodes.keys)
          .to match_array(%i[before_script image services
                             after_script variables stages
                             types cache])
      end
    end
  end

  context 'when configuration is valid' do
    context 'when some entries defined' do
      let(:hash) do
        { before_script: %w(ls pwd),
          image: 'ruby:2.2',
          services: ['postgres:9.1', 'mysql:5.5'],
          variables: { VAR: 'value' },
          after_script: ['make clean'],
          stages: %w(build pages),
          cache: { key: 'k', untracked: true, paths: ['public/'] },
          rspec: { script: %w[rspec ls] },
          spinach: { before_script: [], variables: {}, script: 'spinach' } }
      end

      describe '#compose!' do
        before do
          global.compose!
        end

        it 'creates nodes hash' do
          expect(global.descendants).to be_an Array
        end

        it 'creates node object for each entry' do
          expect(global.descendants.count).to eq 8
        end

        it 'creates node object using valid class' do
          expect(global.descendants.first)
            .to be_an_instance_of Gitlab::Ci::Config::Entry::Script
          expect(global.descendants.second)
            .to be_an_instance_of Gitlab::Ci::Config::Entry::Image
        end

        it 'sets correct description for nodes' do
          expect(global.descendants.first.description)
            .to eq 'Script that will be executed before each job.'
          expect(global.descendants.second.description)
            .to eq 'Docker image that will be used to execute jobs.'
        end

        describe '#leaf?' do
          it 'is not leaf' do
            expect(global).not_to be_leaf
          end
        end
      end

      context 'when not composed' do
        describe '#before_script_value' do
          it 'returns nil' do
            expect(global.before_script_value).to be nil
          end
        end

        describe '#leaf?' do
          it 'is leaf' do
            expect(global).to be_leaf
          end
        end
      end

      context 'when composed' do
        before do
          global.compose!
        end

        describe '#errors' do
          it 'has no errors' do
            expect(global.errors).to be_empty
          end
        end

        describe '#before_script_value' do
          it 'returns correct script' do
            expect(global.before_script_value).to eq %w(ls pwd)
          end
        end

        describe '#image_value' do
          it 'returns valid image' do
            expect(global.image_value).to eq(name: 'ruby:2.2')
          end
        end

        describe '#services_value' do
          it 'returns array of services' do
            expect(global.services_value).to eq [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }]
          end
        end

        describe '#after_script_value' do
          it 'returns after script' do
            expect(global.after_script_value).to eq ['make clean']
          end
        end

        describe '#variables_value' do
          it 'returns variables' do
            expect(global.variables_value).to eq('VAR' => 'value')
          end
        end

        describe '#stages_value' do
          context 'when stages key defined' do
            it 'returns array of stages' do
              expect(global.stages_value).to eq %w[build pages]
            end
          end

          context 'when deprecated types key defined' do
            let(:hash) do
              { types: %w(test deploy),
                rspec: { script: 'rspec' } }
            end

            it 'returns array of types as stages' do
              expect(global.stages_value).to eq %w[test deploy]
            end
          end
        end

        describe '#cache_value' do
          it 'returns cache configuration' do
            expect(global.cache_value)
              .to eq(key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push')
          end
        end

        describe '#jobs_value' do
          it 'returns jobs configuration' do
            expect(global.jobs_value).to eq(
              rspec: { name: :rspec,
                       script: %w[rspec ls],
                       before_script: %w(ls pwd),
                       commands: "ls\npwd\nrspec\nls",
                       image: { name: 'ruby:2.2' },
                       services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                       stage: 'test',
                       cache: { key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push' },
                       variables: { 'VAR' => 'value' },
                       ignore: false,
                       after_script: ['make clean'] },
              spinach: { name: :spinach,
                         before_script: [],
                         script: %w[spinach],
                         commands: 'spinach',
                         image: { name: 'ruby:2.2' },
                         services: [{ name: 'postgres:9.1' }, { name: 'mysql:5.5' }],
                         stage: 'test',
                         cache: { key: 'k', untracked: true, paths: ['public/'], policy: 'pull-push' },
                         variables: {},
                         ignore: false,
                         after_script: ['make clean'] }
            )
          end
        end
      end
    end

    context 'when most of entires not defined' do
      before do
        global.compose!
      end

      let(:hash) do
        { cache: { key: 'a' }, rspec: { script: %w[ls] } }
      end

      describe '#nodes' do
        it 'instantizes all nodes' do
          expect(global.descendants.count).to eq 8
        end

        it 'contains unspecified nodes' do
          expect(global.descendants.first)
            .not_to be_specified
        end
      end

      describe '#variables_value' do
        it 'returns default value for variables' do
          expect(global.variables_value).to eq({})
        end
      end

      describe '#stages_value' do
        it 'returns an array of default stages' do
          expect(global.stages_value).to eq %w[build test deploy]
        end
      end

      describe '#cache_value' do
        it 'returns correct cache definition' do
          expect(global.cache_value).to eq(key: 'a', policy: 'pull-push')
        end
      end
    end

    ##
    # When nodes are specified but not defined, we assume that
    # configuration is valid, and we asume that entry is simply undefined,
    # despite the fact, that key is present. See issue #18775 for more
    # details.
    #
    context 'when entires specified but not defined' do
      before do
        global.compose!
      end

      let(:hash) do
        { variables: nil, rspec: { script: 'rspec' } }
      end

      describe '#variables_value' do
        it 'undefined entry returns a default value' do
          expect(global.variables_value).to eq({})
        end
      end
    end
  end

  context 'when configuration is not valid' do
    before do
      global.compose!
    end

    context 'when before script is not an array' do
      let(:hash) do
        { before_script: 'ls' }
      end

      describe '#valid?' do
        it 'is not valid' do
          expect(global).not_to be_valid
        end
      end

      describe '#errors' do
        it 'reports errors from child nodes' do
          expect(global.errors)
            .to include 'before_script config should be an array of strings'
        end
      end

      describe '#before_script_value' do
        it 'returns nil' do
          expect(global.before_script_value).to be_nil
        end
      end
    end

    context 'when job does not have commands' do
      let(:hash) do
        { before_script: ['echo 123'], rspec: { stage: 'test' } }
      end

      describe '#errors' do
        it 'reports errors about missing script' do
          expect(global.errors)
            .to include "jobs:rspec script can't be blank"
        end
      end
    end
  end

  context 'when value is not a hash' do
    let(:hash) { [] }

    describe '#valid?' do
      it 'is not valid' do
        expect(global).not_to be_valid
      end
    end

    describe '#errors' do
      it 'returns error about invalid type' do
        expect(global.errors.first).to match /should be a hash/
      end
    end
  end

  describe '#specified?' do
    it 'is concrete entry that is defined' do
      expect(global.specified?).to be true
    end
  end

  describe '#[]' do
    before do
      global.compose!
    end

    let(:hash) do
      { cache: { key: 'a' }, rspec: { script: 'ls' } }
    end

    context 'when entry exists' do
      it 'returns correct entry' do
        expect(global[:cache])
          .to be_an_instance_of Gitlab::Ci::Config::Entry::Cache
        expect(global[:jobs][:rspec][:script].value).to eq ['ls']
      end
    end

    context 'when entry does not exist' do
      it 'always return unspecified node' do
        expect(global[:some][:unknown][:node])
          .not_to be_specified
      end
    end
  end
end
