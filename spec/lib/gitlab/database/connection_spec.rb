# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Connection do
  let(:connection) { described_class.new }

  describe '#default_pool_size' do
    before do
      allow(Gitlab::Runtime).to receive(:max_threads).and_return(7)
    end

    it 'returns the max thread size plus a fixed headroom of 10' do
      expect(connection.default_pool_size).to eq(17)
    end

    it 'returns the max thread size plus a DB_POOL_HEADROOM if this env var is present' do
      stub_env('DB_POOL_HEADROOM', '7')

      expect(connection.default_pool_size).to eq(14)
    end
  end

  describe '#config' do
    it 'returns a HashWithIndifferentAccess' do
      expect(connection.config).to be_an_instance_of(HashWithIndifferentAccess)
    end

    it 'returns a default pool size' do
      expect(connection.config).to include(pool: connection.default_pool_size)
    end
  end

  describe '#pool_size' do
    context 'when no explicit size is configured' do
      it 'returns the default pool size' do
        expect(connection.config).to receive(:[]).with(:pool).and_return(nil)

        expect(connection.pool_size).to eq(connection.default_pool_size)
      end
    end

    context 'when an explicit pool size is set' do
      it 'returns the pool size' do
        expect(connection.config).to receive(:[]).with(:pool).and_return(4)

        expect(connection.pool_size).to eq(4)
      end
    end
  end

  describe '#username' do
    context 'when a username is set' do
      it 'returns the username' do
        allow(connection).to receive(:config).and_return(username: 'bob')

        expect(connection.username).to eq('bob')
      end
    end

    context 'when a username is not set' do
      it 'returns the value of the USER environment variable' do
        allow(connection).to receive(:config).and_return(username: nil)
        allow(ENV).to receive(:[]).with('USER').and_return('bob')

        expect(connection.username).to eq('bob')
      end
    end
  end

  describe '#database_name' do
    it 'returns the name of the database' do
      allow(connection).to receive(:config).and_return(database: 'test')

      expect(connection.database_name).to eq('test')
    end
  end

  describe '#adapter_name' do
    it 'returns the database adapter name' do
      allow(connection).to receive(:config).and_return(adapter: 'test')

      expect(connection.adapter_name).to eq('test')
    end
  end

  describe '#human_adapter_name' do
    context 'when the adapter is PostgreSQL' do
      it 'returns PostgreSQL' do
        allow(connection).to receive(:config).and_return(adapter: 'postgresql')

        expect(connection.human_adapter_name).to eq('PostgreSQL')
      end
    end

    context 'when the adapter is not PostgreSQL' do
      it 'returns Unknown' do
        allow(connection).to receive(:config).and_return(adapter: 'kittens')

        expect(connection.human_adapter_name).to eq('Unknown')
      end
    end
  end

  describe '#postgresql?' do
    context 'when using PostgreSQL' do
      it 'returns true' do
        allow(connection).to receive(:adapter_name).and_return('PostgreSQL')

        expect(connection.postgresql?).to eq(true)
      end
    end

    context 'when not using PostgreSQL' do
      it 'returns false' do
        allow(connection).to receive(:adapter_name).and_return('MySQL')

        expect(connection.postgresql?).to eq(false)
      end
    end
  end

  describe '#disable_prepared_statements' do
    around do |example|
      original_config = ::Gitlab::Database.config

      example.run

      connection.scope.establish_connection(original_config)
    end

    it 'disables prepared statements' do
      connection.scope.establish_connection(
        ::Gitlab::Database.config.merge(prepared_statements: true)
      )

      expect(connection.scope.connection.prepared_statements).to eq(true)

      connection.disable_prepared_statements

      expect(connection.scope.connection.prepared_statements).to eq(false)
    end
  end

  describe '#read_only?' do
    it 'returns false' do
      expect(connection.read_only?).to eq(false)
    end
  end

  describe '#read_write' do
    it 'returns true' do
      expect(connection.read_write?).to eq(true)
    end
  end

  describe '#db_read_only?' do
    it 'detects a read-only database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "t" }])

      expect(connection.db_read_only?).to be_truthy
    end

    it 'detects a read-only database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => true }])

      expect(connection.db_read_only?).to be_truthy
    end

    it 'detects a read-write database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "f" }])

      expect(connection.db_read_only?).to be_falsey
    end

    it 'detects a read-write database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => false }])

      expect(connection.db_read_only?).to be_falsey
    end
  end

  describe '#db_read_write?' do
    it 'detects a read-only database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "t" }])

      expect(connection.db_read_write?).to eq(false)
    end

    it 'detects a read-only database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => true }])

      expect(connection.db_read_write?).to eq(false)
    end

    it 'detects a read-write database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "f" }])

      expect(connection.db_read_write?).to eq(true)
    end

    it 'detects a read-write database' do
      allow(connection.scope.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => false }])

      expect(connection.db_read_write?).to eq(true)
    end
  end

  describe '#version' do
    around do |example|
      connection.instance_variable_set(:@version, nil)
      example.run
      connection.instance_variable_set(:@version, nil)
    end

    context "on postgresql" do
      it "extracts the version number" do
        allow(connection)
          .to receive(:database_version)
          .and_return("PostgreSQL 9.4.4 on x86_64-apple-darwin14.3.0")

        expect(connection.version).to eq '9.4.4'
      end
    end

    it 'memoizes the result' do
      count = ActiveRecord::QueryRecorder
        .new { 2.times { connection.version } }
        .count

      expect(count).to eq(1)
    end
  end

  describe '#postgresql_minimum_supported_version?' do
    it 'returns false when using PostgreSQL 10' do
      allow(connection).to receive(:version).and_return('10')

      expect(connection.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns false when using PostgreSQL 11' do
      allow(connection).to receive(:version).and_return('11')

      expect(connection.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns true when using PostgreSQL 12' do
      allow(connection).to receive(:version).and_return('12')

      expect(connection.postgresql_minimum_supported_version?).to eq(true)
    end
  end

  describe '#bulk_insert' do
    before do
      allow(connection).to receive(:connection).and_return(dummy_connection)
      allow(dummy_connection).to receive(:quote_column_name, &:itself)
      allow(dummy_connection).to receive(:quote, &:itself)
      allow(dummy_connection).to receive(:execute)
    end

    let(:dummy_connection) { double(:connection) }

    let(:rows) do
      [
        { a: 1, b: 2, c: 3 },
        { c: 6, a: 4, b: 5 }
      ]
    end

    it 'does nothing with empty rows' do
      expect(dummy_connection).not_to receive(:execute)

      connection.bulk_insert('test', [])
    end

    it 'uses the ordering from the first row' do
      expect(dummy_connection).to receive(:execute) do |sql|
        expect(sql).to include('(1, 2, 3)')
        expect(sql).to include('(4, 5, 6)')
      end

      connection.bulk_insert('test', rows)
    end

    it 'quotes column names' do
      expect(dummy_connection).to receive(:quote_column_name).with(:a)
      expect(dummy_connection).to receive(:quote_column_name).with(:b)
      expect(dummy_connection).to receive(:quote_column_name).with(:c)

      connection.bulk_insert('test', rows)
    end

    it 'quotes values' do
      1.upto(6) do |i|
        expect(dummy_connection).to receive(:quote).with(i)
      end

      connection.bulk_insert('test', rows)
    end

    it 'does not quote values of a column in the disable_quote option' do
      [1, 2, 4, 5].each do |i|
        expect(dummy_connection).to receive(:quote).with(i)
      end

      connection.bulk_insert('test', rows, disable_quote: :c)
    end

    it 'does not quote values of columns in the disable_quote option' do
      [2, 5].each do |i|
        expect(dummy_connection).to receive(:quote).with(i)
      end

      connection.bulk_insert('test', rows, disable_quote: [:a, :c])
    end

    it 'handles non-UTF-8 data' do
      expect { connection.bulk_insert('test', [{ a: "\255" }]) }.not_to raise_error
    end

    context 'when using PostgreSQL' do
      it 'allows the returning of the IDs of the inserted rows' do
        result = double(:result, values: [['10']])

        expect(dummy_connection)
          .to receive(:execute)
          .with(/RETURNING id/)
          .and_return(result)

        ids = connection
          .bulk_insert('test', [{ number: 10 }], return_ids: true)

        expect(ids).to eq([10])
      end

      it 'allows setting the upsert to do nothing' do
        expect(dummy_connection)
          .to receive(:execute)
          .with(/ON CONFLICT DO NOTHING/)

        connection
          .bulk_insert('test', [{ number: 10 }], on_conflict: :do_nothing)
      end
    end
  end

  describe '#create_connection_pool' do
    it 'creates a new connection pool with specific pool size' do
      pool = connection.create_connection_pool(5)

      begin
        expect(pool)
          .to be_kind_of(ActiveRecord::ConnectionAdapters::ConnectionPool)

        expect(pool.db_config.pool).to eq(5)
      ensure
        pool.disconnect!
      end
    end

    it 'allows setting of a custom hostname' do
      pool = connection.create_connection_pool(5, '127.0.0.1')

      begin
        expect(pool.db_config.host).to eq('127.0.0.1')
      ensure
        pool.disconnect!
      end
    end

    it 'allows setting of a custom hostname and port' do
      pool = connection.create_connection_pool(5, '127.0.0.1', 5432)

      begin
        expect(pool.db_config.host).to eq('127.0.0.1')
        expect(pool.db_config.configuration_hash[:port]).to eq(5432)
      ensure
        pool.disconnect!
      end
    end
  end

  describe '#with_connection_pool' do
    it 'creates a new connection pool and disconnect it after used' do
      closed_pool = nil

      connection.with_connection_pool(1) do |pool|
        pool.with_connection do |connection|
          connection.execute('SELECT 1 AS value')
        end

        expect(pool).to be_connected

        closed_pool = pool
      end

      expect(closed_pool).not_to be_connected
    end

    it 'disconnects the pool even an exception was raised' do
      error = Class.new(RuntimeError)
      closed_pool = nil

      begin
        connection.with_connection_pool(1) do |pool|
          pool.with_connection do |connection|
            connection.execute('SELECT 1 AS value')
          end

          closed_pool = pool

          raise error, 'boom'
        end
      rescue error
      end

      expect(closed_pool).not_to be_connected
    end
  end

  describe '#cached_column_exists?' do
    it 'only retrieves data once' do
      expect(connection.scope.connection)
        .to receive(:columns)
        .once.and_call_original

      2.times do
        expect(connection.cached_column_exists?(:projects, :id)).to be_truthy
        expect(connection.cached_column_exists?(:projects, :bogus_column)).to be_falsey
      end
    end
  end

  describe '#cached_table_exists?' do
    it 'only retrieves data once per table' do
      expect(connection.scope.connection)
        .to receive(:data_source_exists?)
        .with(:projects)
        .once.and_call_original

      expect(connection.scope.connection)
        .to receive(:data_source_exists?)
        .with(:bogus_table_name)
        .once.and_call_original

      2.times do
        expect(connection.cached_table_exists?(:projects)).to be_truthy
        expect(connection.cached_table_exists?(:bogus_table_name)).to be_falsey
      end
    end

    it 'returns false when database does not exist' do
      expect(connection.scope).to receive(:connection) do
        raise ActiveRecord::NoDatabaseError, 'broken'
      end

      expect(connection.cached_table_exists?(:projects)).to be(false)
    end
  end

  describe '#exists?' do
    it 'returns true if `ActiveRecord::Base.connection` succeeds' do
      expect(connection.scope).to receive(:connection)

      expect(connection.exists?).to be(true)
    end

    it 'returns false if `ActiveRecord::Base.connection` fails' do
      expect(connection.scope).to receive(:connection) do
        raise ActiveRecord::NoDatabaseError, 'broken'
      end

      expect(connection.exists?).to be(false)
    end
  end

  describe '#system_id' do
    it 'returns the PostgreSQL system identifier' do
      expect(connection.system_id).to be_an_instance_of(Integer)
    end
  end

  describe '#get_write_location' do
    it 'returns a string' do
      expect(connection.get_write_location(connection.scope.connection))
        .to be_a(String)
    end

    it 'returns nil if there are no results' do
      expect(connection.get_write_location(double(select_all: []))).to be_nil
    end
  end
end
