# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Variables::Collection::Item do
  let(:variable_key) { 'VAR' }
  let(:variable_value) { 'something' }
  let(:expected_value) { variable_value }

  let(:variable) do
    { key: variable_key, value: variable_value, public: true, masked: false }
  end

  describe '.new' do
    context 'when unknown keyword is specified' do
      it 'raises error' do
        expect { described_class.new(key: variable_key, value: 'abc', files: true) }
          .to raise_error ArgumentError, 'unknown keyword: files'
      end
    end

    context 'when required keywords are not specified' do
      it 'raises error' do
        expect { described_class.new(key: variable_key) }
          .to raise_error ArgumentError, 'missing keyword: value'
      end
    end

    shared_examples 'creates variable' do
      subject { described_class.new(key: variable_key, value: variable_value) }

      it 'saves given value' do
        expect(subject[:key]).to eq variable_key
        expect(subject[:value]).to eq expected_value
      end
    end

    shared_examples 'raises error for invalid type' do
      it do
        expect { described_class.new(key: variable_key, value: variable_value) }
          .to raise_error ArgumentError, /`#{variable_key}` must be of type String or nil value, while it was:/
      end
    end

    it_behaves_like 'creates variable'

    context "when it's nil" do
      let(:variable_value) { nil }
      let(:expected_value) { nil }

      it_behaves_like 'creates variable'
    end

    context "when it's an empty string" do
      let(:variable_value) { '' }
      let(:expected_value) { '' }

      it_behaves_like 'creates variable'
    end

    context 'when provided value is not a string' do
      [1, false, [], {}, Object.new].each do |val|
        context "when it's #{val}" do
          let(:variable_value) { val }

          it_behaves_like 'raises error for invalid type'
        end
      end
    end
  end

  describe '.fabricate' do
    it 'supports using a hash' do
      resource = described_class.fabricate(variable)

      expect(resource).to be_a(described_class)
      expect(resource).to eq variable
    end

    it 'supports using a hash with stringified values' do
      variable = { 'key' => 'VARIABLE', 'value' => 'my value' }

      resource = described_class.fabricate(variable)

      expect(resource).to eq(key: 'VARIABLE', value: 'my value')
    end

    it 'supports using an active record resource' do
      variable = create(:ci_variable, key: 'CI_VAR', value: '123')
      resource = described_class.fabricate(variable)

      expect(resource).to be_a(described_class)
      expect(resource).to eq(key: 'CI_VAR', value: '123', public: false, masked: false)
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
          .to eq(key: 'VAR', value: 'value', public: true, file: true, masked: false)
      end
    end
  end
end
