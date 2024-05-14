# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Validator do
  let(:validator) { Class.new(described_class) }
  let(:validator_instance) { validator.new(node) }
  let(:node) { spy('node') }

  before do
    allow(node).to receive(:key).and_return('node')
    allow(node).to receive(:ancestors).and_return([])
  end

  describe 'delegated validator' do
    before do
      validator.class_eval do
        validates :test_attribute, presence: true
      end
    end

    context 'when node is valid' do
      before do
        allow(node).to receive(:test_attribute).and_return('valid value')
      end

      it 'validates attribute in node' do
        expect(node).to receive(:test_attribute)
        expect(validator_instance).to be_valid
      end

      it 'returns no errors' do
        validator_instance.validate

        expect(validator_instance.messages).to be_empty
      end
    end

    context 'when node is invalid' do
      before do
        allow(node).to receive(:test_attribute).and_return(nil)
      end

      it 'validates attribute in node' do
        expect(node).to receive(:test_attribute)
        expect(validator_instance).to be_invalid
      end

      it 'returns errors' do
        validator_instance.validate

        expect(validator_instance.messages)
          .to include(/test attribute can't be blank/)
      end
    end
  end
end
