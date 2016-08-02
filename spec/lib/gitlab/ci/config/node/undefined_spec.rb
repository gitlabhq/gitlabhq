require 'spec_helper'

describe Gitlab::Ci::Config::Node::Undefined do
  let(:undefined) { described_class.new(entry) }
  let(:entry) { spy('Entry') }

  describe '#valid?' do
    it 'delegates method to entry' do
      expect(undefined.valid).to eq entry
    end
  end

  describe '#errors' do
    it 'delegates method to entry' do
      expect(undefined.errors).to eq entry
    end
  end

  describe '#value' do
    it 'delegates method to entry' do
      expect(undefined.value).to eq entry
    end
  end

  describe '#specified?' do
    it 'is always false' do
      allow(entry).to receive(:specified?).and_return(true)

      expect(undefined.specified?).to be false
    end
  end
end
