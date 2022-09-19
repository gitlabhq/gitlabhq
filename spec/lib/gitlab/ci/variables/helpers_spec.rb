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
      [{ key: 'key1', value: 'value1' },
       { key: 'key2', value: 'value22' },
       { key: 'key3', value: 'value3' }]
    end

    subject { described_class.merge_variables(current_variables, new_variables) }

    it { is_expected.to match_array(result) }

    context 'when new variables is a hash' do
      let(:new_variables) do
        { 'key2' => 'value22', 'key3' => 'value3' }
      end

      it { is_expected.to match_array(result) }
    end

    context 'when new variables is a hash with symbol keys' do
      let(:new_variables) do
        { key2: 'value22', key3: 'value3' }
      end

      it { is_expected.to match_array(result) }
    end

    context 'when new variables is nil' do
      let(:new_variables) {}
      let(:result) do
        [{ key: 'key1', value: 'value1' },
         { key: 'key2', value: 'value2' }]
      end

      it { is_expected.to match_array(result) }
    end
  end

  describe '.transform_to_array' do
    subject { described_class.transform_to_array(variables) }

    context 'when values are strings' do
      let(:variables) do
        { 'key1' => 'value1', 'key2' => 'value2' }
      end

      let(:result) do
        [{ key: 'key1', value: 'value1' },
         { key: 'key2', value: 'value2' }]
      end

      it { is_expected.to match_array(result) }
    end

    context 'when variables is nil' do
      let(:variables) {}

      it { is_expected.to match_array([]) }
    end

    context 'when values are hashes' do
      let(:variables) do
        { 'key1' => { value: 'value1', description: 'var 1' }, 'key2' => { value: 'value2' } }
      end

      let(:result) do
        [{ key: 'key1', value: 'value1', description: 'var 1' },
         { key: 'key2', value: 'value2' }]
      end

      it { is_expected.to match_array(result) }

      context 'when a value data has `key` as a key' do
        let(:variables) do
          { 'key1' => { value: 'value1', key: 'new_key1' }, 'key2' => { value: 'value2' } }
        end

        let(:result) do
          [{ key: 'key1', value: 'value1' },
           { key: 'key2', value: 'value2' }]
        end

        it 'ignores the key set with "key"' do
          is_expected.to match_array(result)
        end
      end
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
      [{ key: 'key1', value: 'value1' },
       { key: 'key2', value: 'value22' },
       { key: 'key3', value: 'value3' }]
    end

    subject { described_class.inherit_yaml_variables(from: from, to: to, inheritance: inheritance) }

    it { is_expected.to match_array(result) }

    context 'when inheritance is false' do
      let(:inheritance) { false }

      let(:result) do
        [{ key: 'key2', value: 'value22' },
         { key: 'key3', value: 'value3' }]
      end

      it { is_expected.to match_array(result) }
    end

    context 'when inheritance is array' do
      let(:inheritance) { ['key2'] }

      let(:result) do
        [{ key: 'key2', value: 'value22' },
         { key: 'key3', value: 'value3' }]
      end

      it { is_expected.to match_array(result) }
    end
  end
end
