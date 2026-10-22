# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::PinConnectionKeepsLock, feature_category: :database do
  let(:pool) { ApplicationRecord.connection_pool }
  let(:connection) { pool.lease_connection }

  context 'when the connection is already pinned with a lock' do
    it 'keeps the lock the outer pin installed' do
      outer_lock = connection.lock
      expect(outer_lock).not_to equal(ActiveSupport::Concurrency::NullLock)

      pool.pin_connection!(true)
      begin
        expect(connection.lock).to equal(outer_lock)
      ensure
        pool.unpin_connection!
      end
    end
  end

  context 'when the connection is already pinned without a lock' do
    it 'installs a lock' do
      connection.lock_thread = nil

      pool.pin_connection!(true)
      begin
        expect(connection.lock).not_to equal(ActiveSupport::Concurrency::NullLock)
      ensure
        pool.unpin_connection!
      end
    ensure
      connection.lock_thread = ActiveSupport::IsolatedExecutionState.context
    end
  end

  context 'when the nested pin asks for no lock' do
    it 'keeps the lock the outer pin installed' do
      outer_lock = connection.lock

      pool.pin_connection!(false)
      begin
        expect(connection.lock).to equal(outer_lock)
      ensure
        pool.unpin_connection!
      end
    end
  end
end
