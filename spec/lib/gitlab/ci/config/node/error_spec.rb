require 'spec_helper'

describe Gitlab::Ci::Config::Node::Error do
  let(:error) { described_class.new(message, parent) }
  let(:message) { 'some error' }
  let(:parent) { spy('parent') }

  before do
    allow(parent).to receive(:key).and_return('parent_key')
  end

  describe '#key' do
    it 'returns underscored class name' do
      expect(error.key).to eq 'parent_key'
    end
  end

  describe '#to_s' do
    it 'returns valid error message' do
      expect(error.to_s).to eq 'parent_key: some error'
    end
  end
end
