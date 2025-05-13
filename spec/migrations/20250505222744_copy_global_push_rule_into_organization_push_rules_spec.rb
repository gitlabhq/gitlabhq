# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CopyGlobalPushRuleIntoOrganizationPushRules, feature_category: :source_code_management do
  let(:push_rules) { table(:push_rules) }
  let(:organization_push_rules) { table(:organization_push_rules) }
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let(:push_rules_attributes) do
    {
      'organization_id' => organization.id,
      'max_file_size' => 120,
      'member_check' => true,
      'prevent_secrets' => true,
      'commit_committer_name_check' => true,
      'deny_delete_tag' => true,
      'reject_unsigned_commits' => true,
      'commit_committer_check' => true,
      'reject_non_dco_commits' => true,
      'commit_message_regex' => 'Default commit message',
      'branch_name_regex' => 'branch_name',
      'commit_message_negative_regex' => 'commit_negative_3',
      'author_email_regex' => 'test@test.com',
      'file_name_regex' => 'filename.png'
    }
  end

  let!(:global_push_rule) { push_rules.create!(is_sample: true, **push_rules_attributes) }

  def migrate_and_reset_registry_columns!
    migrate!

    [push_rules, organization_push_rules].each(&:reset_column_information)
  end

  describe '#up' do
    it 'creates an organization_push_rule record if push_rule is a global rule' do
      migrate_and_reset_registry_columns!

      organization_push_rule = organization_push_rules.last

      expect(organization_push_rule.attributes).to include(push_rules_attributes)
      expect(organization_push_rule.created_at).to be_within(1.second).of(global_push_rule.created_at)
      expect(organization_push_rule.updated_at).to be_within(1.second).of(global_push_rule.updated_at)
    end

    it 'does not create an organization_push_rule record if global rule does not exist' do
      global_push_rule.destroy!
      push_rules.create!(**push_rules_attributes)

      migrate_and_reset_registry_columns!

      expect(organization_push_rules.all).to be_empty
    end
  end

  describe '#down' do
    it 'deletes the organization_push_rule record' do
      migrate_and_reset_registry_columns!

      expect(organization_push_rules.count).to eq(1)

      schema_migrate_down!

      expect(organization_push_rules.count).to eq(0)
    end
  end
end
