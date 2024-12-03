# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIncidentManagementIssuableEscalationStatusesNamespaceId,
  feature_category: :incident_management,
  schema: 20241202145035 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :incident_management_issuable_escalation_statuses }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
