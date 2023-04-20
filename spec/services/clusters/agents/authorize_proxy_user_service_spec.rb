# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::AuthorizeProxyUserService, feature_category: :deployment_management do
  subject(:service_response) { service.execute }

  let(:service) { described_class.new(user, agent) }
  let(:user) { create(:user) }

  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:user_access_config) do
    {
      'user_access' => {
        'access_as' => { 'agent' => {} },
        'projects' => [{ 'id' => project.full_path }],
        'groups' => [{ 'id' => group.full_path }]
      }
    }
  end

  let_it_be(:configuration_project) do
    create(
      :project, :custom_repo,
      files: {
        ".gitlab/agents/the-agent/config.yaml" => user_access_config.to_yaml
      }
    )
  end

  let_it_be(:agent) { create(:cluster_agent, name: 'the-agent', project: configuration_project) }

  it 'returns forbidden when user has no access to any project', :aggregate_failures do
    expect(service_response).to be_error
    expect(service_response.reason).to eq :forbidden
  end

  context 'when user is member of an authorized group' do
    it 'authorizes developers', :aggregate_failures do
      group.add_member(user, :developer)
      expect(service_response).to be_success
      expect(service_response.payload[:user]).to include(id: user.id, username: user.username)
      expect(service_response.payload[:agent]).to include(id: agent.id, config_project: { id: agent.project.id })
    end

    it 'does not authorize reporters', :aggregate_failures do
      group.add_member(user, :reporter)
      expect(service_response).to be_error
      expect(service_response.reason).to eq :forbidden
    end
  end

  context 'when user is member of an authorized project' do
    it 'authorizes developers', :aggregate_failures do
      project.add_member(user, :developer)
      expect(service_response).to be_success
      expect(service_response.payload[:user]).to include(id: user.id, username: user.username)
      expect(service_response.payload[:agent]).to include(id: agent.id, config_project: { id: agent.project.id })
    end

    it 'does not authorize reporters', :aggregate_failures do
      project.add_member(user, :reporter)
      expect(service_response).to be_error
      expect(service_response.reason).to eq :forbidden
    end
  end
end
