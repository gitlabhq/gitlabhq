# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateSyncPushRulesToProjectPushRulesTrigger, feature_category: :source_code_management do
  let!(:organization) { table(:organizations).create!(name: "Organization", path: "organization") }
  let!(:namespace) do
    table(:namespaces).create!(name: "Namespace", path: "namespace", type: 'Group', organization_id: organization.id)
  end

  let!(:project_namespace) do
    table(:namespaces).create!(
      name: 'Project',
      path: 'project',
      type: 'Project',
      organization_id: organization.id,
      parent_id: namespace.id
    )
  end

  let!(:another_project_namespace) do
    table(:namespaces).create!(
      name: 'Another Project',
      path: 'another-project',
      type: 'Project',
      organization_id: organization.id,
      parent_id: namespace.id
    )
  end

  let!(:project) do
    table(:projects).create!(
      name: 'Project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:another_project) do
    table(:projects).create!(
      name: 'Another Project',
      path: 'another-project',
      namespace_id: namespace.id,
      project_namespace_id: another_project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:push_rules_table) { table(:push_rules) }
  let(:project_push_rules_table) { table(:project_push_rules) }

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

    [push_rules_table, project_push_rules_table].each(&:reset_column_information)
  end

  describe '#up' do
    it 'creates a project_push_rules from push_rule with synced IDs' do
      migrate_and_reset_registry_columns!
      expect(project_push_rules_table.count).to eq(0)

      push_rule = push_rules_table.create!(**push_rules_attributes, project_id: project.id)
      push_rules_table.create!(**push_rules_attributes, project_id: another_project.id)

      expect(project_push_rules_table.count).to eq(2)
      expect(project_push_rules_table.first.id).to eq(push_rule.id)
      expect(project_push_rules_table.first.commit_message_regex).to eq('Default commit message')
    end

    it 'syncs all fields correctly between push_rules and project_push_rules', :freeze_time do
      migrate_and_reset_registry_columns!
      expect(project_push_rules_table.count).to eq(0)

      push_rule = push_rules_table.create!(**push_rules_attributes, project_id: project.id)
      project_push_rule = project_push_rules_table.find_by(id: push_rule.id)

      shared_columns = push_rules_table.column_names & project_push_rules_table.column_names

      shared_columns.each do |column|
        expect(project_push_rule[column]).to eq(push_rule[column])
      end
    end

    it 'does not create project_push_rule when push_rule has no project_id' do
      migrate_and_reset_registry_columns!

      push_rules_table.create!(**push_rules_attributes, project_id: nil)
      push_rules_table.create!(**push_rules_attributes, project_id: nil)

      expect(project_push_rules_table.count).to eq(0)
    end

    it 'updates a project_push_rule record if the project has a push_rule', :freeze_time do
      migrate_and_reset_registry_columns!

      push_rule = push_rules_table.create!(
        **push_rules_attributes,
        project_id: project.id
      )

      expect(project_push_rules_table.count).to eq(1)

      push_rule.update!(commit_message_regex: 'This message should change in project_push_rule')

      project_push_rule = project_push_rules_table.find_by(project_id: project.id)
      expect(project_push_rule.commit_message_regex).to eq('This message should change in project_push_rule')

      shared_columns = push_rules_table.column_names & project_push_rules_table.column_names
      shared_columns.each do |column|
        expect(project_push_rule[column]).to eq(push_rule[column])
      end
    end

    it 'deletes a project_push_rule record if push_rule is deleted' do
      migrate_and_reset_registry_columns!

      push_rule = push_rules_table.create!(
        **push_rules_attributes,
        project_id: project.id
      )
      push_rules_table.create!(**push_rules_attributes, project_id: another_project.id)

      push_rule.destroy!
      expect(project_push_rules_table.count).to eq(1)
      expect(project_push_rules_table.first.project_id).to eq(another_project.id)
    end
  end

  describe '#down' do
    it 'removes the trigger' do
      migrate_and_reset_registry_columns!
      schema_migrate_down!

      expect(project_push_rules_table.count).to eq(0)

      push_rules_table.create!(**push_rules_attributes, project_id: project.id)

      # After migration down, trigger should not sync
      expect(project_push_rules_table.count).to eq(0)
    end
  end
end
