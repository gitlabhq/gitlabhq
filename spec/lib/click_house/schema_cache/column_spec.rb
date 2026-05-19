# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::SchemaCache::Column, feature_category: :database do
  let(:column) do
    described_class.new(
      name: 'id',
      type: 'UInt64',
      position: 1,
      default_kind: '',
      default_expression: '',
      comment: '',
      compression_codec: '',
      is_in_partition_key: false,
      is_in_sorting_key: true,
      is_in_primary_key: true,
      is_in_sampling_key: false
    )
  end

  it 'exposes attributes' do
    expect(column.name).to eq('id')
    expect(column.type).to eq('UInt64')
    expect(column.position).to eq(1)
    expect(column.is_in_primary_key).to be(true)
  end

  describe '#nullable?' do
    it 'returns false for non-nullable types' do
      expect(column.nullable?).to be(false)
    end

    it 'returns true for Nullable wrapper types' do
      nullable = described_class.new(name: 'x', type: 'Nullable(UInt64)', position: 0,
        default_kind: nil, default_expression: nil, comment: nil, compression_codec: nil,
        is_in_partition_key: false, is_in_sorting_key: false,
        is_in_primary_key: false, is_in_sampling_key: false)

      expect(nullable.nullable?).to be(true)
    end
  end
end
