require 'spec_helper'

describe Gitlab::Ci::Config::Node::Configurable do
  let(:node) { Class.new }

  before do
    node.include(described_class)
  end

  describe 'configured nodes' do
    before do
      node.class_eval do
        allow_node :object, Object, description: 'test object'
      end
    end

    describe '.nodes' do
      it 'has valid nodes' do
        expect(node.nodes).to include :object
      end

      it 'creates a node factory' do
        expect(node.nodes[:object])
          .to be_an_instance_of Gitlab::Ci::Config::Node::Factory
      end

      it 'returns a duplicated factory object' do
        first_factory = node.nodes[:object]
        second_factory = node.nodes[:object]

        expect(first_factory).not_to be_equal(second_factory)
      end
    end
  end
end
