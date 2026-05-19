# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::SchemaCache::Loader, feature_category: :database do
  let(:loader) { described_class.new(database: :main) }

  let(:users_table) do
    {
      'name' => 'users',
      'engine' => 'MergeTree',
      'engine_full' => 'MergeTree() ORDER BY id',
      'partition_key' => '',
      'primary_key' => 'id',
      'sorting_key' => 'id',
      'sampling_key' => '',
      'settings' => { 'index_granularity' => '8192' },
      'columns' => [
        {
          'name' => 'id',
          'type' => 'UInt64',
          'position' => 1,
          'default_kind' => '',
          'default_expression' => '',
          'comment' => '',
          'compression_codec' => '',
          'is_in_partition_key' => false,
          'is_in_sorting_key' => true,
          'is_in_primary_key' => true,
          'is_in_sampling_key' => false
        }
      ]
    }
  end

  describe '#load' do
    it 'reads each table YAML file in the database directory and returns a Database' do
      Dir.mktmpdir do |tmpdir|
        dir = Pathname.new(tmpdir).join('main')
        FileUtils.mkdir_p(dir)
        File.write(dir.join('users.yml'), YAML.dump(users_table))
        allow(ClickHouse::SchemaCache).to receive(:schema_cache_path).with(:main).and_return(dir)

        database = loader.load

        expect(database).to be_a(ClickHouse::SchemaCache::Database)
        expect(database.table_names).to eq(['users'])
        expect(database.column('users', 'id').type).to eq('UInt64')
        expect(database.table('users').settings).to eq('index_granularity' => '8192')
      end
    end

    it 'loads multiple per-table files into a single Database' do
      Dir.mktmpdir do |tmpdir|
        dir = Pathname.new(tmpdir).join('main')
        FileUtils.mkdir_p(dir)
        File.write(dir.join('users.yml'), YAML.dump(users_table))
        File.write(dir.join('events.yml'), YAML.dump(users_table.merge('name' => 'events')))
        allow(ClickHouse::SchemaCache).to receive(:schema_cache_path).with(:main).and_return(dir)

        database = loader.load

        expect(database.table_names).to match_array(%w[users events])
      end
    end

    it 'raises a clear error when the directory is missing' do
      missing_dir = Pathname.new('/tmp/does_not_exist/schema_cache')
      allow(ClickHouse::SchemaCache).to receive(:schema_cache_path).with(:main).and_return(missing_dir)

      expect { loader.load }.to raise_error(
        described_class::MissingSchemaCacheError,
        /ClickHouse schema cache not found/
      )
    end
  end
end
