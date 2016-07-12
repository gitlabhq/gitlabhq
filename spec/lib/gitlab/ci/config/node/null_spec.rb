require 'spec_helper'

describe Gitlab::Ci::Config::Node::Null do
  let(:null) { described_class.new(nil) }

  describe '#leaf?' do
    it 'is leaf node' do
      expect(null).to be_leaf
    end
  end

  describe '#valid?' do
    it 'is always valid' do
      expect(null).to be_valid
    end
  end

  describe '#errors' do
    it 'is does not contain errors' do
      expect(null.errors).to be_empty
    end
  end

  describe '#value' do
    it 'returns nil' do
      expect(null.value).to eq nil
    end
  end

  describe '#relevant?' do
    it 'is not relevant' do
      expect(null.relevant?).to eq false
    end
  end

  describe '#specified?' do
    it 'is not defined' do
      expect(null.specified?).to eq false
    end
  end
end
