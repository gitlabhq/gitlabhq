# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::SyncStrategies::AuditEventSyncStrategy, '#execute', :click_house, feature_category: :compliance_management do
  let(:strategy) { described_class.new }

  let_it_be(:group_audit_event) { create(:audit_event, :group_event) }
  let_it_be(:group_audit_event_2) { create(:audit_event, :group_event) }
  let_it_be(:project_audit_event) { create(:audit_event, :project_event) }
  let_it_be(:project_audit_event_2) { create(:audit_event, :project_event) }

  subject(:execute) { strategy.execute(:audit_events) }

  it 'inserts all records' do
    expect(execute).to eq({ status: :processed, records_inserted: 4, reached_end_of_table: true })

    expected_records = [
      an_audit_event_sync_model(group_audit_event),
      an_audit_event_sync_model(group_audit_event_2),
      an_audit_event_sync_model(project_audit_event),
      an_audit_event_sync_model(project_audit_event_2)
    ]

    audit_events = ClickHouse::Client.select('SELECT * FROM audit_events FINAL ORDER BY id', :main)

    expect(audit_events).to match(expected_records)

    last_processed_id = ClickHouse::SyncCursor.cursor_for(:audit_events)
    expect(last_processed_id).to eq(project_audit_event_2.id)
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(sync_audit_events_to_clickhouse: false)
    end

    it 'inserts no records' do
      expect(execute).to eq({ status: :disabled })

      audit_events = ClickHouse::Client.select('SELECT * FROM audit_events FINAL ORDER BY id', :main)

      expect(audit_events).to be_empty
    end
  end

  context 'when the clickhouse database is not configured' do
    before do
      allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)
    end

    it 'inserts no records' do
      expect(execute).to eq({ status: :disabled })

      audit_events = ClickHouse::Client.select('SELECT * FROM audit_events FINAL ORDER BY id', :main)

      expect(audit_events).to be_empty
    end
  end

  def an_audit_event_sync_model(audit_event)
    hash_including(
      'id' => audit_event.id,
      'entity_type' => audit_event.entity_type,
      'entity_id' => audit_event.entity_id.to_s,
      'author_id' => audit_event.author_id.to_s,
      'target_id' => audit_event.target_id.to_s,
      'target_type' => audit_event.target_type,
      'entity_path' => audit_event.entity_path,
      'target_details' => audit_event.target_details,
      'ip_address' => audit_event.ip_address,
      'details' => audit_event.details.to_json,
      'created_at' => a_value_within(0.01).of(audit_event.created_at))
  end
end
