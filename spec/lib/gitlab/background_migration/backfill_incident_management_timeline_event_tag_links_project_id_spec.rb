# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIncidentManagementTimelineEventTagLinksProjectId,
  feature_category: :incident_management,
  schema: 20240918102409 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :incident_management_timeline_event_tag_links }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :incident_management_timeline_event_tags }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :timeline_event_tag_id }
  end
end
