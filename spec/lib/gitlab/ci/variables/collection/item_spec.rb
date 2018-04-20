require 'spec_helper'

describe Gitlab::Ci::Variables::Collection::Item do
  let(:variable) do
    { key: 'VAR', value: 'something', public: true }
  end

  describe '.new' do
    it 'raises error if unknown key i specified' do
      expect { described_class.new(key: 'VAR', value: 'abc', files: true) }
        .to raise_error ArgumentError, 'unknown keyword: files'
    end

    it 'raises error when required keywords are not specified' do
      expect { described_class.new(key: 'VAR') }
        .to raise_error ArgumentError, 'missing keyword: value'
    end
  end

  describe '.fabricate' do
    it 'supports using a hash' do
      resource = described_class.fabricate(variable)

      expect(resource).to be_a(described_class)
      expect(resource).to eq variable
    end

    it 'supports using an active record resource' do
      variable = create(:ci_variable, key: 'CI_VAR', value: '123')
      resource = described_class.fabricate(variable)

      expect(resource).to be_a(described_class)
      expect(resource).to eq(key: 'CI_VAR', value: '123', public: false)
    end

    it 'supports using another collection item' do
      item = described_class.new(**variable)

      resource = described_class.fabricate(item)

      expect(resource).to be_a(described_class)
      expect(resource).to eq variable
      expect(resource.object_id).not_to eq item.object_id
    end
  end

  describe '#==' do
    it 'compares a hash representation of a variable' do
      expect(described_class.new(**variable) == variable).to be true
    end
  end

  describe '#[]' do
    it 'behaves like a hash accessor' do
      item = described_class.new(**variable)

      expect(item[:key]).to eq 'VAR'
    end
  end

  describe '#to_runner_variable' do
    context 'when variable is not a file-related' do
      it 'returns a runner-compatible hash representation' do
        runner_variable = described_class
          .new(**variable)
          .to_runner_variable

        expect(runner_variable).to eq variable
      end
    end

    context 'when variable is file-related' do
      it 'appends file description component' do
        runner_variable = described_class
          .new(key: 'VAR', value: 'value', file: true)
          .to_runner_variable

        expect(runner_variable)
          .to eq(key: 'VAR', value: 'value', public: true, file: true)
      end
    end
  end
end
