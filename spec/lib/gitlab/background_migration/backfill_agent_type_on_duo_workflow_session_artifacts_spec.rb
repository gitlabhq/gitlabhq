# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillAgentTypeOnDuoWorkflowSessionArtifacts,
  feature_category: :compliance_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:workflows) { table(:duo_workflows_workflows) }
  let(:artifacts) { table(:duo_workflow_session_artifacts) }

  let(:organization) { organizations.create!(name: 'Org', path: 'org') }

  let(:group_namespace) do
    namespaces.create!(name: 'Group', path: 'group', organization_id: organization.id)
  end

  let(:project_namespace) do
    namespaces.create!(name: 'Project NS', path: 'project-ns', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(
      namespace_id: group_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:user) do
    users.create!(email: 'u@example.com', projects_limit: 10, username: 'u', organization_id: organization.id)
  end

  let!(:external_artifact) { create_artifact(create_workflow(agent_type: 'claude-code')) }
  let!(:dap_artifact) { create_artifact(create_workflow(agent_type: nil)) }

  def create_workflow(agent_type:)
    workflows.create!(
      project_id: project.id, user_id: user.id, goal: 'goal',
      agent_type: agent_type, environment: agent_type ? 6 : nil
    )
  end

  def create_artifact(workflow, agent_type: nil)
    artifacts.create!(
      workflow_id: workflow.id, user_id: user.id, project_id: project.id,
      namespace_id: project_namespace.id, status: 0, agent_type: agent_type,
      workflow_definition: agent_type ? 'external_agent' : 'software_development',
      workflow_created_at: Time.current, workflow_updated_at: Time.current
    )
  end

  def perform_migration(end_id: artifacts.maximum(:id))
    described_class.new(
      start_cursor: [artifacts.minimum(:id)],
      end_cursor: [end_id],
      batch_table: :duo_workflow_session_artifacts,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  # Row version: unchanged means the UPDATE never touched the row, so the
  # source-side `agent_type IS NOT NULL` guard did its job.
  def row_version(artifact)
    artifacts.connection.select_value("SELECT xmin FROM duo_workflow_session_artifacts WHERE id = #{artifact.id}")
  end

  describe '#perform' do
    it 'backfills agent_type from the workflow for external sessions only', :aggregate_failures do
      dap_version = row_version(dap_artifact)

      perform_migration

      expect(external_artifact.reload.agent_type).to eq('claude-code')
      expect(dap_artifact.reload.agent_type).to be_nil
      expect(row_version(dap_artifact)).to eq(dap_version)
    end

    it 'stops at the end cursor' do
      later_artifact = create_artifact(create_workflow(agent_type: 'claude-code'))

      perform_migration(end_id: external_artifact.id)

      expect(later_artifact.reload.agent_type).to be_nil
    end

    it 'does not overwrite a populated agent_type in a sub-batch that backfills other rows', :aggregate_failures do
      populated_artifact = create_artifact(create_workflow(agent_type: 'claude-code'), agent_type: 'opencode')

      perform_migration

      expect(populated_artifact.reload.agent_type).to eq('opencode')
      expect(external_artifact.reload.agent_type).to eq('claude-code')
    end

    it 'is idempotent' do
      perform_migration

      expect { perform_migration }.not_to change { artifacts.order(:id).pluck(:agent_type) }
    end
  end
end
