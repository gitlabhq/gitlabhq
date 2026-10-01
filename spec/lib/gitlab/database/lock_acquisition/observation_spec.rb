# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LockAcquisition::Observation, feature_category: :database do
  describe '.capture' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    it 'parses the snapshot row', :aggregate_failures do
      allow(connection).to receive(:select_one).and_return(
        'blocking_pids' => '222,111,111',
        'queued_waiters' => '3',
        'unfiltered_waiters' => '5',
        'ddl_wait_event_type' => 'Lock'
      )

      observation = described_class.capture(connection, ddl_pid: 1, db_oid: 2, quoted_backend_start: "'x'")

      expect(observation.blocking_pids).to match_array([111, 222])
      expect(observation.queued_waiters).to eq(3)
      expect(observation.unfiltered_waiters).to eq(5)
      expect(observation).to be_in_lock_wait
    end

    it 'is not in a lock wait for any other wait event type' do
      allow(connection).to receive(:select_one).and_return(
        'blocking_pids' => '', 'queued_waiters' => '0', 'unfiltered_waiters' => '0', 'ddl_wait_event_type' => nil
      )

      observation = described_class.capture(connection, ddl_pid: 1, db_oid: 2, quoted_backend_start: "'x'")

      expect(observation).not_to be_in_lock_wait
    end
  end

  describe '.sql' do
    it 'bills only relation-level waiters, keeping the unfiltered count for the ceiling' do
      sql = described_class.sql(1, 2, "'x'")

      expect(sql.scan("locktype = 'relation'").size).to eq(1)
    end

    it 'counts only waiters whose wait began at or after ours' do
      sql = described_class.sql(1, 2, "'x'")

      expect(sql.scan(/w\.waitstart >=/).size).to eq(2)
    end
  end
end
