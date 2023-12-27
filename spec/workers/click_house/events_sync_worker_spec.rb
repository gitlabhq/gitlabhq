# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::EventsSyncWorker, feature_category: :value_stream_management do
  let(:worker) { described_class.new }

  specify do
    expect(worker.class.click_house_worker_attrs).to match(
      a_hash_including(migration_lock_ttl: ClickHouse::MigrationSupport::ExclusiveLock::DEFAULT_CLICKHOUSE_WORKER_TTL)
    )
  end

  context 'when worker is enqueued' do
    it 'calls ::ClickHouse::SyncStrategies::EventSyncStrategy with correct args' do
      expect_next_instance_of(::ClickHouse::SyncStrategies::EventSyncStrategy) do |instance|
        expect(instance).to receive(:execute)
      end

      worker.perform
    end

    it 'correctly logs the metadata on done' do
      expect_next_instance_of(::ClickHouse::SyncStrategies::EventSyncStrategy) do |instance|
        expect(instance).to receive(:execute).and_return({ status: :ok })
      end
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :ok })

      worker.perform
    end
  end
end
