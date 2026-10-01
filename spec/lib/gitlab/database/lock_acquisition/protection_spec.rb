# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LockAcquisition::Protection, feature_category: :database do
  let(:logger) { instance_spy(Gitlab::JsonLogger) }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
  let(:bill) { Gitlab::Database::LockAcquisition::DamageBill.new }

  subject(:protection) do
    described_class.new(
      bill: bill, count_ceiling: 5, pool: pool, ddl_pid: 12345,
      quoted_backend_start: "'2026-08-21 10:00:00+00'::timestamptz", logger: logger, log_params: {}
    )
  end

  before do
    allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(true)
  end

  # One accrual of `amount` waiters over a 1s interval = `amount`
  # stuck-seconds, staying under the blindness width cap.
  def spend(amount)
    bill.instance_variable_set(
      :@last_accrual_at, Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1.0
    )
    bill.accrue(amount, true)
  end

  describe '#ceiling_trip' do
    it 'cancels the watched session when the queue reaches the ceiling', :aggregate_failures do
      protection.ceiling_trip(connection, 5, true)

      expect(protection.verdict.canceled).to be(true)
      expect(protection.verdict.trip_reason).to eq(:pool_exhaustion)
    end

    it 'guards the cancel to the exact session, only while it waits for a lock' do
      protection.ceiling_trip(connection, 5, true)

      expect(connection).to have_received(:select_value) do |sql|
        expect(sql).to include(
          'pid = 12345',
          "backend_start = '2026-08-21 10:00:00+00'::timestamptz",
          "state = 'active'",
          "wait_event_type = 'Lock'"
        )
      end
    end

    it 'does nothing below the ceiling or outside a lock wait', :aggregate_failures do
      protection.ceiling_trip(connection, 4, true)
      protection.ceiling_trip(connection, 10, false)

      expect(protection.verdict.canceled).to be(false)
      expect(connection).not_to have_received(:select_value)
    end
  end

  describe '#budget_trip' do
    it 'trips :accumulated_wait when the run budget is spent', :aggregate_failures do
      spend(11)
      spend(11)

      protection.budget_trip(connection, 3, true)

      expect(protection.verdict.canceled).to be(true)
      expect(protection.verdict.trip_reason).to eq(:accumulated_wait)
    end

    it 'labels a window that fills on its first poll as :table_too_hot', :aggregate_failures do
      spend(11)

      protection.budget_trip(connection, 11, true)

      expect(protection.verdict.trip_reason).to eq(:table_too_hot)
    end

    it 'does nothing while the bill is under budget', :aggregate_failures do
      spend(1)

      protection.budget_trip(connection, 1, true)

      expect(protection.verdict.canceled).to be(false)
      expect(connection).not_to have_received(:select_value)
    end
  end

  describe 'trip precedence' do
    it 'stands down congestion trips once a watch loss owns the abort', :aggregate_failures do
      protection.watch_loss_cancel(connection, armed: true)
      spend(11)

      protection.ceiling_trip(connection, 9, true)
      protection.budget_trip(connection, 9, true)

      expect(protection.verdict.canceled).to be(false)
      expect(protection.verdict.trip_reason).to be_nil
    end

    it 'keeps an undelivered decision and retries it, holding the first reason', :aggregate_failures do
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(nil, true)
      spend(11)

      protection.ceiling_trip(connection, 5, true) # the wait already ended: no row matched
      expect(protection.verdict).to have_attributes(trip_reason: :pool_exhaustion, canceled: false)

      protection.budget_trip(connection, 5, true)
      expect(protection.verdict).to have_attributes(trip_reason: :pool_exhaustion, canceled: true)
    end

    it 'starts each attempt with no verdict' do
      protection.ceiling_trip(connection, 5, true)

      protection.reset_attempt!

      expect(protection.verdict).to eq(described_class::NO_VERDICT)
    end
  end

  describe '#watch_loss_cancel' do
    it 'cancels the watched wait as a dying act and records the flag', :aggregate_failures do
      protection.watch_loss_cancel(connection, armed: true)

      expect(protection.verdict.watch_lost).to be(true)
      expect(connection).to have_received(:select_value).with(/pg_cancel_backend/)
    end

    it 'claims no watch loss when the guard matched no session' do
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(nil)

      protection.watch_loss_cancel(connection, armed: true)

      expect(protection.verdict.watch_lost).to be(false)
    end

    it 'does nothing before arming', :aggregate_failures do
      protection.watch_loss_cancel(connection, armed: false)

      expect(protection.verdict.watch_lost).to be(false)
      expect(connection).not_to have_received(:select_value)
    end

    it 'stands down once a pile-up cancel was delivered' do
      protection.ceiling_trip(connection, 5, true)

      protection.watch_loss_cancel(connection, armed: true)

      expect(protection.verdict.watch_lost).to be(false)
    end

    it 'falls back to a fresh connection when the poll connection is dead', :aggregate_failures do
      fresh = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_raise(PG::UnableToSend, 'gone')
      allow(pool).to receive(:checkout).and_return(fresh)
      allow(pool).to receive(:checkin)
      allow(fresh).to receive(:transaction).and_yield
      allow(fresh).to receive(:execute)
      allow(fresh).to receive(:select_value).with(/pg_cancel_backend/).and_return(true)

      protection.watch_loss_cancel(connection, armed: true)

      expect(protection.verdict.watch_lost).to be(true)
      expect(pool).to have_received(:checkout).with(2)
      expect(fresh).to have_received(:execute).with(/SET LOCAL statement_timeout/)
      expect(pool).to have_received(:checkin).with(fresh)
    end

    it 'discards the fresh connection instead of checking it back in when the fallback fails', :aggregate_failures do
      fresh = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_raise(PG::UnableToSend, 'gone')
      allow(pool).to receive(:checkout).and_return(fresh)
      allow(pool).to receive(:checkin)
      allow(pool).to receive(:remove)
      allow(fresh).to receive(:transaction).and_yield
      allow(fresh).to receive(:execute)
      allow(fresh).to receive(:disconnect!)
      allow(fresh).to receive(:select_value)
        .with(/pg_cancel_backend/).and_raise(ActiveRecord::QueryCanceled, 'statement timeout')

      protection.watch_loss_cancel(connection, armed: true)

      expect(protection.verdict.watch_lost).to be(false)
      expect(pool).to have_received(:remove).with(fresh)
      expect(fresh).to have_received(:disconnect!)
      expect(pool).not_to have_received(:checkin).with(fresh)
    end

    it 'claims no watch loss when the cancel fails on both connections' do
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_raise(PG::UnableToSend, 'gone')
      allow(pool).to receive(:checkout).and_raise(ActiveRecord::ConnectionTimeoutError, 'pool exhausted')

      protection.watch_loss_cancel(connection, armed: true)

      expect(protection.verdict.watch_lost).to be(false)
    end
  end
end
