# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillScanResultPoliciesProjectId,
  feature_category: :security_policy_management,
  schema: 20250301125533 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :scan_result_policies }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :security_orchestration_policy_configurations }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :security_orchestration_policy_configuration_id }
  end
end
