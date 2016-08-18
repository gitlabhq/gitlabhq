require 'spec_helper'

describe Gitlab::Ci::Config::Node::Validatable do
  let(:node) { Class.new }

  before do
    node.include(described_class)
  end

  describe '.validator' do
    before do
      node.class_eval do
        attr_accessor :test_attribute

        validations do
          validates :test_attribute, presence: true
        end
      end
    end

    it 'returns validator' do
      expect(node.validator.superclass)
        .to be Gitlab::Ci::Config::Node::Validator
    end

    it 'returns only one validator to mitigate leaks' do
      expect { node.validator }.not_to change { node.validator }
    end

    context 'when validating node instance' do
      let(:node_instance) { node.new }

      context 'when attribute is valid' do
        before do
          node_instance.test_attribute = 'valid'
        end

        it 'instance of validator is valid' do
          expect(node.validator.new(node_instance)).to be_valid
        end
      end

      context 'when attribute is not valid' do
        before do
          node_instance.test_attribute = nil
        end

        it 'instance of validator is invalid' do
          expect(node.validator.new(node_instance)).to be_invalid
        end
      end
    end
  end
end
