# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::DatabaseConnection, :reestablished_active_record_base, feature_category: :backup_restore do
  let(:connection_name) { 'main' }
  let(:snapshot_id_pattern) { /[A-Z0-9]{8}-[A-Z0-9]{8}-[0-9]/ }

  subject(:backup_connection) { described_class.new(connection_name) }

  describe '#initialize' do
    it 'initializes database_configuration with the provided connection_name' do
      expect(Backup::DatabaseConfiguration).to receive(:new).with(connection_name).and_call_original

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
end
