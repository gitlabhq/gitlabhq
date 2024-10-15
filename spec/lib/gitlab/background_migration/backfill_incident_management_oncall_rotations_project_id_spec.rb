# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIncidentManagementOncallRotationsProjectId,
  feature_category: :incident_management,
  schema: 20240916132822 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :incident_management_oncall_rotations }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :incident_management_oncall_schedules }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :oncall_schedule_id }
  end
end
