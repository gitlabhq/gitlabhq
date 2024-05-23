# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillAuditEventsStreamingEventTypeFiltersGroupId,
  feature_category: :audit_events,
  schema: 20240514140023 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :audit_events_streaming_event_type_filters }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :audit_events_external_audit_event_destinations }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :external_audit_event_destination_id }
  end
end
