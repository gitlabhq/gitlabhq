# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateOrganizationPushRulesSyncTriggersToIncludePushRuleId, feature_category: :source_code_management do
  let!(:organization) { table(:organizations).create!(name: "Organization", path: "organization") }
  let!(:another_organization) do
    table(:organizations).create!(name: 'another_organization', path: 'another_organization')
  end

  let(:push_rules_table) { table(:push_rules) }
  let(:organization_push_rules_table) { table(:organization_push_rules) }

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

    [push_rules_table, organization_push_rules_table].each(&:reset_column_information)
  end

  describe '#up' do
    it 'creates a organization_push_rules from push_rule with synced IDs' do
      migrate_and_reset_registry_columns!
      expect(organization_push_rules_table.count).to eq(0)

      push_rule = push_rules_table.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)
      push_rules_table.create!(**push_rules_attributes, organization_id: another_organization.id)

      expect(organization_push_rules_table.count).to eq(1)
      expect(organization_push_rules_table.last.id).to eq(push_rule.id)
      expect(organization_push_rules_table.last.commit_message_regex).to eq('Default commit message')
    end

    it 'does not create organization_push_rule when push_rule has no organization_id' do
      migrate_and_reset_registry_columns!

      push_rules_table.create!(**push_rules_attributes, is_sample: true, organization_id: nil)
      push_rules_table.create!(**push_rules_attributes, organization_id: nil)

      expect(organization_push_rules_table.count).to eq(0)
    end

    it 'updates an organization_push_rule record if the organization has a global push_rule' do
      migrate_and_reset_registry_columns!

      global_push_rule = push_rules_table.create!(
        **push_rules_attributes,
        is_sample: true,
        organization_id: organization.id
      )
      push_rules_table.create!(**push_rules_attributes, organization_id: another_organization.id)

      expect(organization_push_rules_table.last.commit_message_regex).to eq('Default commit message')

      global_push_rule.update!(commit_message_regex: 'This message should change in organization_push_rule')

      expect(organization_push_rules_table.count).to eq(1)
      expect(organization_push_rules_table.last.commit_message_regex)
        .to eq('This message should change in organization_push_rule')
    end

    it 'deletes an organization_push_rule record if global push_rule is deleted' do
      migrate_and_reset_registry_columns!

      global_push_rule = push_rules_table.create!(
        **push_rules_attributes,
        is_sample: true,
        organization_id: organization.id
      )
      push_rules_table.create!(**push_rules_attributes, organization_id: another_organization.id)

      global_push_rule.destroy!
      expect(organization_push_rules_table.count).to eq(0)
    end
  end

  describe '#down' do
    it 'creates a organization_push_rules from push_rule with out of sync IDs' do
      migrate_and_reset_registry_columns!
      schema_migrate_down!

      expect(organization_push_rules_table.count).to eq(0)

      push_rules_table.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)

      expect(organization_push_rules_table.count).to eq(1)
      expect(organization_push_rules_table.last.commit_message_regex).to eq('Default commit message')
    end
  end
end
