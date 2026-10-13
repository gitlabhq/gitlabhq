# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::SyncEvent, feature_category: :cell do
  describe '.enqueue_worker' do
    it 'schedules Namespaces::ProcessSyncEventsWorker job' do
      expect(::Namespaces::ProcessSyncEventsWorker).to receive(:perform_async)
      described_class.enqueue_worker
    end
  end

  describe '.unprocessed_events' do
    it 'returns only events not yet synced to ci' do
      create_list(:namespace, 2)
      synced = described_class.first
      synced.update_column(:ci_synced, true)

      expect(described_class.unprocessed_events).not_to include(synced)
      expect(described_class.unprocessed_events.count).to eq(1)
    end
  end

  describe '.mark_records_processed' do
    let_it_be(:namespaces) { create_list(:namespace, 3) }

    it 'deletes the given events and keeps the others' do
      events = described_class.order_by_id_asc.to_a

      described_class.mark_records_processed(events.first(2))

      expect(described_class.all).to contain_exactly(events.last)
      expect(events.last.reload.ci_synced).to be(false)
    end
  end

  describe '.upper_bound_count' do
    it 'returns 0 when there are no records in the table' do
      expect(described_class.upper_bound_count).to eq(0)
    end

    it 'returns an estimated number of the records in the database' do
      create_list(:namespace, 3)
      expect(described_class.upper_bound_count).to eq(3)
    end

    it 'ignores events already synced to ci' do
      create_list(:namespace, 3)
      described_class.order_by_id_asc.first.update_column(:ci_synced, true)

      expect(described_class.upper_bound_count).to eq(2)
    end
  end
end
