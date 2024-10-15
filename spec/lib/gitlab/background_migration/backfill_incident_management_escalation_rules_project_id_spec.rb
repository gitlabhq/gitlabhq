# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIncidentManagementEscalationRulesProjectId,
  feature_category: :incident_management,
  schema: 20240916130526 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :incident_management_escalation_rules }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :incident_management_escalation_policies }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :policy_id }
  end
end
