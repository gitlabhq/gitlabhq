require 'spec_helper'

describe Gitlab::Ci::Config::Node::Global do
  let(:global) { described_class.new(hash) }

  describe '.nodes' do
    it 'can contain global config keys' do
      expect(described_class.nodes).to include :before_script
    end

    it 'returns a hash' do
      expect(described_class.nodes).to be_a Hash
    end
  end

  context 'when hash is valid' do
    context 'when all entries defined' do
      let(:hash) do
        { before_script: ['ls', 'pwd'],
          image: 'ruby:2.2',
          services: ['postgres:9.1', 'mysql:5.5'],
          variables: { VAR: 'value' },
          after_script: ['make clean'],
          stages: ['build', 'pages'],
          cache: { key: 'k', untracked: true, paths: ['public/'] },
          rspec: { script: %w[rspec ls] },
          spinach: { script: 'spinach' } }
      end

      describe '#compose!' do
        before { global.compose! }

        it 'creates nodes hash' do
          expect(global.descendants).to be_an Array
        end

        it 'creates node object for each entry' do
          expect(global.descendants.count).to eq 8
        end

        it 'creates node object using valid class' do
          expect(global.descendants.first)
            .to be_an_instance_of Gitlab::Ci::Config::Node::Script
          expect(global.descendants.second)
            .to be_an_instance_of Gitlab::Ci::Config::Node::Image
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
        describe '#before_script' do
          it 'returns nil' do
            expect(global.before_script).to be nil
          end
        end

        describe '#leaf?' do
          it 'is leaf' do
            expect(global).to be_leaf
          end
        end
      end

      context 'when composed' do
        before { global.compose! }

        describe '#before_script' do
          it 'returns correct script' do
            expect(global.before_script).to eq ['ls', 'pwd']
          end
        end

        describe '#image' do
          it 'returns valid image' do
            expect(global.image).to eq 'ruby:2.2'
          end
        end

        describe '#services' do
          it 'returns array of services' do
            expect(global.services).to eq ['postgres:9.1', 'mysql:5.5']
          end
        end

        describe '#after_script' do
          it 'returns after script' do
            expect(global.after_script).to eq ['make clean']
          end
        end

        describe '#variables' do
          it 'returns variables' do
            expect(global.variables).to eq(VAR: 'value')
          end
        end

        describe '#stages' do
          context 'when stages key defined' do
            it 'returns array of stages' do
              expect(global.stages).to eq %w[build pages]
            end
          end

          context 'when deprecated types key defined' do
            let(:hash) do
              { types: ['test', 'deploy'],
                rspec: { script: 'rspec' } }
            end

            it 'returns array of types as stages' do
              expect(global.stages).to eq %w[test deploy]
            end
          end
        end

        describe '#cache' do
          it 'returns cache configuration' do
            expect(global.cache)
              .to eq(key: 'k', untracked: true, paths: ['public/'])
          end
        end

        describe '#jobs' do
          it 'returns jobs configuration' do
            expect(global.jobs).to eq(
              rspec: { name: :rspec,
                       script: %w[rspec ls],
                       stage: 'test' },
              spinach: { name: :spinach,
                         script: %w[spinach],
                         stage: 'test' }
            )
          end
        end
      end
    end

    context 'when most of entires not defined' do
      before { global.compose! }

      let(:hash) do
        { cache: { key: 'a' }, rspec: { script: %w[ls] } }
      end

      describe '#nodes' do
        it 'instantizes all nodes' do
          expect(global.descendants.count).to eq 8
        end

        it 'contains unspecified nodes' do
          expect(global.descendants.first)
            .to be_an_instance_of Gitlab::Ci::Config::Node::Unspecified
        end
      end

      describe '#variables' do
        it 'returns default value for variables' do
          expect(global.variables).to eq({})
        end
      end

      describe '#stages' do
        it 'returns an array of default stages' do
          expect(global.stages).to eq %w[build test deploy]
        end
      end

      describe '#cache' do
        it 'returns correct cache definition' do
          expect(global.cache).to eq(key: 'a')
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
      before { global.compose! }

      let(:hash) do
        { variables: nil, rspec: { script: 'rspec' } }
      end

      describe '#variables' do
        it 'undefined entry returns a default value' do
          expect(global.variables).to eq({})
        end
      end
    end
  end

  context 'when hash is not valid' do
    before { global.compose! }

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

    describe '#before_script' do
      it 'returns nil' do
        expect(global.before_script).to be_nil
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
    before { global.compose! }

    let(:hash) do
      { cache: { key: 'a' }, rspec: { script: 'ls' } }
    end

    context 'when node exists' do
      it 'returns correct entry' do
        expect(global[:cache])
          .to be_an_instance_of Gitlab::Ci::Config::Node::Cache
        expect(global[:jobs][:rspec][:script].value).to eq ['ls']
      end
    end

    context 'when node does not exist' do
      it 'always return unspecified node' do
        expect(global[:some][:unknown][:node])
          .not_to be_specified
      end
    end
  end
end
