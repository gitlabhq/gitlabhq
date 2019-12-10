# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database do
  before do
    stub_const('MigrationTest', Class.new { include Gitlab::Database })
  end

  describe '.config' do
    it 'returns a Hash' do
      expect(described_class.config).to be_an_instance_of(Hash)
    end
  end

  describe '.adapter_name' do
    it 'returns the name of the adapter' do
      expect(described_class.adapter_name).to be_an_instance_of(String)
    end

    it 'returns Unknown when using anything else' do
      allow(described_class).to receive(:postgresql?).and_return(false)

      expect(described_class.human_adapter_name).to eq('Unknown')
    end
  end

  describe '.human_adapter_name' do
    it 'returns PostgreSQL when using PostgreSQL' do
      expect(described_class.human_adapter_name).to eq('PostgreSQL')
    end
  end

  describe '.postgresql?' do
    subject { described_class.postgresql? }

    it { is_expected.to satisfy { |val| val == true || val == false } }
  end

  describe '.version' do
    around do |example|
      described_class.instance_variable_set(:@version, nil)
      example.run
      described_class.instance_variable_set(:@version, nil)
    end

    context "on postgresql" do
      it "extracts the version number" do
        allow(described_class).to receive(:database_version)
          .and_return("PostgreSQL 9.4.4 on x86_64-apple-darwin14.3.0")

        expect(described_class.version).to eq '9.4.4'
      end
    end

    it 'memoizes the result' do
      count = ActiveRecord::QueryRecorder
        .new { 2.times { described_class.version } }
        .count

      expect(count).to eq(1)
    end
  end

  describe '.postgresql_9_or_less?' do
    it 'returns true when using postgresql 8.4' do
      allow(described_class).to receive(:version).and_return('8.4')
      expect(described_class.postgresql_9_or_less?).to eq(true)
    end

    it 'returns true when using PostgreSQL 9.6' do
      allow(described_class).to receive(:version).and_return('9.6')

      expect(described_class.postgresql_9_or_less?).to eq(true)
    end

    it 'returns false when using PostgreSQL 10 or newer' do
      allow(described_class).to receive(:version).and_return('10')

      expect(described_class.postgresql_9_or_less?).to eq(false)
    end
  end

  describe '.postgresql_minimum_supported_version?' do
    it 'returns false when using PostgreSQL 9.5' do
      allow(described_class).to receive(:version).and_return('9.5')

      expect(described_class.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns true when using PostgreSQL 9.6' do
      allow(described_class).to receive(:version).and_return('9.6')

      expect(described_class.postgresql_minimum_supported_version?).to eq(true)
    end

    it 'returns true when using PostgreSQL 10 or newer' do
      allow(described_class).to receive(:version).and_return('10')

      expect(described_class.postgresql_minimum_supported_version?).to eq(true)
    end
  end

  describe '.replication_slots_supported?' do
    it 'returns false when using PostgreSQL 9.3' do
      allow(described_class).to receive(:version).and_return('9.3.1')

      expect(described_class.replication_slots_supported?).to eq(false)
    end

    it 'returns true when using PostgreSQL 9.4.0 or newer' do
      allow(described_class).to receive(:version).and_return('9.4.0')

      expect(described_class.replication_slots_supported?).to eq(true)
    end
  end

  describe '.pg_wal_lsn_diff' do
    it 'returns old name when using PostgreSQL 9.6' do
      allow(described_class).to receive(:version).and_return('9.6')

      expect(described_class.pg_wal_lsn_diff).to eq('pg_xlog_location_diff')
    end

    it 'returns new name when using PostgreSQL 10 or newer' do
      allow(described_class).to receive(:version).and_return('10')

      expect(described_class.pg_wal_lsn_diff).to eq('pg_wal_lsn_diff')
    end
  end

  describe '.pg_current_wal_insert_lsn' do
    it 'returns old name when using PostgreSQL 9.6' do
      allow(described_class).to receive(:version).and_return('9.6')

      expect(described_class.pg_current_wal_insert_lsn).to eq('pg_current_xlog_insert_location')
    end

    it 'returns new name when using PostgreSQL 10 or newer' do
      allow(described_class).to receive(:version).and_return('10')

      expect(described_class.pg_current_wal_insert_lsn).to eq('pg_current_wal_insert_lsn')
    end
  end

  describe '.pg_last_wal_receive_lsn' do
    it 'returns old name when using PostgreSQL 9.6' do
      allow(described_class).to receive(:version).and_return('9.6')

      expect(described_class.pg_last_wal_receive_lsn).to eq('pg_last_xlog_receive_location')
    end

    it 'returns new name when using PostgreSQL 10 or newer' do
      allow(described_class).to receive(:version).and_return('10')

      expect(described_class.pg_last_wal_receive_lsn).to eq('pg_last_wal_receive_lsn')
    end
  end

  describe '.pg_last_wal_replay_lsn' do
    it 'returns old name when using PostgreSQL 9.6' do
      allow(described_class).to receive(:version).and_return('9.6')

      expect(described_class.pg_last_wal_replay_lsn).to eq('pg_last_xlog_replay_location')
    end

    it 'returns new name when using PostgreSQL 10 or newer' do
      allow(described_class).to receive(:version).and_return('10')

      expect(described_class.pg_last_wal_replay_lsn).to eq('pg_last_wal_replay_lsn')
    end
  end

  describe '.pg_last_xact_replay_timestamp' do
    it 'returns pg_last_xact_replay_timestamp' do
      expect(described_class.pg_last_xact_replay_timestamp).to eq('pg_last_xact_replay_timestamp')
    end
  end

  describe '.nulls_last_order' do
    it { expect(described_class.nulls_last_order('column', 'ASC')).to eq 'column ASC NULLS LAST'}
    it { expect(described_class.nulls_last_order('column', 'DESC')).to eq 'column DESC NULLS LAST'}
  end

  describe '.nulls_first_order' do
    it { expect(described_class.nulls_first_order('column', 'ASC')).to eq 'column ASC NULLS FIRST'}
    it { expect(described_class.nulls_first_order('column', 'DESC')).to eq 'column DESC NULLS FIRST'}
  end

  describe '.with_connection_pool' do
    it 'creates a new connection pool and disconnect it after used' do
      closed_pool = nil

      described_class.with_connection_pool(1) do |pool|
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
        described_class.with_connection_pool(1) do |pool|
          pool.with_connection do |connection|
            connection.execute('SELECT 1 AS value')
          end

          closed_pool = pool

          raise error.new('boom')
        end
      rescue error
      end

      expect(closed_pool).not_to be_connected
    end
  end

  describe '.bulk_insert' do
    before do
      allow(described_class).to receive(:connection).and_return(connection)
      allow(described_class).to receive(:version).and_return(version)
      allow(connection).to receive(:quote_column_name, &:itself)
      allow(connection).to receive(:quote, &:itself)
      allow(connection).to receive(:execute)
    end

    let(:connection) { double(:connection) }

    let(:rows) do
      [
        { a: 1, b: 2, c: 3 },
        { c: 6, a: 4, b: 5 }
      ]
    end

    let_it_be(:version) { 9.6 }

    it 'does nothing with empty rows' do
      expect(connection).not_to receive(:execute)

      described_class.bulk_insert('test', [])
    end

    it 'uses the ordering from the first row' do
      expect(connection).to receive(:execute) do |sql|
        expect(sql).to include('(1, 2, 3)')
        expect(sql).to include('(4, 5, 6)')
      end

      described_class.bulk_insert('test', rows)
    end

    it 'quotes column names' do
      expect(connection).to receive(:quote_column_name).with(:a)
      expect(connection).to receive(:quote_column_name).with(:b)
      expect(connection).to receive(:quote_column_name).with(:c)

      described_class.bulk_insert('test', rows)
    end

    it 'quotes values' do
      1.upto(6) do |i|
        expect(connection).to receive(:quote).with(i)
      end

      described_class.bulk_insert('test', rows)
    end

    it 'does not quote values of a column in the disable_quote option' do
      [1, 2, 4, 5].each do |i|
        expect(connection).to receive(:quote).with(i)
      end

      described_class.bulk_insert('test', rows, disable_quote: :c)
    end

    it 'does not quote values of columns in the disable_quote option' do
      [2, 5].each do |i|
        expect(connection).to receive(:quote).with(i)
      end

      described_class.bulk_insert('test', rows, disable_quote: [:a, :c])
    end

    it 'handles non-UTF-8 data' do
      expect { described_class.bulk_insert('test', [{ a: "\255" }]) }.not_to raise_error
    end

    context 'when using PostgreSQL' do
      it 'allows the returning of the IDs of the inserted rows' do
        result = double(:result, values: [['10']])

        expect(connection)
          .to receive(:execute)
          .with(/RETURNING id/)
          .and_return(result)

        ids = described_class
          .bulk_insert('test', [{ number: 10 }], return_ids: true)

        expect(ids).to eq([10])
      end

      context 'with version >= 9.5' do
        it 'allows setting the upsert to do nothing' do
          expect(connection)
            .to receive(:execute)
            .with(/ON CONFLICT DO NOTHING/)

          described_class
            .bulk_insert('test', [{ number: 10 }], on_conflict: :do_nothing)
        end
      end

      context 'with version < 9.5' do
        let(:version) { 9.4 }
        it 'refuses setting the upsert' do
          expect(connection)
            .not_to receive(:execute)
            .with(/ON CONFLICT/)

          described_class
            .bulk_insert('test', [{ number: 10 }], on_conflict: :do_nothing)
        end
      end
    end
  end

  describe '.create_connection_pool' do
    it 'creates a new connection pool with specific pool size' do
      pool = described_class.create_connection_pool(5)

      begin
        expect(pool)
          .to be_kind_of(ActiveRecord::ConnectionAdapters::ConnectionPool)

        expect(pool.spec.config[:pool]).to eq(5)
      ensure
        pool.disconnect!
      end
    end

    it 'allows setting of a custom hostname' do
      pool = described_class.create_connection_pool(5, '127.0.0.1')

      begin
        expect(pool.spec.config[:host]).to eq('127.0.0.1')
      ensure
        pool.disconnect!
      end
    end

    it 'allows setting of a custom hostname and port' do
      pool = described_class.create_connection_pool(5, '127.0.0.1', 5432)

      begin
        expect(pool.spec.config[:host]).to eq('127.0.0.1')
        expect(pool.spec.config[:port]).to eq(5432)
      ensure
        pool.disconnect!
      end
    end
  end

  describe '.cached_column_exists?' do
    it 'only retrieves data once' do
      expect(ActiveRecord::Base.connection).to receive(:columns).once.and_call_original

      2.times do
        expect(described_class.cached_column_exists?(:projects, :id)).to be_truthy
        expect(described_class.cached_column_exists?(:projects, :bogus_column)).to be_falsey
      end
    end
  end

  describe '.cached_table_exists?' do
    it 'only retrieves data once per table' do
      expect(ActiveRecord::Base.connection).to receive(:data_source_exists?).with(:projects).once.and_call_original
      expect(ActiveRecord::Base.connection).to receive(:data_source_exists?).with(:bogus_table_name).once.and_call_original

      2.times do
        expect(described_class.cached_table_exists?(:projects)).to be_truthy
        expect(described_class.cached_table_exists?(:bogus_table_name)).to be_falsey
      end
    end
  end

  describe '#true_value' do
    it 'returns correct value' do
      expect(described_class.true_value).to eq "'t'"
    end
  end

  describe '#false_value' do
    it 'returns correct value' do
      expect(described_class.false_value).to eq "'f'"
    end
  end

  describe '.read_only?' do
    it 'returns false' do
      expect(described_class.read_only?).to be_falsey
    end
  end

  describe '.db_read_only?' do
    before do
      allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original
    end

    it 'detects a read only database' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT pg_is_in_recovery()').and_return([{ "pg_is_in_recovery" => "t" }])

      expect(described_class.db_read_only?).to be_truthy
    end

    it 'detects a read only database' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT pg_is_in_recovery()').and_return([{ "pg_is_in_recovery" => true }])

      expect(described_class.db_read_only?).to be_truthy
    end

    it 'detects a read write database' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT pg_is_in_recovery()').and_return([{ "pg_is_in_recovery" => "f" }])

      expect(described_class.db_read_only?).to be_falsey
    end

    it 'detects a read write database' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT pg_is_in_recovery()').and_return([{ "pg_is_in_recovery" => false }])

      expect(described_class.db_read_only?).to be_falsey
    end
  end

  describe '#sanitize_timestamp' do
    let(:max_timestamp) { Time.at((1 << 31) - 1) }

    subject { described_class.sanitize_timestamp(timestamp) }

    context 'with a timestamp smaller than MAX_TIMESTAMP_VALUE' do
      let(:timestamp) { max_timestamp - 10.years }

      it 'returns the given timestamp' do
        expect(subject).to eq(timestamp)
      end
    end

    context 'with a timestamp larger than MAX_TIMESTAMP_VALUE' do
      let(:timestamp) { max_timestamp + 1.second }

      it 'returns MAX_TIMESTAMP_VALUE' do
        expect(subject).to eq(max_timestamp)
      end
    end
  end
end
