require 'spec_helper'

describe Gitlab::Ci::Config::Node::Configurable do
  let(:node) { Class.new }

  before do
    node.include(described_class)
  end

  describe 'validations' do
    let(:validator) { node.validator.new(instance) }

    before do
      node.class_eval do
        attr_reader :config

        def initialize(config)
          @config = config
        end
      end

      validator.validate
    end

    context 'when node validator is invalid' do
      let(:instance) { node.new('ls') }

      it 'returns invalid validator' do
        expect(validator).to be_invalid
      end
    end

    context 'when node instance is valid' do
      let(:instance) { node.new(key: 'value') }

      it 'returns valid validator' do
        expect(validator).to be_valid
      end
    end
  end

  describe 'configured nodes' do
    before do
      node.class_eval do
        node :object, Object, description: 'test object'
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
