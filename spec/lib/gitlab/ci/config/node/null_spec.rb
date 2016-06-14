require 'spec_helper'

describe Gitlab::Ci::Config::Node::Null do
  let(:entry) { described_class.new(nil) }

  describe '#leaf?' do
    it 'is leaf node' do
      expect(entry).to be_leaf
    end
  end

  describe '#any_method' do
    it 'responds with nil' do
      expect(entry.any_method).to be nil
    end
  end

  describe '#value' do
    it 'returns nil' do
      expect(entry.value).to be nil
    end
  end
end
