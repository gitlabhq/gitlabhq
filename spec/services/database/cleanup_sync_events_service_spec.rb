# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::CleanupSyncEventsService, feature_category: :cell do
  subject(:service) { described_class.new(Namespaces::SyncEvent) }

  let!(:groups) { create_list(:group, 3) }
  let!(:events) { Namespaces::SyncEvent.order_by_id_asc.to_a }

  describe '#execute' do
    before do
      events[0].update_columns(ci_synced: true, sec_synced: true)
      events[1].update_column(:ci_synced, true)
    end

    it 'deletes the events synced by every active consumer, in batches by id' do
      stub_const("#{described_class}::BATCH_SIZE", 1)

      expect(service.execute).to eq(deleted_events: 1)

      expect(Namespaces::SyncEvent.all).to match_array(events.last(2))
    end
  end
end
