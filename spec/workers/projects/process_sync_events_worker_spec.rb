# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProcessSyncEventsWorker do
  let!(:group) { create(:group) }
  let!(:project) { create(:project) }

  include_examples 'an idempotent worker'

  describe '#perform' do
    subject(:perform) { described_class.new.perform }

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
  end
end
