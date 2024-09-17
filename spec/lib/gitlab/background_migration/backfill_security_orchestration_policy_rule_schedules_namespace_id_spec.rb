# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSecurityOrchestrationPolicyRuleSchedulesNamespaceId,
  feature_category: :security_policy_management,
  schema: 20240816130540 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :security_orchestration_policy_rule_schedules }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :security_orchestration_policy_configurations }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :security_orchestration_policy_configuration_id }
  end
end
