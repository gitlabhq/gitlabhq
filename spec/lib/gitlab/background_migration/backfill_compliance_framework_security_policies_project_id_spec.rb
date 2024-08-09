# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillComplianceFrameworkSecurityPoliciesProjectId,
  feature_category: :security_policy_management,
  schema: 20240722095911 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :compliance_framework_security_policies }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :security_orchestration_policy_configurations }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :policy_configuration_id }
  end
end
