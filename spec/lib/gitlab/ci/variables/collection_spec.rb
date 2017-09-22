require 'spec_helper'

describe Gitlab::Ci::Variables::Collection do
  describe '.new' do
    it 'can be initialized with an array' do
      variable = { key: 'SOME_VAR', value: 'Some Value' }
      collection = described_class.new([variable])

      expect(collection.first.to_h).to include variable
    end

    it 'can be initialized without an argument' do
      expect(subject).to be_none
    end
  end

  describe '#append' do
    it 'appends a hash' do
      subject.append(key: 'VARIABLE', value: 'something')

      expect(subject).to be_one
    end

    it 'appends a Ci::Variable' do
      subject.append(build(:ci_variable))

      expect(subject).to be_one
    end

    it 'appends an internal resource' do
      collection = described_class.new([{ key: 'TEST', value: 1 }])

      subject.append(collection.first)

      expect(subject).to be_one
    end
  end

  describe '#+' do
    it 'makes it possible to combine with an array' do
      collection = described_class.new([{ key: 'TEST', value: 1 }])
      variables = [{ key: 'TEST', value: 'something' }]

      expect((collection + variables).count).to eq 2
    end

    it 'makes it possible to combine with another collection' do
      collection = described_class.new([{ key: 'TEST', value: 1 }])
      other = described_class.new([{ key: 'TEST', value: 2 }])

      expect((collection + other).count).to eq 2
    end
  end

  describe '#to_hash' do
    it 'creates a hash / value mapping' do
      collection = described_class.new([{ key: 'TEST', value: 1 }])

      expect(collection.to_hash)
        .to eq [{ key: 'TEST', value: 1, public: false }]
    end
  end
end
