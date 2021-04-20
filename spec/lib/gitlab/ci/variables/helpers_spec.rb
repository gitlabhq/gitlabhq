# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Variables::Helpers do
  describe '.merge_variables' do
    let(:current_variables) do
      [{ key: 'key1', value: 'value1' },
       { key: 'key2', value: 'value2' }]
    end

    let(:new_variables) do
      [{ key: 'key2', value: 'value22' },
       { key: 'key3', value: 'value3' }]
    end

    let(:result) do
      [{ key: 'key1', value: 'value1', public: true },
       { key: 'key2', value: 'value22', public: true },
       { key: 'key3', value: 'value3', public: true }]
    end

    subject { described_class.merge_variables(current_variables, new_variables) }

    it { is_expected.to eq(result) }

    context 'when new variables is a hash' do
      let(:new_variables) do
        { 'key2' => 'value22', 'key3' => 'value3' }
      end

      it { is_expected.to eq(result) }
    end

    context 'when new variables is a hash with symbol keys' do
      let(:new_variables) do
        { key2: 'value22', key3: 'value3' }
      end

      it { is_expected.to eq(result) }
    end

    context 'when new variables is nil' do
      let(:new_variables) {}
      let(:result) do
        [{ key: 'key1', value: 'value1', public: true },
         { key: 'key2', value: 'value2', public: true }]
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.transform_to_yaml_variables' do
    let(:variables) do
      { 'key1' => 'value1', 'key2' => 'value2' }
    end

    let(:result) do
      [{ key: 'key1', value: 'value1', public: true },
       { key: 'key2', value: 'value2', public: true }]
    end

    subject { described_class.transform_to_yaml_variables(variables) }

    it { is_expected.to eq(result) }

    context 'when variables is nil' do
      let(:variables) {}

      it { is_expected.to eq([]) }
    end
  end

  describe '.transform_from_yaml_variables' do
    let(:variables) do
      [{ key: 'key1', value: 'value1', public: true },
       { key: 'key2', value: 'value2', public: true }]
    end

    let(:result) do
      { 'key1' => 'value1', 'key2' => 'value2' }
    end

    subject { described_class.transform_from_yaml_variables(variables) }

    it { is_expected.to eq(result) }

    context 'when variables is nil' do
      let(:variables) {}

      it { is_expected.to eq({}) }
    end

    context 'when variables is a hash' do
      let(:variables) do
        { key1: 'value1', 'key2' => 'value2' }
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.inherit_yaml_variables' do
    let(:from) do
      [{ key: 'key1', value: 'value1' },
       { key: 'key2', value: 'value2' }]
    end

    let(:to) do
      [{ key: 'key2', value: 'value22' },
       { key: 'key3', value: 'value3' }]
    end

    let(:inheritance) { true }

    let(:result) do
      [{ key: 'key1', value: 'value1', public: true },
       { key: 'key2', value: 'value22', public: true },
       { key: 'key3', value: 'value3', public: true }]
    end

    subject { described_class.inherit_yaml_variables(from: from, to: to, inheritance: inheritance) }

    it { is_expected.to eq(result) }

    context 'when inheritance is false' do
      let(:inheritance) { false }

      let(:result) do
        [{ key: 'key2', value: 'value22', public: true },
         { key: 'key3', value: 'value3', public: true }]
      end

      it { is_expected.to eq(result) }
    end

    context 'when inheritance is array' do
      let(:inheritance) { ['key2'] }

      let(:result) do
        [{ key: 'key2', value: 'value22', public: true },
         { key: 'key3', value: 'value3', public: true }]
      end

      it { is_expected.to eq(result) }
    end
  end
end
