# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LockAcquisition::SessionGuard, feature_category: :database do
  let(:pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

  subject(:guard) { described_class.new(pool: pool) }

  before do
    allow(connection).to receive(:execute)
    allow(connection).to receive(:quote) { |value| "'#{value}'" }
    allow(connection).to receive(:select_value).with('SHOW statement_timeout').and_return('2min')
  end

  describe '.remove_and_disconnect' do
    it 'does not raise when disconnecting fails' do
      allow(pool).to receive(:remove)
      allow(connection).to receive(:disconnect!).and_raise(PG::UnableToSend, 'gone')

      expect { described_class.remove_and_disconnect(pool, connection) }.not_to raise_error
    end
  end

  describe '#harden' do
    it 'applies the safety settings to the session', :aggregate_failures do
      guard.harden(connection)

      expect(connection).to have_received(:execute).with(/SET statement_timeout = '500ms'/)
      expect(connection).to have_received(:execute).with(/SET application_name = 'lock_acquisition_watcher'/)
    end
  end

  describe '#reassert' do
    it 'restores the safety timeout first, so a partial failure never leaves a poll unbounded' do
      statements = []
      allow(connection).to receive(:execute) { |sql| statements << sql }

      guard.reassert(connection)

      expect(statements.first).to include('statement_timeout')
    end
  end

  describe '#release' do
    it 'restores the original statement_timeout and checks the connection back in', :aggregate_failures do
      guard.harden(connection)
      allow(pool).to receive(:checkin)

      guard.release(connection, discard: false)

      expect(connection).to have_received(:execute).with("SET statement_timeout = '2min'")
      expect(connection).to have_received(:execute).with('RESET application_name')
      expect(pool).to have_received(:checkin).with(connection)
    end

    it 'leaves statement_timeout alone when harden never captured it', :aggregate_failures do
      allow(pool).to receive(:checkin)

      guard.release(connection, discard: false)

      expect(connection).not_to have_received(:execute).with(/statement_timeout/)
      expect(connection).to have_received(:execute).with('RESET application_name')
      expect(pool).to have_received(:checkin).with(connection)
    end

    it 'does not raise when checking the connection back in fails' do
      guard.harden(connection)
      allow(pool).to receive(:checkin).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect { guard.release(connection, discard: false) }.not_to raise_error
    end

    it 'discards the connection instead of checking it in when the reset fails', :aggregate_failures do
      guard.harden(connection)
      allow(pool).to receive(:checkin)
      allow(pool).to receive(:remove)
      allow(connection).to receive(:disconnect!)
      allow(connection).to receive(:execute)
        .with("SET statement_timeout = '2min'").and_raise(PG::UnableToSend, 'gone')

      guard.release(connection, discard: false)

      expect(pool).to have_received(:remove).with(connection)
      expect(connection).to have_received(:disconnect!)
      expect(pool).not_to have_received(:checkin)
    end

    it 'removes a discarded connection without touching its unknown session state', :aggregate_failures do
      allow(pool).to receive(:remove)
      allow(connection).to receive(:disconnect!)

      guard.release(connection, discard: true)

      expect(pool).to have_received(:remove).with(connection)
      expect(connection).to have_received(:disconnect!)
      expect(connection).not_to have_received(:execute)
    end

    it 'still disconnects when removing from the pool fails' do
      allow(pool).to receive(:remove).and_raise(ActiveRecord::ConnectionNotEstablished)
      allow(connection).to receive(:disconnect!)

      guard.release(connection, discard: true)

      expect(connection).to have_received(:disconnect!)
    end
  end
end
