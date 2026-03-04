# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateProjectPushRulesTriggerToUseNextval, feature_category: :source_code_management do
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

  let!(:project) do
    table(:projects).create!(
      name: 'Project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:push_rules_table) { table(:push_rules) }
  let(:project_push_rules_table) { table(:project_push_rules) }

  def sequence_value
    ApplicationRecord.connection.select_value(
      "SELECT last_value FROM pg_sequences WHERE sequencename = 'project_push_rules_id_seq'"
    )
  end

  around do |example|
    Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
      Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
        example.run
      end
    end
  end

  describe '#up' do
    before do
      migrate!
      push_rules_table.reset_column_information
      project_push_rules_table.reset_column_information
    end

    it 'advances the sequence when a new push rule is inserted via trigger' do
      push_rules_table.create!(project_id: project.id, created_at: Time.current, updated_at: Time.current)
      project_push_rule = project_push_rules_table.find_by(project_id: project.id)

      expect(sequence_value).to be >= project_push_rule.id
    end

    it 'syncs the push rule data to project_push_rules' do
      push_rule = push_rules_table.create!(project_id: project.id, created_at: Time.current, updated_at: Time.current)
      project_push_rule = project_push_rules_table.find_by(project_id: project.id)

      expect(project_push_rule).to be_present
      expect(project_push_rule.project_id).to eq(push_rule.project_id)
    end

    it 'does not change the sequence when a push rule is updated' do
      push_rules_table.create!(project_id: project.id, created_at: Time.current, updated_at: Time.current)
      value_before = sequence_value

      push_rules_table.find_by(project_id: project.id).update!(max_file_size: 100)

      expect(sequence_value).to eq(value_before)
    end
  end

  describe '#down' do
    before do
      migrate!
      schema_migrate_down!
      push_rules_table.reset_column_information
      project_push_rules_table.reset_column_information
    end

    it 'restores the original trigger that copies push_rules id' do
      push_rule = push_rules_table.create!(project_id: project.id, created_at: Time.current, updated_at: Time.current)
      project_push_rule = project_push_rules_table.find_by(project_id: project.id)

      expect(project_push_rule.id).to eq(push_rule.id)
    end
  end
end
