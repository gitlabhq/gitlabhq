require 'spec_helper'

describe Gitlab::Ci::Config::Node::Undefined do
  let(:undefined) { described_class.new(entry) }
  let(:entry) { Class.new }

  describe '#leaf?' do
    it 'is leaf node' do
      expect(undefined).to be_leaf
    end
  end

  describe '#valid?' do
    it 'is always valid' do
      expect(undefined).to be_valid
    end
  end

  describe '#errors' do
    it 'is does not contain errors' do
      expect(undefined.errors).to be_empty
    end
  end

  describe '#value' do
    before do
      allow(entry).to receive(:default).and_return('some value')
    end

    it 'returns default value for entry' do
      expect(undefined.value).to eq 'some value'
    end
  end

  describe '#undefined?' do
    it 'is not a defined entry' do
      expect(undefined.defined?).to be false
    end
  end
end
