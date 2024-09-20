# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::ActiveRecordConnectionPool, feature_category: :shared do
  let(:db_config) { ApplicationRecord.connection_pool.db_config }
  let(:pool_config) do
    ActiveRecord::ConnectionAdapters::PoolConfig.new(ActiveRecord::Base, db_config, :writing, :default)
  end

  let(:done_connection) do
    conn = nil
    Thread.new do
      conn = pool.checkout
      pool.checkin(conn)
    end.join

    conn
  end

  subject(:pool) { ActiveRecord::ConnectionAdapters::ConnectionPool.new(pool_config) }

  describe '#disconnect_without_verify!' do
    it 'does not call verify!' do
      expect(done_connection).not_to receive(:verify!)

      pool.disconnect_without_verify!

      expect(pool.connections.count).to eq(0)
    end
  end

  describe '#disconnect!' do
    it 'calls verify on the connection' do
      expect(done_connection).to receive(:verify!).and_call_original

      pool.disconnect!

      expect(pool.connections.count).to eq(0)
    end
  end
end
