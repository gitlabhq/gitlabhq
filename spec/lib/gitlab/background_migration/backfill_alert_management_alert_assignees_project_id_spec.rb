# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillAlertManagementAlertAssigneesProjectId,
  feature_category: :incident_management,
  schema: 20240910151504 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :alert_management_alert_assignees }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :alert_management_alerts }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :alert_id }
  end
end
