# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::AlterWebhookDeletedAuditEvent, feature_category: :webhooks do
  let(:migration) do
    described_class.new(
      start_id: audit_event1.id,
      end_id: audit_event4.id,
      batch_table: :audit_events,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  let(:audit_events) { partitioned_table(:audit_events) }
  let(:attributes) do
    { author_id: 1,
      entity_id: 2,
      entity_type: "Group",
      target_id: 5 }
  end

  let!(:audit_event1) do
    audit_events.create!(attributes.merge(id: 1, target_type: 'SystemHook', target_details: "Hook 1"))
  end

  let!(:audit_event2) do
    audit_events.create!(attributes.merge(id: 2, target_type: 'GroupHook', target_details: "http://example2@example.com"))
  end

  let!(:audit_event3) do
    audit_events.create!(attributes.merge(id: 3, target_type: 'ProjectHook', target_details: "http://example3@example.com"))
  end

  let!(:audit_event4) do
    audit_events.create!(attributes.merge(id: 4, target_type: 'User', target_details: "Administrator"))
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'alters target details column' do
      perform_migration

      audit_events = AuditEvent.all.sort

      expect(audit_events[0].target_details).to eq("Hook 1")
      expect(audit_events[1].target_details).to eq("Hook 5")
      expect(audit_events[2].target_details).to eq("Hook 5")
      expect(audit_events[3].target_details).to eq("Administrator")
    end
  end
end
