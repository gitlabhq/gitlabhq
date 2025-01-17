# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillUserProvidedWorkspaceVariables, feature_category: :workspaces do
  let(:user) { table(:users).create!(name: 'test-user', email: 'test@example.com', projects_limit: 5) }
  let(:organization) { table(:organizations).create!(name: 'test-org', path: 'default') }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path', organization_id: organization.id) }
  let(:workspace_variables) { table(:workspace_variables) }

  let(:project) do
    table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let!(:personal_access_token) do
    table(:personal_access_tokens).create!(
      user_id: user.id,
      name: 'token_name',
      organization_id: organization.id,
      expires_at: Time.now
    )
  end

  let(:cluster_agent) { table(:cluster_agents).create!(name: 'remotedev', project_id: project.id) }

  let!(:agent) do
    table(:workspaces_agent_configs).create!(
      cluster_agent_id: cluster_agent.id,
      enabled: true,
      dns_zone: 'test.workspace.me',
      project_id: project.id
    )
  end

  let!(:agent_config_version) do
    table(:workspaces_agent_config_versions).create!(
      project_id: project.id,
      item_id: agent.id,
      item_type: 'RemoteDevelopment::WorkspacesAgentConfig',
      event: 'create'
    )
  end

  let!(:workspace) do
    table(:workspaces).create!(
      user_id: user.id,
      project_id: project.id,
      cluster_agent_id: cluster_agent.id,
      desired_state_updated_at: Time.now,
      responded_to_agent_at: Time.now,
      name: 'workspace-1',
      namespace: 'workspace_1_namespace',
      desired_state: 'Running',
      actual_state: 'Running',
      project_ref: 'devfile-ref',
      devfile_path: 'devfile-path',
      devfile: 'devfile',
      processed_devfile: 'processed_dev_file',
      url: 'workspace-url',
      deployment_resource_version: 'v1',
      personal_access_token_id: personal_access_token.id,
      max_hours_before_termination: 5760,
      workspaces_agent_config_version: agent_config_version.id,
      desired_config_generator_version: 3
    )
  end

  let!(:workspace_static_file_variable) do
    workspace_variables.create!(
      workspace_id: workspace.id,
      project_id: project.id,
      key: 'gl_token',
      variable_type: 1,
      encrypted_value: 'encrypted_value',
      encrypted_value_iv: 'encrypted_value_iv'
    )
  end

  let!(:workspace_static_env_variable) do
    workspace_variables.create!(
      workspace_id: workspace.id,
      project_id: project.id,
      key: 'GIT_CONFIG_COUNT',
      variable_type: 0,
      encrypted_value: 'encrypted_value',
      encrypted_value_iv: 'encrypted_value_iv'
    )
  end

  let!(:workspace_user_provided_variable) do
    workspace_variables.create!(
      workspace_id: workspace.id,
      project_id: project.id,
      key: 'variable_key',
      variable_type: 0,
      encrypted_value: 'encrypted_value',
      encrypted_value_iv: 'encrypted_value_iv'
    )
  end

  it 'sets user_provided to true for all non-internal environment variables in the table' do
    reversible_migration do |migration|
      migration.before -> {
        expect(workspace_variables.pluck(:user_provided)).to all(be false)
      }

      migration.after -> {
        user_provided_variable = workspace_variables.where(variable_type: described_class::VARIABLE_ENV_TYPE)
        .where.not(key: described_class::WORKSPACE_INTERNAL_VARIABLES).first

        expect(workspace_static_file_variable.user_provided).to be(false)
        expect(workspace_static_env_variable.user_provided).to be(false)
        expect(user_provided_variable.user_provided).to be(true)
      }
    end
  end
end
