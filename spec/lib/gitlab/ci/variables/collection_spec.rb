# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Collection do
  describe '.new' do
    it 'can be initialized with an array' do
      variable = { key: 'VAR', value: 'value', public: true, masked: false }

      collection = described_class.new([variable])

      expect(collection.first.to_runner_variable).to eq variable
    end

    it 'can be initialized without an argument' do
      is_expected.to be_none
    end
  end

  describe '#append' do
    it 'appends a hash' do
      subject.append(key: 'VARIABLE', value: 'something')

      is_expected.to be_one
    end

    it 'appends a Ci::Variable' do
      subject.append(build(:ci_variable))

      is_expected.to be_one
    end

    it 'appends an internal resource' do
      collection = described_class.new([{ key: 'TEST', value: '1' }])

      subject.append(collection.first)

      is_expected.to be_one
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

    it 'does not concatenate resource if it undefined' do
      collection = described_class.new([{ key: 'VAR_1', value: '1' }])

      collection.concat(nil)

      expect(collection).to be_one
    end

    it 'returns self' do
      expect(subject.concat([key: 'VAR', value: 'test']))
        .to eq subject
    end
  end

  describe '#+' do
    it 'makes it possible to combine with an array' do
      collection = described_class.new([{ key: 'TEST', value: '1' }])
      variables = [{ key: 'TEST', value: 'something' }]

      expect((collection + variables).count).to eq 2
    end

    it 'makes it possible to combine with another collection' do
      collection = described_class.new([{ key: 'TEST', value: '1' }])
      other = described_class.new([{ key: 'TEST', value: '2' }])

      expect((collection + other).count).to eq 2
    end
  end

  describe '#[]' do
    variable = { key: 'VAR', value: 'value', public: true, masked: false }

    collection = described_class.new([variable])

    it 'returns nil for a non-existent variable name' do
      expect(collection['UNKNOWN_VAR']).to be_nil
    end

    it 'returns Item for an existent variable name' do
      expect(collection['VAR']).to be_an_instance_of(Gitlab::Ci::Variables::Collection::Item)
      expect(collection['VAR'].to_runner_variable).to eq(variable)
    end
  end

  describe '#size' do
    it 'returns zero for empty collection' do
      collection = described_class.new([])

      expect(collection.size).to eq(0)
    end

    it 'returns 2 for collection with 2 variables' do
      collection = described_class.new(
        [
          { key: 'VAR1', value: 'value', public: true, masked: false },
          { key: 'VAR2', value: 'value', public: true, masked: false }
        ])

      expect(collection.size).to eq(2)
    end

    it 'returns 3 for collection with 2 duplicate variables' do
      collection = described_class.new(
        [
          { key: 'VAR1', value: 'value', public: true, masked: false },
          { key: 'VAR2', value: 'value', public: true, masked: false },
          { key: 'VAR1', value: 'value', public: true, masked: false }
        ])

      expect(collection.size).to eq(3)
    end
  end

  describe '#to_runner_variables' do
    it 'creates an array of hashes in a runner-compatible format' do
      collection = described_class.new([{ key: 'TEST', value: '1' }])

      expect(collection.to_runner_variables)
        .to eq [{ key: 'TEST', value: '1', public: true, masked: false }]
    end
  end

  describe '#to_hash' do
    it 'returns regular hash in valid order without duplicates' do
      collection = described_class.new
        .append(key: 'TEST1', value: 'test-1')
        .append(key: 'TEST2', value: 'test-2')
        .append(key: 'TEST1', value: 'test-3')

      expect(collection.to_hash).to eq('TEST1' => 'test-3',
                                       'TEST2' => 'test-2')

      expect(collection.to_hash).to include(TEST1: 'test-3')
      expect(collection.to_hash).not_to include(TEST1: 'test-1')
    end
  end

  describe '#sorted_collection' do
    let!(:project) { create(:project) }

    subject { collection.sorted_collection(project) }

    context 'when FF :variable_inside_variable is disabled' do
      before do
        stub_feature_flags(variable_inside_variable: false)
      end

      let(:collection) do
        described_class.new
          .append(key: 'A', value: 'test-$B')
          .append(key: 'B', value: 'test-$C')
          .append(key: 'C', value: 'test')
      end

      it { is_expected.to be(collection) }
    end

    context 'when FF :variable_inside_variable is enabled' do
      before do
        stub_feature_flags(variable_inside_variable: [project])
      end

      let(:collection) do
        described_class.new
          .append(key: 'A', value: 'test-$B')
          .append(key: 'B', value: 'test-$C')
          .append(key: 'C', value: 'test')
      end

      it { is_expected.to be_a(Gitlab::Ci::Variables::Collection) }

      it 'returns sorted collection' do
        expect(subject.to_a).to eq(
          [
            { key: 'C', value: 'test', masked: false, public: true },
            { key: 'B', value: 'test-$C', masked: false, public: true },
            { key: 'A', value: 'test-$B', masked: false, public: true }
          ])
      end
    end
  end

  describe '#reject' do
    let(:collection) do
      described_class.new
        .append(key: 'CI_JOB_NAME', value: 'test-1')
        .append(key: 'CI_BUILD_ID', value: '1')
        .append(key: 'TEST1', value: 'test-3')
    end

    subject { collection.reject { |var| var[:key] =~ /\ACI_(JOB|BUILD)/ } }

    it 'returns a Collection instance' do
      is_expected.to be_an_instance_of(described_class)
    end

    it 'returns correctly filtered Collection' do
      comp = collection.to_runner_variables.reject { |var| var[:key] =~ /\ACI_(JOB|BUILD)/ }
      expect(subject.to_runner_variables).to eq(comp)
    end
  end
end
