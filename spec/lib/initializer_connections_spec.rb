# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InitializerConnections do
  describe '.warn_if_database_connection' do
    let(:block_result) { 'block_executed' }

    before do
      allow(described_class).to receive(:warn)
    end

    it 'returns the result of the block' do
      expect(described_class.warn_if_database_connection { block_result }).to eq(block_result)
    end

    it 'does not raise errors when a database connection is made' do
      expect do
        described_class.warn_if_database_connection { Project.first }
      end.not_to raise_error
    end

    it 'subscribes to sql.active_record notifications for the duration of the block' do
      expect(ActiveSupport::Notifications).to receive(:subscribed)
        .with(anything, "sql.active_record")
        .and_call_original

      described_class.warn_if_database_connection { block_result }
    end

    it 'outputs SQL queries and backtrace to STDOUT as a single warn call' do
      expect(described_class).to receive(:warn).once.with(
        a_string_matching(/InitializerConnections Query:.*InitializerConnections Backtrace:/m)
      )

      described_class.warn_if_database_connection { Project.first }
    end

    it 'does not warn when only connection_pool is accessed without executing SQL' do
      expect(described_class).not_to receive(:warn)

      described_class.warn_if_database_connection { Project.connection_pool }
    end
  end
end
