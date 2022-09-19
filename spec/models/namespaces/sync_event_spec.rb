# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::SyncEvent, type: :model do
  describe '.enqueue_worker' do
    it 'schedules Namespaces::ProcessSyncEventsWorker job' do
      expect(::Namespaces::ProcessSyncEventsWorker).to receive(:perform_async)
      described_class.enqueue_worker
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
  end
end
