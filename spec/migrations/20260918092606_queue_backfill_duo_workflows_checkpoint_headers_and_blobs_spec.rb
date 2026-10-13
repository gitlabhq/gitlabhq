# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillDuoWorkflowsCheckpointHeadersAndBlobs,
  migration: :gitlab_main_org, feature_category: :duo_agent_platform do
  let!(:batched_migration) { described_class::MIGRATION }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:workflows) { table(:duo_workflows_workflows) }
  let(:checkpoints) { partitioned_table(:p_duo_workflows_checkpoints, by: :created_at, strategy: :daily) }

  let(:organization) { organizations.create!(name: 'Org', path: 'org') }
  let(:group_namespace) { namespaces.create!(name: 'Group', path: 'group', organization_id: organization.id) }
  let(:project_namespace) do
    namespaces.create!(name: 'Project NS', path: 'project-ns', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(
      namespace_id: group_namespace.id, project_namespace_id: project_namespace.id, organization_id: organization.id
    )
  end

  let(:user) do
    users.create!(email: 'u@example.com', projects_limit: 10, username: 'u', organization_id: organization.id)
  end

  let(:workflow) { workflows.create!(project_id: project.id, user_id: user.id, goal: 'goal') }

  # Rows in the batch table, so the migration is queued as active with real
  # cursor bounds instead of finishing immediately over an empty table.
  let!(:first_checkpoint) { create_checkpoint('ts-1') }
  let!(:last_checkpoint) { create_checkpoint('ts-2') }

  def create_checkpoint(thread_ts)
    checkpoints.create!(
      workflow_id: workflow.id, project_id: project.id, thread_ts: thread_ts,
      checkpoint: { 'v' => 1 }, metadata: { 'source' => 'loop' }
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
          table_name: :p_duo_workflows_checkpoints,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          status_name: :active,
          min_cursor: [first_checkpoint.id, first_checkpoint.created_at.as_json],
          max_cursor: [last_checkpoint.id, last_checkpoint.created_at.as_json]
        )
      }
    end
  end
end
