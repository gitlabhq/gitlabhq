# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::AddModifiedToApprovalMergeRequestRule, schema: 20200817195628 do
  let(:determine_if_rules_are_modified) { described_class.new }

  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab') }
  let(:projects) { table(:projects) }
  let(:normal_project) { projects.create!(namespace_id: namespace.id) }
  let(:overridden_project) { projects.create!(namespace_id: namespace.id) }
  let(:rules) { table(:approval_merge_request_rules) }
  let(:project_rules) { table(:approval_project_rules) }
  let(:sources) { table(:approval_merge_request_rule_sources) }
  let(:merge_requests) { table(:merge_requests) }
  let(:groups) { table(:namespaces) }
  let(:mr_groups) { table(:approval_merge_request_rules_groups) }
  let(:project_groups) { table(:approval_project_rules_groups) }

  before do
    project_rule = project_rules.create!(project_id: normal_project.id, approvals_required: 3, name: 'test rule')
    overridden_project_rule = project_rules.create!(project_id: overridden_project.id, approvals_required: 5, name: 'other test rule')
    overridden_project_rule_two = project_rules.create!(project_id: overridden_project.id, approvals_required: 7, name: 'super cool rule')

    merge_request = merge_requests.create!(target_branch: 'feature', source_branch: 'default', source_project_id: normal_project.id, target_project_id: normal_project.id)
    overridden_merge_request = merge_requests.create!(target_branch: 'feature-2', source_branch: 'default', source_project_id: overridden_project.id, target_project_id: overridden_project.id)

    merge_rule = rules.create!(merge_request_id: merge_request.id, approvals_required: 3, name: 'test rule')
    overridden_merge_rule = rules.create!(merge_request_id: overridden_merge_request.id, approvals_required: 6, name: 'other test rule')
    overridden_merge_rule_two = rules.create!(merge_request_id: overridden_merge_request.id, approvals_required: 7, name: 'super cool rule')

    sources.create!(approval_project_rule_id: project_rule.id, approval_merge_request_rule_id: merge_rule.id)
    sources.create!(approval_project_rule_id: overridden_project_rule.id, approval_merge_request_rule_id: overridden_merge_rule.id)
    sources.create!(approval_project_rule_id: overridden_project_rule_two.id, approval_merge_request_rule_id: overridden_merge_rule_two.id)

    group1 = groups.create!(name: "group1", path: "test_group1", type: 'Group')
    group2 = groups.create!(name: "group2", path: "test_group2", type: 'Group')
    group3 = groups.create!(name: "group3", path: "test_group3", type: 'Group')

    project_groups.create!(approval_project_rule_id: overridden_project_rule_two.id, group_id: group1.id)
    project_groups.create!(approval_project_rule_id: overridden_project_rule_two.id, group_id: group2.id)
    project_groups.create!(approval_project_rule_id: overridden_project_rule_two.id, group_id: group3.id)

    mr_groups.create!(approval_merge_request_rule_id: overridden_merge_rule.id, group_id: group1.id)
    mr_groups.create!(approval_merge_request_rule_id: overridden_merge_rule_two.id, group_id: group2.id)
  end

  describe '#perform' do
    it 'changes the correct rules' do
      original_count = rules.all.count

      determine_if_rules_are_modified.perform(rules.minimum(:id), rules.maximum(:id))

      results = rules.where(modified_from_project_rule: true)

      expect(results.count).to eq 2
      expect(results.collect(&:name)).to eq(['other test rule', 'super cool rule'])
      expect(rules.count).to eq original_count
    end
  end
end
