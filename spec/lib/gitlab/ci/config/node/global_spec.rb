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
          cache: { key: 'k', untracked: true, paths: ['public/'] } }
      end

      describe '#process!' do
        before { global.process! }

        it 'creates nodes hash' do
          expect(global.nodes).to be_an Array
        end

        it 'creates node object for each entry' do
          expect(global.nodes.count).to eq 8
        end

        it 'creates node object using valid class' do
          expect(global.nodes.first)
            .to be_an_instance_of Gitlab::Ci::Config::Node::Script
          expect(global.nodes.second)
            .to be_an_instance_of Gitlab::Ci::Config::Node::Image
        end

        it 'sets correct description for nodes' do
          expect(global.nodes.first.description)
            .to eq 'Script that will be executed before each job.'
          expect(global.nodes.second.description)
            .to eq 'Docker image that will be used to execute jobs.'
        end
      end

      describe '#leaf?' do
        it 'is not leaf' do
          expect(global).not_to be_leaf
        end
      end

      context 'when not processed' do
        describe '#before_script' do
          it 'returns nil' do
            expect(global.before_script).to be nil
          end
        end
      end

      context 'when processed' do
        before { global.process! }

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
            let(:hash) { { types: ['test', 'deploy'] } }

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
      end
    end

    context 'when most of entires not defined' do
      let(:hash) { { cache: { key: 'a' }, rspec: {} } }
      before { global.process! }

      describe '#nodes' do
        it 'instantizes all nodes' do
          expect(global.nodes.count).to eq 8
        end

        it 'contains undefined nodes' do
          expect(global.nodes.first)
            .to be_an_instance_of Gitlab::Ci::Config::Node::Undefined
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
      let(:hash) { { variables: nil } }
      before { global.process! }

      describe '#variables' do
        it 'undefined entry returns a default value' do
          expect(global.variables).to eq({})
        end
      end
    end
  end

  context 'when hash is not valid' do
    before { global.process! }

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
      it 'raises error' do
        expect { global.before_script }.to raise_error(
          Gitlab::Ci::Config::Node::Entry::InvalidError
        )
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

  describe '#defined?' do
    it 'is concrete entry that is defined' do
      expect(global.defined?).to be true
    end
  end
end
