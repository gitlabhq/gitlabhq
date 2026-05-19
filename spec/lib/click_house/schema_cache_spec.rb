# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::SchemaCache, feature_category: :database do
  let(:database) { :main }

  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  describe '.schema_cache_path' do
    it 'returns the per-database schema cache directory' do
      expect(described_class.schema_cache_path(:main).to_s)
        .to end_with('db/click_house/schema_cache/main')
    end
  end

  describe '.table_cache_path' do
    it 'returns the YAML file path for a single table' do
      expect(described_class.table_cache_path(:main, 'events').to_s)
        .to end_with('db/click_house/schema_cache/main/events.yml')
    end
  end

  describe '.[]' do
    let(:database_double) { instance_double(ClickHouse::SchemaCache::Database) }

    it 'loads the database via the Loader and memoizes it' do
      loader = instance_double(ClickHouse::SchemaCache::Loader, load: database_double)
      allow(ClickHouse::SchemaCache::Loader).to receive(:new).with(database: database).and_return(loader)

      first = described_class[database]
      second = described_class[database]

      expect(first).to eq(database_double)
      expect(second).to eq(database_double)
      expect(ClickHouse::SchemaCache::Loader).to have_received(:new).once
    end

    it 'returns an object exposing table, columns, table? lookup methods' do
      table = instance_double(ClickHouse::SchemaCache::Table)
      column = instance_double(ClickHouse::SchemaCache::Column)
      allow(database_double).to receive(:table).with('events').and_return(table)
      allow(database_double).to receive(:columns).with('events').and_return([column])
      allow(database_double).to receive(:table?).with('events').and_return(true)

      loader = instance_double(ClickHouse::SchemaCache::Loader, load: database_double)
      allow(ClickHouse::SchemaCache::Loader).to receive(:new).with(database: database).and_return(loader)

      schema = described_class[database]

      expect(schema.table('events')).to eq(table)
      expect(schema.columns('events')).to eq([column])
      expect(schema.table?('events')).to be(true)
    end
  end

  describe '.dump' do
    let(:connection) { instance_double(ClickHouse::Connection) }
    let(:dumper) { instance_double(ClickHouse::SchemaCache::Dumper) }

    it 'delegates to the Dumper and clears the in-memory cache for that database' do
      allow(ClickHouse::SchemaCache::Dumper)
        .to receive(:new).with(connection: connection, database: database).and_return(dumper)
      allow(dumper).to receive(:dump).and_return('/tmp/path')

      loader = instance_double(ClickHouse::SchemaCache::Loader, load: instance_double(ClickHouse::SchemaCache::Database))
      allow(ClickHouse::SchemaCache::Loader).to receive(:new).with(database: database).and_return(loader)

      described_class[database] # populate cache
      described_class.dump(connection, database)
      described_class[database]

      expect(dumper).to have_received(:dump)
      expect(ClickHouse::SchemaCache::Loader).to have_received(:new).twice
    end
  end
end
