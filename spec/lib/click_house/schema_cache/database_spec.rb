# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::SchemaCache::Database, feature_category: :database do
  let(:column) do
    ClickHouse::SchemaCache::Column.new(
      name: 'id', type: 'UInt64', position: 1,
      default_kind: nil, default_expression: nil, comment: nil, compression_codec: nil,
      is_in_partition_key: false, is_in_sorting_key: true,
      is_in_primary_key: true, is_in_sampling_key: false
    )
  end

  let(:users_table) do
    ClickHouse::SchemaCache::Table.new(
      name: 'users', engine: 'MergeTree', engine_full: 'MergeTree() ORDER BY id',
      partition_key: '', primary_key: 'id', sorting_key: 'id', sampling_key: '',
      settings: {}, columns: [column]
    )
  end

  let(:database) { described_class.new(name: :main, tables: [users_table]) }

  describe '#table' do
    it 'returns the table by name' do
      expect(database.table('users')).to eq(users_table)
    end

    it 'returns nil when the table is not present' do
      expect(database.table('missing')).to be_nil
    end
  end

  describe '#table?' do
    it 'is true for known tables' do
      expect(database.table?('users')).to be(true)
    end

    it 'is false for unknown tables' do
      expect(database.table?('missing')).to be(false)
    end
  end

  describe '#tables' do
    it 'lists all tables' do
      expect(database.tables).to contain_exactly(users_table)
    end
  end

  describe '#table_names' do
    it 'returns table names' do
      expect(database.table_names).to eq(['users'])
    end
  end

  describe '#columns' do
    it 'returns the columns of a table' do
      expect(database.columns('users')).to eq([column])
    end

    it 'returns an empty array for unknown tables' do
      expect(database.columns('missing')).to eq([])
    end
  end

  describe '#column' do
    it 'returns the column for a known table/column' do
      expect(database.column('users', 'id')).to eq(column)
    end

    it 'returns nil for unknown columns' do
      expect(database.column('users', 'missing')).to be_nil
    end

    it 'returns nil for unknown tables' do
      expect(database.column('missing', 'id')).to be_nil
    end
  end
end
