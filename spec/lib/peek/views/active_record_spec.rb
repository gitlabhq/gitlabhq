# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::ActiveRecord, :request_store do
  subject { Peek.views.find { |v| v.instance_of?(Peek::Views::ActiveRecord) } }

  let(:connection_replica) { double(:connection_replica) }
  let(:connection_primary_1) { double(:connection_primary) }
  let(:connection_primary_2) { double(:connection_primary) }
  let(:connection_unknown) { double(:connection_unknown) }

  let(:event_1) do
    {
      name: 'SQL',
      sql: 'SELECT * FROM users WHERE id = 10',
      cached: false,
      connection: connection_primary_1
    }
  end

  let(:event_2) do
    {
      name: 'SQL',
      sql: 'SELECT * FROM users WHERE id = 10',
      cached: true,
      connection: connection_replica
    }
  end

  let(:event_3) do
    {
      name: 'SQL',
      sql: 'UPDATE users SET admin = true WHERE id = 10',
      cached: false,
      connection: connection_primary_2
    }
  end

  let(:event_4) do
    {
      name: 'SCHEMA',
      sql: 'SELECT VERSION()',
      cached: false,
      connection: connection_unknown
    }
  end

  before do
    allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
    allow(connection_replica).to receive(:transaction_open?).and_return(false)
    allow(connection_primary_1).to receive(:transaction_open?).and_return(false)
    allow(connection_primary_2).to receive(:transaction_open?).and_return(true)
    allow(connection_unknown).to receive(:transaction_open?).and_return(false)
  end

  context 'when database load balancing is not enabled' do
    it 'subscribes and store data into peek views' do
      Timecop.freeze(2021, 2, 23, 10, 0) do
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 1.second, '1', event_1)
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 2.seconds, '2', event_2)
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 3.seconds, '3', event_3)
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 4.seconds, '4', event_4)
      end

      expect(subject.results).to match(
        calls: 4,
        summary: {
          "Cached" => 1,
          "In a transaction" => 1
        },
        duration: '10000.00ms',
        warnings: ["active-record duration: 10000.0 over 3000"],
        details: contain_exactly(
          a_hash_including(
            start: be_a(Time),
            cached: '',
            transaction: '',
            duration: 1000.0,
            sql: 'SELECT * FROM users WHERE id = 10'
          ),
          a_hash_including(
            start: be_a(Time),
            cached: 'Cached',
            transaction: '',
            duration: 2000.0,
            sql: 'SELECT * FROM users WHERE id = 10'
          ),
          a_hash_including(
            start: be_a(Time),
            cached: '',
            transaction: 'In a transaction',
            duration: 3000.0,
            sql: 'UPDATE users SET admin = true WHERE id = 10'
          ),
          a_hash_including(
            start: be_a(Time),
            cached: '',
            transaction: '',
            duration: 4000.0,
            sql: 'SELECT VERSION()'
          )
        )
      )
    end
  end

  context 'when database load balancing is enabled' do
    before do
      allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
      allow(Gitlab::Database::LoadBalancing).to receive(:db_role_for_connection).with(connection_replica).and_return(:replica)
      allow(Gitlab::Database::LoadBalancing).to receive(:db_role_for_connection).with(connection_primary_1).and_return(:primary)
      allow(Gitlab::Database::LoadBalancing).to receive(:db_role_for_connection).with(connection_primary_2).and_return(:primary)
      allow(Gitlab::Database::LoadBalancing).to receive(:db_role_for_connection).with(connection_unknown).and_return(nil)
    end

    it 'includes db role data' do
      Timecop.freeze(2021, 2, 23, 10, 0) do
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 1.second, '1', event_1)
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 2.seconds, '2', event_2)
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 3.seconds, '3', event_3)
        ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 4.seconds, '4', event_4)
      end

      expect(subject.results).to match(
        calls: 4,
        summary: {
          "Cached" => 1,
          "In a transaction" => 1,
          "Primary" => 2,
          "Replica" => 1,
          "Unknown" => 1
        },
        duration: '10000.00ms',
        warnings: ["active-record duration: 10000.0 over 3000"],
        details: contain_exactly(
          a_hash_including(
            start: be_a(Time),
            cached: '',
            transaction: '',
            duration: 1000.0,
            sql: 'SELECT * FROM users WHERE id = 10',
            db_role: 'Primary'
          ),
          a_hash_including(
            start: be_a(Time),
            cached: 'Cached',
            transaction: '',
            duration: 2000.0,
            sql: 'SELECT * FROM users WHERE id = 10',
            db_role: 'Replica'
          ),
          a_hash_including(
            start: be_a(Time),
            cached: '',
            transaction: 'In a transaction',
            duration: 3000.0,
            sql: 'UPDATE users SET admin = true WHERE id = 10',
            db_role: 'Primary'
          ),
          a_hash_including(
            start: be_a(Time),
            cached: '',
            transaction: '',
            duration: 4000.0,
            sql: 'SELECT VERSION()',
            db_role: 'Unknown'
          )
        )
      )
    end
  end
end
