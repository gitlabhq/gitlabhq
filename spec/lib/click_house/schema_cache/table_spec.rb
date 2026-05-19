# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::SchemaCache::Table, feature_category: :database do
  let(:column_id) do
    ClickHouse::SchemaCache::Column.new(
      name: 'id', type: 'UInt64', position: 1,
      default_kind: nil, default_expression: nil, comment: nil, compression_codec: nil,
      is_in_partition_key: false, is_in_sorting_key: true,
      is_in_primary_key: true, is_in_sampling_key: false
    )
  end

  let(:column_name) do
    ClickHouse::SchemaCache::Column.new(
      name: 'name', type: 'String', position: 2,
      default_kind: nil, default_expression: nil, comment: nil, compression_codec: nil,
      is_in_partition_key: false, is_in_sorting_key: false,
      is_in_primary_key: false, is_in_sampling_key: false
    )
  end

  let(:table) do
    described_class.new(
      name: 'users',
      engine: 'MergeTree',
      engine_full: 'MergeTree() ORDER BY id SETTINGS index_granularity = 8192',
      partition_key: '',
      primary_key: 'id, name',
      sorting_key: 'id',
      sampling_key: '',
      settings: { 'index_granularity' => '8192' },
      columns: [column_id, column_name]
    )
  end

  it 'exposes attributes' do
    expect(table.name).to eq('users')
    expect(table.engine).to eq('MergeTree')
    expect(table.settings).to eq('index_granularity' => '8192')
    expect(table.columns).to contain_exactly(column_id, column_name)
  end

  describe '#primary_key' do
    it 'returns column objects for the parsed key' do
      expect(table.primary_key).to eq([column_id, column_name])
    end

    it 'returns the raw string for parts that do not reference a column' do
      expression_table = described_class.new(
        name: 'events', engine: 'MergeTree', engine_full: '',
        partition_key: '', primary_key: 'cityHash64(user_id), id', sorting_key: 'id',
        sampling_key: '', settings: {}, columns: [column_id]
      )
      expect(expression_table.primary_key).to eq(['cityHash64(user_id)', column_id])
    end

    it 'does not split inside parenthesized expressions or quoted strings' do
      nested_table = described_class.new(
        name: 'events', engine: 'MergeTree', engine_full: '',
        partition_key: '',
        primary_key: "tuple(a, b), 'x, y', id",
        sorting_key: 'id',
        sampling_key: '', settings: {}, columns: [column_id]
      )
      expect(nested_table.primary_key).to eq(['tuple(a, b)', "'x, y'", column_id])
    end

    it 'returns an empty array when blank' do
      blank_table = described_class.new(
        name: 'users', engine: 'MergeTree', engine_full: '',
        partition_key: '', primary_key: '', sorting_key: '', sampling_key: '',
        settings: {}, columns: [column_id]
      )
      expect(blank_table.primary_key).to eq([])
    end
  end

  describe '#sorting_key' do
    it 'returns column objects for the parsed key' do
      expect(table.sorting_key).to eq([column_id])
    end
  end

  describe '#engine_params' do
    def build_table(engine:, engine_full:)
      described_class.new(
        name: 'users', engine: engine, engine_full: engine_full,
        partition_key: '', primary_key: '', sorting_key: '',
        sampling_key: '', settings: {}, columns: []
      )
    end

    it 'returns an empty array when there are no params' do
      table = build_table(
        engine: 'ReplacingMergeTree',
        engine_full: 'ReplacingMergeTree ORDER BY id SETTINGS index_granularity = 8192'
      )
      expect(table.engine_params).to eq([])
    end

    it 'returns an empty array when params are empty' do
      table = build_table(
        engine: 'MergeTree',
        engine_full: 'MergeTree() ORDER BY id'
      )
      expect(table.engine_params).to eq([])
    end

    it 'returns the params when present' do
      table = build_table(
        engine: 'ReplacingMergeTree',
        engine_full: 'ReplacingMergeTree(version, deleted) ORDER BY id'
      )
      expect(table.engine_params).to eq(%w[version deleted])
    end

    it 'returns a single param' do
      table = build_table(
        engine: 'ReplacingMergeTree',
        engine_full: 'ReplacingMergeTree(updated_at) ORDER BY workflow_id'
      )
      expect(table.engine_params).to eq(['updated_at'])
    end

    it 'does not split inside nested parens or quoted strings' do
      table = build_table(
        engine: 'Distributed',
        engine_full: "Distributed(cluster, db, table, cityHash64(a, b), 'x, y')"
      )
      expect(table.engine_params).to eq(['cluster', 'db', 'table', 'cityHash64(a, b)', "'x, y'"])
    end

    it 'returns an empty array when engine_full has no parens after the engine name' do
      table = build_table(
        engine: 'MergeTree',
        engine_full: 'MergeTree ORDER BY tuple(a, b)'
      )
      expect(table.engine_params).to eq([])
    end

    it 'returns an empty array when engine_full is blank' do
      table = build_table(engine: 'MergeTree', engine_full: '')
      expect(table.engine_params).to eq([])
    end

    it 'handles backtick-quoted engine names' do
      table = build_table(engine: 'Null', engine_full: '`Null`')
      expect(table.engine_params).to eq([])
    end
  end

  describe '#column' do
    it 'returns the column by name' do
      expect(table.column('id')).to eq(column_id)
      expect(table.column(:name)).to eq(column_name)
    end

    it 'returns nil for unknown columns' do
      expect(table.column('missing')).to be_nil
    end
  end

  describe '#column_names' do
    it 'returns the names of all columns in order' do
      expect(table.column_names).to eq(%w[id name])
    end
  end

  describe '#to_h' do
    it 'serializes a hash representation suitable for YAML dump' do
      hash = table.to_h

      expect(hash['name']).to eq('users')
      expect(hash['primary_key']).to eq('id, name')
      expect(hash['sorting_key']).to eq('id')
      expect(hash['settings']).to eq('index_granularity' => '8192')
      expect(hash['columns'].first).to include('name' => 'id', 'type' => 'UInt64')
    end
  end
end
