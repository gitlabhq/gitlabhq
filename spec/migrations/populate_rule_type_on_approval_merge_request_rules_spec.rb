# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PopulateRuleTypeOnApprovalMergeRequestRules do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:merge_requests) { table(:merge_requests) }
    let(:approval_rules) { table(:approval_merge_request_rules) }

    # We use integers here since at the time of writing CE does not yet have the
    # appropriate models and enum definitions.
    let(:regular_rule_type) { 1 }
    let(:code_owner_rule_type) { 2 }

    before do
      namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab')
      projects.create!(id: 101, namespace_id: 11, name: 'gitlab', path: 'gitlab')
      merge_requests.create!(id: 1, target_project_id: 101, source_project_id: 101, target_branch: 'feature', source_branch: 'master')

      approval_rules.create!(id: 1, merge_request_id: 1, name: "Default", code_owner: false, rule_type: regular_rule_type)
      approval_rules.create!(id: 2, merge_request_id: 1, name: "Code Owners", code_owner: true, rule_type: regular_rule_type)
    end

    it 'backfills ApprovalMergeRequestRules code_owner rule_type' do
      expect(approval_rules.where(rule_type: regular_rule_type).pluck(:id)).to contain_exactly(1, 2)
      expect(approval_rules.where(rule_type: code_owner_rule_type).pluck(:id)).to be_empty

      migrate!

      expect(approval_rules.where(rule_type: regular_rule_type).pluck(:id)).to contain_exactly(1)
      expect(approval_rules.where(rule_type: code_owner_rule_type).pluck(:id)).to contain_exactly(2)
    end
  end
end
