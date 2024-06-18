# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillApprovalProjectRulesUsersProjectId,
  feature_category: :source_code_management,
  schema: 20240501044501 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :approval_project_rules_users }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :approval_project_rules }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :approval_project_rule_id }
  end
end
