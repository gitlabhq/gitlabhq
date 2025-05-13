# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreatePushRulesSyncTriggers, feature_category: :source_code_management do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:another_organization) do
    table(:organizations).create!(name: 'another_organization', path: 'another_organization')
  end

  let(:push_rules) { table(:push_rules) }
  let(:organization_push_rules) { table(:organization_push_rules) }

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

    [push_rules, organization_push_rules].each(&:reset_column_information)
  end

  describe '#up' do
    it 'creates an organization_push_rule record if push_rule is a global rule' do
      expect(organization_push_rules.count).to eq(0)

      migrate_and_reset_registry_columns!

      # A global rule has 'is_sample' attribute set to true
      push_rules.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)
      push_rules.create!(**push_rules_attributes, organization_id: another_organization.id)

      expect(organization_push_rules.all.count).to eq(1)
      expect(organization_push_rules.last.organization_id).to eq(organization.id)
    end

    it 'does not create organization_push_rule when push_rule has no organization_id' do
      migrate_and_reset_registry_columns!

      push_rules.create!(**push_rules_attributes, is_sample: true, organization_id: nil)
      push_rules.create!(**push_rules_attributes, organization_id: nil)

      expect(organization_push_rules.all.count).to eq(0)
    end

    it 'updates an organization_push_rule record if the organization has a global push_rule' do
      migrate_and_reset_registry_columns!

      global_push_rule = push_rules.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)
      push_rules.create!(**push_rules_attributes, organization_id: another_organization.id)

      expect(organization_push_rules.last.commit_message_regex).to eq('Default commit message')

      global_push_rule.update!(commit_message_regex: 'This message should change in organization_push_rule')

      expect(organization_push_rules.all.count).to eq(1)
      expect(organization_push_rules.last.commit_message_regex)
        .to eq('This message should change in organization_push_rule')
    end

    it 'deletes an organization_push_rule record if global push_rule is deleted' do
      migrate_and_reset_registry_columns!

      global_push_rule = push_rules.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)
      push_rules.create!(**push_rules_attributes, organization_id: another_organization.id)

      global_push_rule.destroy!
      expect(organization_push_rules.all.count).to eq(0)
    end
  end

  describe '#down' do
    it 'does not create an organization_push_rule record if global push_rule is created' do
      migrate_and_reset_registry_columns!

      expect(organization_push_rules.count).to eq(0)

      schema_migrate_down!

      push_rules.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)
      expect(organization_push_rules.all.count).to eq(0)
      expect(push_rules.all.count).to eq(1)
    end

    it 'does not update an organization_push_rule record if global push_rule is updated' do
      migrate_and_reset_registry_columns!

      global_push_rule = push_rules.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)
      expect(organization_push_rules.all.count).to eq(1)

      schema_migrate_down!

      global_push_rule.update!(commit_message_regex: 'This message should not change in organization_push_rule')
      expect(organization_push_rules.last.commit_message_regex).to eq('Default commit message')
    end

    it 'does not delete an organization_push_rule record if global push_rule is deleted' do
      migrate_and_reset_registry_columns!

      global_push_rule = push_rules.create!(**push_rules_attributes, is_sample: true, organization_id: organization.id)
      expect(organization_push_rules.all.count).to eq(1)

      schema_migrate_down!

      global_push_rule.destroy!
      expect(organization_push_rules.all.count).to eq(1)
    end
  end
end
