# frozen_string_literal: true

require 'fast_spec_helper'
require 'click_house/client'

RSpec.describe ClickHouse::SchemaCache::Dumper, feature_category: :database do
  let(:connection) { instance_double(ClickHouse::Connection, database_name: 'gitlab_clickhouse_test') }
  let(:dumper) { described_class.new(connection: connection, database: :main) }

  let(:table_rows) do
    [
      {
        'name' => 'users',
        'engine' => 'MergeTree',
        'engine_full' => 'MergeTree() ORDER BY id SETTINGS index_granularity = 8192',
        'partition_key' => '',
        'primary_key' => 'id',
        'sorting_key' => 'id',
        'sampling_key' => ''
      }
    ]
  end

  let(:column_rows) do
    [
      {
        'table' => 'users',
        'name' => 'id',
        'type' => 'UInt64',
        'position' => 1,
        'default_kind' => '',
        'default_expression' => '',
        'comment' => '',
        'compression_codec' => '',
        'is_in_partition_key' => 0,
        'is_in_sorting_key' => 1,
        'is_in_primary_key' => 1,
        'is_in_sampling_key' => 0
      }
    ]
  end

  before do
    allow(connection).to receive(:select) do |query|
      query_text = query.respond_to?(:to_sql) ? query.to_sql : query.to_s
      next table_rows if query_text.include?('FROM system.tables')
      next column_rows if query_text.include?('FROM system.columns')

      []
    end
  end

  describe '#tables' do
    it 'builds Table objects with columns and parsed settings' do
      tables = dumper.tables

      expect(tables.size).to eq(1)
      table = tables.first
      expect(table.name).to eq('users')
      expect(table.engine).to eq('MergeTree')
      expect(table.settings).to eq('index_granularity' => '8192')
      expect(table.columns.first.name).to eq('id')
      expect(table.columns.first.type).to eq('UInt64')
    end
  end

  describe '#dump' do
    it 'writes one YAML file per table under the database directory' do
      Dir.mktmpdir do |tmpdir|
        dir = Pathname.new(tmpdir).join('main')
        allow(ClickHouse::SchemaCache).to receive(:schema_cache_path).with(:main).and_return(dir)
        allow(ClickHouse::SchemaCache).to receive(:table_cache_path) do |_, name|
          dir.join("#{name}.yml")
        end

        dumper.dump

        users_file = dir.join('users.yml')
        expect(users_file).to exist

        loaded = YAML.safe_load_file(users_file)
        expect(loaded['name']).to eq('users')
        expect(loaded['columns'].first['name']).to eq('id')
      end
    end

    it 'removes YAML files for tables that no longer exist' do
      Dir.mktmpdir do |tmpdir|
        dir = Pathname.new(tmpdir).join('main')
        FileUtils.mkdir_p(dir)
        stale_file = dir.join('old_table.yml')
        File.write(stale_file, YAML.dump('name' => 'old_table'))

        allow(ClickHouse::SchemaCache).to receive(:schema_cache_path).with(:main).and_return(dir)
        allow(ClickHouse::SchemaCache).to receive(:table_cache_path) do |_, name|
          dir.join("#{name}.yml")
        end

        dumper.dump

        expect(stale_file).not_to exist
        expect(dir.join('users.yml')).to exist
      end
    end

    it 'skips writing when the directory is not writable' do
      dir = instance_double(Pathname, exist?: true)
      allow(ClickHouse::SchemaCache).to receive(:schema_cache_path).with(:main).and_return(dir)
      allow(File).to receive(:writable?).with(dir).and_return(false)

      expect { dumper.dump }.to output(/not writeable/).to_stdout
    end
  end

  describe 'settings parsing' do
    let(:table_rows) do
      [
        {
          'name' => 'events', 'engine' => 'ReplacingMergeTree',
          'engine_full' => "ReplacingMergeTree PARTITION BY x ORDER BY id " \
            "SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 8192",
          'partition_key' => 'x', 'primary_key' => 'id', 'sorting_key' => 'id', 'sampling_key' => ''
        }
      ]
    end

    it 'parses string and numeric settings' do
      settings = dumper.tables.first.settings

      expect(settings).to eq(
        'deduplicate_merge_projection_mode' => "'rebuild'",
        'index_granularity' => '8192'
      )
    end
  end
end
