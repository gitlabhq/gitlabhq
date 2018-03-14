require 'spec_helper'

describe Gitlab::Ci::Variables::Collection do
  describe '.new' do
    it 'can be initialized with an array' do
      variable = { key: 'VAR', value: 'value', public: true }

      collection = described_class.new([variable])

      expect(collection.first.to_hash).to eq variable
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

    it 'returns self' do
      expect(subject.append(key: 'VAR', value: 'test'))
        .to eq subject
    end
  end

  describe '#concat' do
    it 'appends all elements from an array' do
      collection = described_class.new([{ key: 'VAR_1', value: '1' }])
      variables = [{ key: 'VAR_2', value: '2' }, { key: 'VAR_3', value: '3' }]

      collection.concat(variables)

      expect(collection).to include(key: 'VAR_1', value: '1', public: true)
      expect(collection).to include(key: 'VAR_2', value: '2', public: true)
      expect(collection).to include(key: 'VAR_3', value: '3', public: true)
    end

    it 'appends all elements from other collection' do
      collection = described_class.new([{ key: 'VAR_1', value: '1' }])
      additional = described_class.new([{ key: 'VAR_2', value: '2' },
                                        { key: 'VAR_3', value: '3' }])

      collection.concat(additional)

      expect(collection).to include(key: 'VAR_1', value: '1', public: true)
      expect(collection).to include(key: 'VAR_2', value: '2', public: true)
      expect(collection).to include(key: 'VAR_3', value: '3', public: true)
    end

    it 'returns self' do
      expect(subject.concat([key: 'VAR', value: 'test']))
        .to eq subject
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

  describe '#to_runner_variables' do
    it 'creates an array of hashes in a runner-compatible format' do
      collection = described_class.new([{ key: 'TEST', value: 1 }])

      expect(collection.to_runner_variables)
        .to eq [{ key: 'TEST', value: 1, public: true }]
    end
  end
end
