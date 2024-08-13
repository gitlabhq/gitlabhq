# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillApprovalGroupRulesProtectedBranchesGroupId,
  feature_category: :source_code_management,
  schema: 20240716135028 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :approval_group_rules_protected_branches }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :approval_group_rules }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :approval_group_rule_id }
  end
end
