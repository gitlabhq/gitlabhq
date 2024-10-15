# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillApprovalProjectRulesProtectedBranchesProjectId,
  feature_category: :source_code_management,
  schema: 20240930160023 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :approval_project_rules_protected_branches }
    let(:batch_column) { :approval_project_rule_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :approval_project_rules }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :approval_project_rule_id }
  end
end
