# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProcessSyncEventsWorker, feature_category: :cell do
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group) }
  let!(:group3) { create(:group) }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker'

  describe 'deduplication' do
    before do
      stub_const("Ci::ProcessSyncEventsService::BATCH_SIZE", 2)
    end

    it 'has the `until_executed` deduplicate strategy' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    end

    it 'has the option to reschedule once if deduplicated and a TTL of 1 minute' do
      expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once, ttl: 1.minute })
    end

    it 'expect the job to enqueue itself again if there was more items to be processed', :sidekiq_inline do
      Namespaces::SyncEvent.delete_all # delete the sync_events that have been created by triggers of previous groups
      create_list(:sync_event, 3, namespace_id: group1.id)
      # It's called more than twice, because the job deduplication and rescheduling calls the perform_async again
      expect(described_class).to receive(:perform_async).at_least(:twice).and_call_original
      expect do
        described_class.perform_async
      end.to change { Namespaces::SyncEvent.count }.from(3).to(0)
    end
  end

  describe '#perform' do
    subject(:perform) { worker.perform }

    before do
      group2.update!(parent: group1)
      group3.update!(parent: group2)
    end

    it 'consumes all sync events' do
      expect { perform }.to change { Namespaces::SyncEvent.count }.from(5).to(0)
    end

    it 'syncs namespace hierarchy traversal ids' do
      expect { perform }.to change { Ci::NamespaceMirror.all }.to contain_exactly(
        an_object_having_attributes(namespace_id: group1.id, traversal_ids: [group1.id]),
        an_object_having_attributes(namespace_id: group2.id, traversal_ids: [group1.id, group2.id]),
        an_object_having_attributes(namespace_id: group3.id, traversal_ids: [group1.id, group2.id, group3.id])
      )
    end

    it 'logs the service result', :aggregate_failures do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:estimated_total_events, 5)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:consumable_events, 5)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:processed_events, 5)

      perform
    end
  end
end
