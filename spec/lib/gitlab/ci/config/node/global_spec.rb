require 'spec_helper'

describe Gitlab::Ci::Config::Node::Global do
  let(:global) { described_class.new(hash) }

  describe '#keys' do
    it 'can contain global config keys' do
      expect(global.keys).to include :before_script
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
          .to be_an_instance_of Gitlab::Ci::Config::Node::BeforeScript
      end
    end

    describe '#leaf?' do
      it 'is not leaf' do
        expect(global).not_to be_leaf
      end
    end
  end

  context 'when hash is not valid' do
    let(:hash) do
      { before_script: 'ls' }
    end

    before { global.process! }

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
  end
end
