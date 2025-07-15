# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateWorkspacesAgentConfigsProxyNamespaceFromEmptyHashToDefault, feature_category: :workspaces do
  let(:workspaces_agent_configs) { table(:workspaces_agent_configs) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) do
    table(:namespaces).create!(name: 'namespace', path: 'namespace', organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(name: 'project', path: 'project', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:cluster_agent) { table(:cluster_agents).create!(name: 'cluster_agent', project_id: project.id) }
  let!(:workspaces_agent_config) do
    workspaces_agent_configs.create!(
      enabled: true,
      gitlab_workspaces_proxy_namespace: '{}',
      cluster_agent_id: cluster_agent.id,
      dns_zone: 'workspaces.localdev.me',
      project_id: project.id)
  end

  describe '#up' do
    it 'updates proxy_namespace from empty hash to default' do
      expect { migrate! }.to change {
        workspaces_agent_config.reload.gitlab_workspaces_proxy_namespace
      }.from('{}').to('gitlab-workspaces')
    end
  end
end
