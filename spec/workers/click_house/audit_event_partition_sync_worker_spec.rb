# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::AuditEventPartitionSyncWorker, feature_category: :compliance_management do
  let(:worker) { described_class.new }

  subject(:perform) { worker.perform("audit_events") }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [:audit_events] }

    context 'when worker is enqueued' do
      it 'calls ::ClickHouse::SyncStrategies::AuditEventSyncStrategy with correct args' do
        expect_next_instance_of(::ClickHouse::SyncStrategies::AuditEventSyncStrategy) do |instance|
          expect(instance).to receive(:execute).with("audit_events")
        end

        perform
      end

      it 'correctly logs the metadata on done' do
        expect_next_instance_of(::ClickHouse::SyncStrategies::AuditEventSyncStrategy) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :ok })
        end

        expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :ok })

        perform
      end
    end
  end
end
