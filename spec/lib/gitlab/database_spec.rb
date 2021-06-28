# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database do
  before do
    stub_const('MigrationTest', Class.new { include Gitlab::Database })
  end

  describe 'EXTRA_SCHEMAS' do
    it 'contains only schemas starting with gitlab_ prefix' do
      described_class::EXTRA_SCHEMAS.each do |schema|
        expect(schema.to_s).to start_with('gitlab_')
      end
    end
  end

  describe '.default_pool_size' do
    before do
      allow(Gitlab::Runtime).to receive(:max_threads).and_return(7)
    end

    it 'returns the max thread size plus a fixed headroom of 10' do
      expect(described_class.default_pool_size).to eq(17)
    end

    it 'returns the max thread size plus a DB_POOL_HEADROOM if this env var is present' do
      stub_env('DB_POOL_HEADROOM', '7')

      expect(described_class.default_pool_size).to eq(14)
    end
  end

  describe '.config' do
    it 'returns a HashWithIndifferentAccess' do
      expect(described_class.config).to be_an_instance_of(HashWithIndifferentAccess)
    end

    it 'returns a default pool size' do
      expect(described_class.config).to include(pool: described_class.default_pool_size)
    end
  end

  describe '.has_config?' do
    context 'two tier database config' do
      before do
        allow(Gitlab::Application).to receive_message_chain(:config, :database_configuration, :[]).with(Rails.env)
          .and_return({ "adapter" => "postgresql", "database" => "gitlabhq_test" })
      end

      it 'returns false for primary' do
        expect(described_class.has_config?(:primary)).to eq(false)
      end

      it 'returns false for ci' do
        expect(described_class.has_config?(:ci)).to eq(false)
      end
    end

    context 'three tier database config' do
      before do
        allow(Gitlab::Application).to receive_message_chain(:config, :database_configuration, :[]).with(Rails.env)
          .and_return({
            "primary" => { "adapter" => "postgresql", "database" => "gitlabhq_test" },
            "ci" => { "adapter" => "postgresql", "database" => "gitlabhq_test_ci" }
          })
      end

      it 'returns true for primary' do
        expect(described_class.has_config?(:primary)).to eq(true)
      end

      it 'returns true for ci' do
        expect(described_class.has_config?(:ci)).to eq(true)
      end

      it 'returns false for non-existent' do
        expect(described_class.has_config?(:nonexistent)).to eq(false)
      end
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

  describe '.system_id' do
    it 'returns the PostgreSQL system identifier' do
      expect(described_class.system_id).to be_an_instance_of(Integer)
    end
  end

  describe '.disable_prepared_statements' do
    around do |example|
      original_config = ::Gitlab::Database.config

      example.run

      ActiveRecord::Base.establish_connection(original_config)
    end

    it 'disables prepared statements' do
      ActiveRecord::Base.establish_connection(::Gitlab::Database.config.merge(prepared_statements: true))
      expect(ActiveRecord::Base.connection.prepared_statements).to eq(true)

      expect(ActiveRecord::Base).to receive(:establish_connection)
        .with(a_hash_including({ 'prepared_statements' => false })).and_call_original

      described_class.disable_prepared_statements

      expect(ActiveRecord::Base.connection.prepared_statements).to eq(false)
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

  describe '.postgresql_minimum_supported_version?' do
    it 'returns false when using PostgreSQL 10' do
      allow(described_class).to receive(:version).and_return('10')

      expect(described_class.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns false when using PostgreSQL 11' do
      allow(described_class).to receive(:version).and_return('11')

      expect(described_class.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns true when using PostgreSQL 12' do
      allow(described_class).to receive(:version).and_return('12')

      expect(described_class.postgresql_minimum_supported_version?).to eq(true)
    end
  end

  describe '.check_postgres_version_and_print_warning' do
    subject { described_class.check_postgres_version_and_print_warning }

    it 'prints a warning if not compliant with minimum postgres version' do
      allow(described_class).to receive(:postgresql_minimum_supported_version?).and_return(false)

      expect(Kernel).to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'doesnt print a warning if compliant with minimum postgres version' do
      allow(described_class).to receive(:postgresql_minimum_supported_version?).and_return(true)

      expect(Kernel).not_to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'doesnt print a warning in Rails runner environment' do
      allow(described_class).to receive(:postgresql_minimum_supported_version?).and_return(false)
      allow(Gitlab::Runtime).to receive(:rails_runner?).and_return(true)

      expect(Kernel).not_to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'ignores ActiveRecord errors' do
      allow(described_class).to receive(:postgresql_minimum_supported_version?).and_raise(ActiveRecord::ActiveRecordError)

      expect { subject }.not_to raise_error
    end

    it 'ignores Postgres errors' do
      allow(described_class).to receive(:postgresql_minimum_supported_version?).and_raise(PG::Error)

      expect { subject }.not_to raise_error
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

          raise error, 'boom'
        end
      rescue error
      end

      expect(closed_pool).not_to be_connected
    end
  end

  describe '.bulk_insert' do
    before do
      allow(described_class).to receive(:connection).and_return(connection)
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

      it 'allows setting the upsert to do nothing' do
        expect(connection)
          .to receive(:execute)
          .with(/ON CONFLICT DO NOTHING/)

        described_class
          .bulk_insert('test', [{ number: 10 }], on_conflict: :do_nothing)
      end
    end
  end

  describe '.create_connection_pool' do
    it 'creates a new connection pool with specific pool size' do
      pool = described_class.create_connection_pool(5)

      begin
        expect(pool)
          .to be_kind_of(ActiveRecord::ConnectionAdapters::ConnectionPool)

        expect(pool.db_config.pool).to eq(5)
      ensure
        pool.disconnect!
      end
    end

    it 'allows setting of a custom hostname' do
      pool = described_class.create_connection_pool(5, '127.0.0.1')

      begin
        expect(pool.db_config.host).to eq('127.0.0.1')
      ensure
        pool.disconnect!
      end
    end

    it 'allows setting of a custom hostname and port' do
      pool = described_class.create_connection_pool(5, '127.0.0.1', 5432)

      begin
        expect(pool.db_config.host).to eq('127.0.0.1')
        expect(pool.db_config.configuration_hash[:port]).to eq(5432)
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

    it 'returns false when database does not exist' do
      expect(ActiveRecord::Base).to receive(:connection) { raise ActiveRecord::NoDatabaseError, 'broken' }

      expect(described_class.cached_table_exists?(:projects)).to be(false)
    end
  end

  describe '.exists?' do
    it 'returns true if `ActiveRecord::Base.connection` succeeds' do
      expect(ActiveRecord::Base).to receive(:connection)

      expect(described_class.exists?).to be(true)
    end

    it 'returns false if `ActiveRecord::Base.connection` fails' do
      expect(ActiveRecord::Base).to receive(:connection) { raise ActiveRecord::NoDatabaseError, 'broken' }

      expect(described_class.exists?).to be(false)
    end
  end

  describe '.get_write_location' do
    it 'returns a string' do
      connection = ActiveRecord::Base.connection

      expect(described_class.get_write_location(connection)).to be_a(String)
    end

    it 'returns nil if there are no results' do
      connection = double(select_all: [])

      expect(described_class.get_write_location(connection)).to be_nil
    end
  end

  describe '.dbname' do
    it 'returns the dbname for the connection' do
      connection = ActiveRecord::Base.connection

      expect(described_class.dbname(connection)).to be_a(String)
      expect(described_class.dbname(connection)).to eq(connection.pool.db_config.database)
    end

    context 'when the pool is a NullPool' do
      it 'returns unknown' do
        connection = double(:active_record_connection, pool: ActiveRecord::ConnectionAdapters::NullPool.new)

        expect(described_class.dbname(connection)).to eq('unknown')
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

    it 'detects a read-only database' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT pg_is_in_recovery()').and_return([{ "pg_is_in_recovery" => "t" }])

      expect(described_class.db_read_only?).to be_truthy
    end

    it 'detects a read-only database' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT pg_is_in_recovery()').and_return([{ "pg_is_in_recovery" => true }])

      expect(described_class.db_read_only?).to be_truthy
    end

    it 'detects a read-write database' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT pg_is_in_recovery()').and_return([{ "pg_is_in_recovery" => "f" }])

      expect(described_class.db_read_only?).to be_falsey
    end

    it 'detects a read-write database' do
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

  describe 'ActiveRecordBaseTransactionMetrics' do
    def subscribe_events
      events = []

      begin
        subscriber = ActiveSupport::Notifications.subscribe('transaction.active_record') do |e|
          events << e
        end

        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      events
    end

    context 'without a transaction block' do
      it 'does not publish a transaction event' do
        events = subscribe_events do
          User.first
        end

        expect(events).to be_empty
      end
    end

    context 'within a transaction block' do
      it 'publishes a transaction event' do
        events = subscribe_events do
          ActiveRecord::Base.transaction do
            User.first
          end
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0
        expect(event.payload).to a_hash_including(
          connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
        )
      end
    end

    context 'within an empty transaction block' do
      it 'publishes a transaction event' do
        events = subscribe_events do
          ActiveRecord::Base.transaction {}
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0
        expect(event.payload).to a_hash_including(
          connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
        )
      end
    end

    context 'within a nested transaction block' do
      it 'publishes multiple transaction events' do
        events = subscribe_events do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.transaction do
              ActiveRecord::Base.transaction do
                User.first
              end
            end
          end
        end

        expect(events.length).to be(3)

        events.each do |event|
          expect(event).not_to be_nil
          expect(event.duration).to be > 0.0
          expect(event.payload).to a_hash_including(
            connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
          )
        end
      end
    end

    context 'within a cancelled transaction block' do
      it 'publishes multiple transaction events' do
        events = subscribe_events do
          ActiveRecord::Base.transaction do
            User.first
            raise ActiveRecord::Rollback
          end
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0
        expect(event.payload).to a_hash_including(
          connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
        )
      end
    end
  end
end
