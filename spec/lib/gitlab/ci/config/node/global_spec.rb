require 'spec_helper'

describe Gitlab::Ci::Config::Node::Global do
  let(:global) { described_class.new(hash) }

  describe '#allowed_nodes' do
    it 'can contain global config keys' do
      expect(global.allowed_nodes).to include :before_script
    end

    it 'returns a hash' do
      expect(global.allowed_nodes).to be_a Hash
    end
  end

  context 'when hash is valid' do
    let(:hash) do
      { before_script: ['ls', 'pwd'] }
    end

    describe '#process!' do
      before { global.process! }

      it 'creates nodes hash' do
        expect(global.nodes).to be_an Array
      end

      it 'creates node object for each entry' do
        expect(global.nodes.count).to eq 1
      end

      it 'creates node object using valid class' do
        expect(global.nodes.first)
          .to be_an_instance_of Gitlab::Ci::Config::Node::Script
      end

      it 'sets correct description for nodes' do
        expect(global.nodes.first.description)
          .to eq 'Script that will be executed before each job.'
      end
    end

    describe '#leaf?' do
      it 'is not leaf' do
        expect(global).not_to be_leaf
      end
    end

    describe '#before_script' do
      context 'when processed' do
        before { global.process! }

        it 'returns correct script' do
          expect(global.before_script).to eq "ls\npwd"
        end
      end

      context 'when not processed' do
        it 'returns nil' do
          expect(global.before_script).to be nil
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
          .to include 'before_script should be an array of strings'
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
  end
end
