# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateGroupPushRulesSyncTriggers, feature_category: :source_code_management do
  let!(:organization) { table(:organizations).create!(name: "Organization", path: "organization") }
  let!(:group_namespace) do
    table(:namespaces).create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:user_namespace) do
    table(:namespaces).create!(name: 'user', path: 'user', type: 'User', organization_id: organization.id)
  end

  let(:push_rules_table) { table(:push_rules) }
  let(:group_push_rules_table) { table(:group_push_rules) }

  let(:push_rules_attributes) do
    {
      commit_message_regex: 'Default commit message',
      deny_delete_tag: false,
      author_email_regex: 'test@test.com',
      member_check: false,
      file_name_regex: 'filename.png',
      max_file_size: 120,
      prevent_secrets: true,
      branch_name_regex: 'branch_name',
      reject_unsigned_commits: true,
      commit_committer_check: true,
      commit_message_negative_regex: 'commit_negative_3',
      reject_non_dco_commits: false,
      commit_committer_name_check: true
    }
  end

  def migrate_and_reset_registry_columns!
    migrate!

    [push_rules_table, group_push_rules_table].each(&:reset_column_information)
  end

  describe '#up' do
    it 'creates a group_push_rules record when a push_rule is associated with a group' do
      migrate_and_reset_registry_columns!
      expect(group_push_rules_table.count).to eq(0)

      push_rule = push_rules_table.create!(**push_rules_attributes)
      group_namespace.update!(push_rule_id: push_rule.id)

      expect(group_push_rules_table.count).to eq(1)
      expect(group_push_rules_table.last.group_id).to eq(group_namespace.id)
      expect(group_push_rules_table.last.commit_message_regex).to eq('Default commit message')
    end

    it 'does not create group_push_rules for User type namespaces' do
      migrate_and_reset_registry_columns!

      push_rule = push_rules_table.create!(**push_rules_attributes)
      user_namespace.update!(push_rule_id: push_rule.id)

      expect(group_push_rules_table.count).to eq(0)
    end

    it 'updates a group_push_rules record when a push rule is updated' do
      migrate_and_reset_registry_columns!

      push_rule = push_rules_table.create!(**push_rules_attributes)
      group_namespace.update!(push_rule_id: push_rule.id)
      expect(group_push_rules_table.last.commit_message_regex).to eq('Default commit message')

      push_rule.update!(commit_message_regex: 'This message should change in group_push_rules')
      expect(group_push_rules_table.count).to eq(1)
      expect(group_push_rules_table.last.commit_message_regex)
        .to eq('This message should change in group_push_rules')
    end

    it 'deletes a group_push_rules record when a group no longer has a push rule' do
      migrate_and_reset_registry_columns!

      push_rule = push_rules_table.create!(**push_rules_attributes)
      group_namespace.update!(push_rule_id: push_rule.id)

      expect(group_push_rules_table.count).to eq(1)

      group_namespace.update!(push_rule_id: nil)
      expect(group_push_rules_table.count).to eq(0)
    end

    it 'updates group_push_rules when a group changes to a different push rule' do
      migrate_and_reset_registry_columns!

      push_rule1 = push_rules_table.create!(**push_rules_attributes)
      push_rule2 = push_rules_table.create!(
        **push_rules_attributes.merge(commit_message_regex: 'Second push rule message')
      )

      group_namespace.update!(push_rule_id: push_rule1.id)
      expect(group_push_rules_table.count).to eq(1)
      expect(group_push_rules_table.last.commit_message_regex).to eq('Default commit message')

      group_namespace.update!(push_rule_id: push_rule2.id)
      expect(group_push_rules_table.count).to eq(1)
      expect(group_push_rules_table.last.commit_message_regex).to eq('Second push rule message')
    end
  end

  describe '#down' do
    it 'does not create a group_push_rules record when a push rule is associated with a group' do
      migrate_and_reset_registry_columns!
      expect(group_push_rules_table.count).to eq(0)

      schema_migrate_down!

      push_rule = push_rules_table.create!(**push_rules_attributes)
      group_namespace.update!(push_rule_id: push_rule.id)

      expect(group_push_rules_table.count).to eq(0)
    end

    it 'does not update a group_push_rules record when a push rule is updated' do
      migrate_and_reset_registry_columns!

      push_rule = push_rules_table.create!(**push_rules_attributes)
      group_namespace.update!(push_rule_id: push_rule.id)

      expect(group_push_rules_table.count).to eq(1)
      original_message = group_push_rules_table.last.commit_message_regex

      schema_migrate_down!

      push_rule.update!(commit_message_regex: 'This message should not change in group_push_rules')

      expect(group_push_rules_table.last.commit_message_regex).to eq(original_message)
    end

    it 'does not delete a group_push_rules record when a group no longer has a push rule' do
      migrate_and_reset_registry_columns!

      push_rule = push_rules_table.create!(**push_rules_attributes)
      group_namespace.update!(push_rule_id: push_rule.id)

      expect(group_push_rules_table.count).to eq(1)

      schema_migrate_down!

      group_namespace.update!(push_rule_id: nil)

      expect(group_push_rules_table.count).to eq(1)
    end
  end
end
