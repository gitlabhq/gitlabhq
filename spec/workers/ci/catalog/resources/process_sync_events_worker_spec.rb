# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::ProcessSyncEventsWorker, feature_category: :pipeline_composition do
  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker'

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has the option to reschedule once if deduplicated and a TTL of 1 minute' do
    expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once, ttl: 1.minute })
  end

  describe '#perform' do
    let_it_be(:project) { create(:project, name: 'Old Name') }
    let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

    before_all do
      create(:ci_catalog_resource_sync_event, catalog_resource: resource, status: :processed)
      create_list(:ci_catalog_resource_sync_event, 2, catalog_resource: resource)
      # PG trigger adds an event for this update
      project.update!(name: 'New Name', description: 'Test', visibility_level: Gitlab::VisibilityLevel::INTERNAL)
    end

    subject(:perform) { worker.perform }

    it 'consumes all sync events' do
      expect { perform }.to change { Ci::Catalog::Resources::SyncEvent.status_pending.count }
        .from(3).to(0)
    end

    it 'syncs the denormalized columns of catalog resource with the project' do
      perform

      expect(resource.reload.name).to eq(project.name)
      expect(resource.reload.description).to eq(project.description)
      expect(resource.reload.visibility_level).to eq(project.visibility_level)
    end

    it 'logs the service result', :aggregate_failures do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:estimated_total_events, 3)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:consumable_events, 3)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:processed_events, 3)

      perform
    end
  end
end
