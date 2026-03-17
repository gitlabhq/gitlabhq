# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::DatabaseConnection, :reestablished_active_record_base, feature_category: :backup_restore do
  let(:connection_name) { 'main' }
  let(:snapshot_id_pattern) { /[A-Z0-9]{8}-[A-Z0-9]{8}-[0-9]/ }

  subject(:backup_connection) { described_class.new(connection_name) }

  describe '#initialize' do
    it 'initializes database_configuration with the provided connection_name' do
      expect(Backup::DatabaseConfiguration).to receive(:new).with(connection_name, custom_config: nil).and_call_original

      backup_connection
    end
  end

  describe '#connection_name' do
    it 'returns the same connection name used during initialization' do
      expect(backup_connection.connection_name).to eq(connection_name)
    end
  end

  describe '#connection' do
    it 'is an instance of a ActiveRecord::Base.connection' do
      backup_connection.connection.is_a? Gitlab::Database::LoadBalancing::ConnectionProxy
    end
  end

  describe '#database_configuration' do
    it 'returns database configuration' do
      expect(backup_connection.database_configuration).to be_a(Backup::DatabaseConfiguration)
    end
  end

  describe '#snapshot_id' do
    it "returns nil when snapshot has not been triggered" do
      expect(backup_connection.snapshot_id).to be_nil
    end

    context 'when a snapshot transaction is open', :delete do
      let!(:snapshot_id) { backup_connection.export_snapshot! }

      it 'returns the snapshot_id in the expected format' do
        expect(backup_connection.snapshot_id).to match(snapshot_id_pattern)
      end

      it 'returns the snapshot_id equal to the one returned by #export_snapshot!' do
        expect(backup_connection.snapshot_id).to eq(snapshot_id)
      end

      it "returns nil after a snapshot is released" do
        backup_connection.release_snapshot!

        expect(backup_connection.snapshot_id).to be_nil
      end
    end
  end

  describe '#export_snapshot!', :delete do
    it 'returns a snapshot_id in the expected format' do
      expect(backup_connection.export_snapshot!).to match(snapshot_id_pattern)
    end

    it 'opens a transaction with correct isolation format and triggers a snapshot generation' do
      expect(backup_connection.connection).to receive(:begin_transaction).with(
        isolation: :repeatable_read
      ).and_call_original

      expect(backup_connection.connection).to receive(:select_value).with(
        "SELECT pg_export_snapshot()"
      ).and_call_original

      backup_connection.export_snapshot!
    end

    it 'disables transaction time out' do
      expect_next_instance_of(Gitlab::Database::TransactionTimeoutSettings) do |transaction_settings|
        expect(transaction_settings).to receive(:disable_timeouts).and_call_original
      end

      backup_connection.export_snapshot!
    end
  end

  describe '#release_snapshot!', :delete do
    it 'clears out existing snapshot_id' do
      snapshot_id = backup_connection.export_snapshot!

      expect { backup_connection.release_snapshot! }.to change { backup_connection.snapshot_id }
        .from(snapshot_id).to(nil)
    end

    it 'executes a transaction rollback' do
      backup_connection.export_snapshot!

      expect(backup_connection.connection).to receive(:rollback_transaction).and_call_original

      backup_connection.release_snapshot!
    end
  end

  describe '#disable_timeouts!' do
    it 'disables transaction time out' do
      expect_next_instance_of(Gitlab::Database::TransactionTimeoutSettings) do |transaction_settings|
        expect(transaction_settings).to receive(:disable_timeouts).and_call_original
      end

      backup_connection.disable_timeouts!
    end
  end

  describe '#restore_timeouts!' do
    it 'restores transaction time out' do
      expect_next_instance_of(Gitlab::Database::TransactionTimeoutSettings) do |transaction_settings|
        expect(transaction_settings).to receive(:restore_timeouts).and_call_original
      end

      backup_connection.restore_timeouts!
    end
  end

  describe '#tables' do
    it 'executes the correct SQL query against pg_tables' do
      expected_query = <<~SQL
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
      SQL

      expect(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).with(expected_query).and_return(instance_double(PG::Result, values: [
          ['users'], ['posts'], ['comments']
        ]))

      backup_connection.tables
    end

    it 'returns an array of table names' do
      allow(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).and_return(instance_double(PG::Result, values: [
          ['users'], ['posts'], ['comments']
        ]))

      result = backup_connection.tables

      expect(result).to eq(%w[users posts comments])
    end

    it 'handles empty result set' do
      allow(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).and_return(instance_double(PG::Result, values: []))

      result = backup_connection.tables

      expect(result).to eq([])
    end

    it 'flattens the results properly' do
      allow(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).and_return(instance_double(PG::Result, values: [
          ['table1'], ['table2']
        ]))

      result = backup_connection.tables

      expect(result).to be_a(Array)
      expect(result).to eq(%w[table1 table2])
    end
  end

  describe '#functions' do
    it 'executes the correct SQL query against information_schema.routines' do
      expected_query = <<~SQL
        SELECT routine_name
        FROM information_schema.routines
        WHERE routine_type = 'FUNCTION'
        AND routine_schema='public'
        AND specific_catalog=current_database()
      SQL

      expect(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).with(expected_query).and_return(instance_double(PG::Result, values: [
          ['func1'], ['func2']
        ]))

      backup_connection.functions
    end

    it 'returns an array of function names' do
      allow(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).and_return(instance_double(PG::Result, values: [
          ['my_function'], ['another_function']
        ]))

      result = backup_connection.functions

      expect(result).to eq(%w[my_function another_function])
    end

    it 'handles empty result set' do
      allow(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).and_return(instance_double(PG::Result, values: []))

      result = backup_connection.functions

      expect(result).to eq([])
    end

    it 'filters by function type and schema' do
      allow(backup_connection.instance_variable_get(:@backup_model).connection)
        .to receive(:execute).and_return(instance_double(PG::Result, values: [['func1']]))

      backup_connection.functions

      expect(backup_connection.instance_variable_get(:@backup_model).connection)
        .to have_received(:execute).with(include('routine_type = \'FUNCTION\''))
      expect(backup_connection.instance_variable_get(:@backup_model).connection)
        .to have_received(:execute).with(include('routine_schema=\'public\''))
    end
  end

  describe '#backup_model' do
    context 'with standard config' do
      it 'creates a class based on connection_name' do
        model = backup_connection.instance_variable_get(:@backup_model)

        expect(model).to be_a(Class)
      end

      it 'returns an ApplicationRecord subclass for standard configs' do
        model = backup_connection.instance_variable_get(:@backup_model)

        expect(model < ApplicationRecord).to be_truthy
      end

      it 'caches the created class' do
        model1 = backup_connection.instance_variable_get(:@backup_model)
        model2 = backup_connection.instance_variable_get(:@backup_model)

        expect(model1).to equal(model2)
      end

      it 'reuses cached class on subsequent calls' do
        first_call = backup_connection.instance_variable_get(:@backup_model)

        # Create a new instance with the same connection_name
        backup_connection2 = described_class.new(connection_name)
        second_call = backup_connection2.instance_variable_get(:@backup_model)

        expect(first_call).to equal(second_call)
      end
    end
  end

  describe 'CustomConfig' do
    let(:connection_name) { 'test_connection' }
    let(:custom_config) do
      {
        host: 'localhost',
        port: 5432,
        database: 'my_db',
        username: 'user',
        password: 'pass',
        adapter: 'postgresql'
      }
    end

    before do
      allow(ActiveRecord::Base).to receive(:establish_connection).and_return(true)
    end

    subject(:backup_connection_with_custom) do
      described_class.new('test_connection', custom_config: custom_config)
    end

    it 'passes custom_config to DatabaseConfiguration' do
      expect(Backup::DatabaseConfiguration).to receive(:new)
        .with(connection_name, custom_config: custom_config).and_call_original

      backup_connection_with_custom
    end

    it 'stores custom_config in instance variable' do
      expect(backup_connection_with_custom.instance_variable_get(:@custom_config)).to eq(custom_config)
    end

    it 'calls retrieve_connection' do
      expect(Backup::DatabaseConnection::CustomConfig).to receive(:retrieve_connection).once
      backup_connection_with_custom.connection
    end

    it 'does not respond to methods that have been undefind' do
      expect(Backup::DatabaseConnection::CustomConfig).not_to respond_to(:load_balancer)
      expect(Backup::DatabaseConnection::CustomConfig).not_to respond_to(:sticking)
      expect(Backup::DatabaseConnection::CustomConfig).to respond_to(:connection)
    end
  end
end
