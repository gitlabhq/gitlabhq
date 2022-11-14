# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Load balancer behavior with errors inside a transaction', :redis, :delete do
  include StubENV
  let(:model) { ActiveRecord::Base }
  let(:db_host) { model.connection_pool.db_config.host }

  let(:test_table_name) { '_test_foo' }

  before do
    # Patch in our load balancer config, simply pointing at the test database twice
    allow(Gitlab::Database::LoadBalancing::Configuration).to receive(:for_model).with(model) do |base_model|
      Gitlab::Database::LoadBalancing::Configuration.new(base_model, [db_host, db_host])
    end

    Gitlab::Database::LoadBalancing::Setup.new(model).setup

    model.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{test_table_name} (id SERIAL PRIMARY KEY, value INTEGER)
    SQL

    # The load balancer sleeps between attempts to retry a query.
    # Mocking the sleep call significantly reduces the runtime of this spec file.
    allow(model.connection.load_balancer).to receive(:sleep)
  end

  after do
    model.connection.execute(<<~SQL)
      DROP TABLE IF EXISTS #{test_table_name}
    SQL

    # reset load balancing to original state
    allow(Gitlab::Database::LoadBalancing::Configuration).to receive(:for_model).and_call_original
    Gitlab::Database::LoadBalancing::Setup.new(model).setup
  end

  def execute(conn)
    conn.execute("INSERT INTO #{test_table_name} (value) VALUES (1)")
    backend_pid = conn.execute("SELECT pg_backend_pid() AS pid").to_a.first['pid']

    # This will result in a PG error, which is not raised.
    # Instead, we retry the statement on a fresh connection (where the pid is different and it does nothing)
    # and the load balancer continues with a fresh connection and no transaction if a transaction was open previously
    conn.execute(<<~SQL)
      SELECT CASE
      WHEN pg_backend_pid() = #{backend_pid} THEN
        pg_terminate_backend(#{backend_pid})
      END
    SQL

    # This statement will execute on a new connection, and violate transaction semantics
    # if we were in a transaction before
    conn.execute("INSERT INTO #{test_table_name} (value) VALUES (2)")
  end

  context 'with the PREVENT_LOAD_BALANCER_RETRIES_IN_TRANSACTION environment variable not set' do
    it 'logs a warning when violating transaction semantics with writes' do
      conn = model.connection

      expect(::Gitlab::Database::LoadBalancing::Logger).to receive(:warn).with(hash_including(event: :transaction_leak))

      conn.transaction do
        expect(conn).to be_transaction_open

        execute(conn)

        expect(conn).not_to be_transaction_open
      end

      values = conn.execute("SELECT value FROM #{test_table_name}").to_a.map { |row| row['value'] }
      expect(values).to contain_exactly(2) # Does not include 1 because the transaction was aborted and leaked
    end

    it 'does not log a warning when no transaction is open to be leaked' do
      conn = model.connection

      expect(::Gitlab::Database::LoadBalancing::Logger)
        .not_to receive(:warn).with(hash_including(event: :transaction_leak))

      expect(conn).not_to be_transaction_open

      execute(conn)

      expect(conn).not_to be_transaction_open

      values = conn.execute("SELECT value FROM #{test_table_name}").to_a.map { |row| row['value'] }
      expect(values).to contain_exactly(1, 2) # Includes both rows because there was no transaction to roll back
    end
  end

  context 'with the PREVENT_LOAD_BALANCER_RETRIES_IN_TRANSACTION environment variable set' do
    before do
      stub_env('PREVENT_LOAD_BALANCER_RETRIES_IN_TRANSACTION' => '1')
    end

    it 'raises an exception when a retry would occur during a transaction' do
      expect(::Gitlab::Database::LoadBalancing::Logger)
        .not_to receive(:warn).with(hash_including(event: :transaction_leak))

      expect do
        model.transaction do
          execute(model.connection)
        end
      end.to raise_error(ActiveRecord::StatementInvalid) { |e| expect(e.cause).to be_a(PG::ConnectionBad) }
    end

    it 'retries when not in a transaction' do
      expect(::Gitlab::Database::LoadBalancing::Logger)
        .not_to receive(:warn).with(hash_including(event: :transaction_leak))

      expect { execute(model.connection) }.not_to raise_error
    end
  end
end
