# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::AuditEventsSyncWorker, '#perform', :click_house, feature_category: :compliance_management do
  let(:worker) { described_class.new }
  let(:partition_identifiers) { %w[audit_event_001 audit_event_002] }

  subject(:perform) { worker.perform }

  it_behaves_like 'an idempotent worker' do
    context 'when audit event partitions are present' do
      before do
        allow(worker).to receive(:partition_identifiers).and_return(partition_identifiers)
      end

      it 'enqueues identifiers for syncing' do
        partition_identifiers.each do |identifier|
          expect(::ClickHouse::AuditEventPartitionSyncWorker).to receive(:perform_async).with(identifier)
        end

        perform
      end

      context 'when no partition is present' do
        before do
          allow(worker).to receive(:partition_identifiers).and_return([])
        end

        it 'does not enqueue for syncing' do
          expect(::ClickHouse::AuditEventPartitionSyncWorker).not_to receive(:perform_async)

          perform
        end
      end
    end

    context 'when clickhouse is not configured' do
      before do
        allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)
      end

      it 'skips execution' do
        expect(::ClickHouse::AuditEventPartitionSyncWorker).not_to receive(:perform_async)

        perform
      end
    end

    context 'when feature flag `sync_audit_events_to_clickhouse` is disabled' do
      before do
        stub_feature_flags(sync_audit_events_to_clickhouse: false)
      end

      it 'does not enqueues for syncing' do
        expect(::ClickHouse::AuditEventPartitionSyncWorker).not_to receive(:perform_async)

        perform
      end
    end
  end
end
