# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::InlineHash do
  describe '.merge_keys' do
    subject { described_class.merge_keys(source) }

    let(:source) do
      {
        nested_param: {
          key: :Value
        },
        'root_param' => 'Root',
        unnested_symbol_key: :unnested_symbol_value,
        12 => 22,
        'very' => {
          'deep' => {
            'nested' => {
              'param' => 'Deep nested value'
            }
          }
        }
      }
    end

    it 'transforms a nested hash into a one-level hash' do
      is_expected.to eq(
        'nested_param.key' => :Value,
        'root_param' => 'Root',
        :unnested_symbol_key => :unnested_symbol_value,
        12 => 22,
        'very.deep.nested.param' => 'Deep nested value'
      )
    end

    it 'retains key insertion order' do
      expect(subject.keys)
        .to eq(['nested_param.key', 'root_param', :unnested_symbol_key, 12, 'very.deep.nested.param'])
    end

    context 'with a custom connector' do
      subject { described_class.merge_keys(source, connector: '::') }

      it 'uses the connector to merge keys' do
        is_expected.to eq(
          'nested_param::key' => :Value,
          'root_param' => 'Root',
          :unnested_symbol_key => :unnested_symbol_value,
          12 => 22,
          'very::deep::nested::param' => 'Deep nested value'
        )
      end
    end

    context 'with a starter prefix' do
      subject { described_class.merge_keys(source, prefix: 'options') }

      it 'prefixes all the keys' do
        is_expected.to eq(
          'options.nested_param.key' => :Value,
          'options.root_param' => 'Root',
          'options.unnested_symbol_key' => :unnested_symbol_value,
          'options.12' => 22,
          'options.very.deep.nested.param' => 'Deep nested value'
        )
      end
    end
  end
end
