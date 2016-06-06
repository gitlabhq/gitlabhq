require 'spec_helper'

describe Gitlab::Ci::Config::Node::Global do
  let(:global) { described_class.new(hash, config) }
  let(:config) { double('Config') }

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
        expect(global.nodes).to be_a Hash
      end

      it 'creates node object for each entry' do
        expect(global.nodes.count).to eq 1
      end

      it 'creates node object using valid class' do
        expect(global.nodes[:before_script])
          .to be_an_instance_of Gitlab::Ci::Config::Node::BeforeScript
      end
    end
  end
end
