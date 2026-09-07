# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillAgentTypeOnDuoWorkflowSessionArtifacts,
  migration: :gitlab_main_org, feature_category: :compliance_management do
  let!(:batched_migration) { described_class::MIGRATION }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:workflows) { table(:duo_workflows_workflows) }
  let(:artifacts) { table(:duo_workflow_session_artifacts) }

  let(:organization) { organizations.create!(name: 'Org', path: 'org') }
  let(:group_namespace) { namespaces.create!(name: 'Group', path: 'group', organization_id: organization.id) }
  let(:project_namespace) do
    namespaces.create!(name: 'Project NS', path: 'project-ns', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(namespace_id: group_namespace.id, project_namespace_id: project_namespace.id,
      organization_id: organization.id)
  end

  let(:user) do
    users.create!(email: 'u@example.com', projects_limit: 10, username: 'u', organization_id: organization.id)
  end

  # Rows in the batch table, so the migration is queued as active with real
  # cursor bounds instead of finishing immediately over an empty table.
  let!(:first_artifact) { create_artifact }
  let!(:last_artifact) { create_artifact }

  def create_artifact
    workflow = workflows.create!(project_id: project.id, user_id: user.id, goal: 'goal')

    artifacts.create!(
      workflow_id: workflow.id, user_id: user.id, project_id: project.id, namespace_id: project_namespace.id,
      status: 0, workflow_definition: 'software_development',
      workflow_created_at: Time.current, workflow_updated_at: Time.current
    )
  end

  it 'schedules a new batched background migration over the table' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main_org,
          table_name: :duo_workflow_session_artifacts,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          status_name: :active,
          min_cursor: [first_artifact.id],
          max_cursor: [last_artifact.id]
        )
      }
    end
  end
end
