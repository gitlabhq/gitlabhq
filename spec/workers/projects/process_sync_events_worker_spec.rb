# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProcessSyncEventsWorker do
  let!(:group) { create(:group) }
  let!(:project) { create(:project) }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker'

  describe '#perform' do
    subject(:perform) { worker.perform }

    before do
      project.update!(namespace: group)
    end

    it 'consumes all sync events' do
      expect { perform }.to change(Projects::SyncEvent, :count).from(2).to(0)
    end

    it 'syncs project namespace id' do
      expect { perform }.to change(Ci::ProjectMirror, :all).to contain_exactly(
        an_object_having_attributes(namespace_id: group.id)
      )
    end

    it 'logs the service result', :aggregate_failures do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:estimated_total_events, 2)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:consumable_events, 2)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:processed_events, 2)

      perform
    end
  end
end
