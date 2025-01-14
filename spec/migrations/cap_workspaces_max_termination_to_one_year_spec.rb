# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CapWorkspacesMaxTerminationToOneYear, feature_category: :workspaces do
  let(:user) { table(:users).create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  let!(:personal_access_token) do
    table(:personal_access_tokens).create!(
      user_id: user.id,
      name: 'token_name',
      expires_at: Time.now
    )
  end

  let(:cluster_agent) do
    table(:cluster_agents).create!(
      id: 1,
      name: 'Agent-1',
      project_id: project.id
    )
  end

  let!(:agent) do
    table(:remote_development_agent_configs).create!(
      cluster_agent_id: cluster_agent.id,
      enabled: true,
      dns_zone: 'test.workspace.me',
      project_id: project.id
    )
  end

  let!(:workspace_1) do
    table(:workspaces).create!(
      user_id: user.id,
      project_id: project.id,
      cluster_agent_id: cluster_agent.id,
      desired_state_updated_at: Time.now,
      responded_to_agent_at: Time.now,
      name: 'workspace-1',
      namespace: 'workspace_1_namespace',
      desired_state: 'Terminated',
      actual_state: 'Terminated',
      editor: 'vs-code',
      project_ref: 'devfile-ref',
      devfile_path: 'devfile-path',
      devfile: 'devfile',
      processed_devfile: 'processed_dev_file',
      url: 'workspace-url',
      deployment_resource_version: 'v1',
      personal_access_token_id: personal_access_token.id,
      max_hours_before_termination: 5760
    )
  end

  let!(:workspace_2) do
    table(:workspaces).create!(
      user_id: user.id,
      project_id: project.id,
      cluster_agent_id: cluster_agent.id,
      desired_state_updated_at: Time.now,
      responded_to_agent_at: Time.now,
      name: 'workspace-2',
      namespace: 'workspace_2_namespace',
      desired_state: 'Running',
      actual_state: 'Running',
      editor: 'vs-code',
      project_ref: 'devfile-ref',
      devfile_path: 'devfile-path',
      devfile: 'devfile',
      processed_devfile: 'processed_dev_file',
      url: 'workspace-url',
      deployment_resource_version: 'v1',
      personal_access_token_id: personal_access_token.id,
      max_hours_before_termination: 8761
    )
  end

  context 'when there exist workspace whose have a termination limit grater than the max and some less than the max' do
    it 'caps those that exceed the max and leaves the rest unchanged' do
      expect do
        migrate!
      end.to not_change { workspace_1.reload.max_hours_before_termination }.and(
        change { workspace_2.reload.max_hours_before_termination }.from(8761).to(8760)
      )
    end
  end
end
