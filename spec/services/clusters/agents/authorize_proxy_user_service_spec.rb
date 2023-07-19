# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::AuthorizeProxyUserService, feature_category: :deployment_management do
  subject(:service_response) { service.execute }

  let(:service) { described_class.new(user, agent) }
  let(:user) { create(:user) }

  let_it_be(:organization) { create(:group) }
  let_it_be(:configuration_project) { create(:project, group: organization) }
  let_it_be(:agent) { create(:cluster_agent, name: 'the-agent', project: configuration_project) }
  let_it_be(:deployment_project) { create(:project, group: organization) }
  let_it_be(:deployment_group) { create(:group, parent: organization) }

  let(:user_access_config) do
    {
      'user_access' => {
        'access_as' => { 'agent' => {} },
        'projects' => [{ 'id' => deployment_project.full_path }],
        'groups' => [{ 'id' => deployment_group.full_path }]
      }
    }
  end

  before do
    Clusters::Agents::Authorizations::UserAccess::RefreshService.new(agent, config: user_access_config).execute
  end

  it 'returns forbidden when user has no access to any project', :aggregate_failures do
    expect(service_response).to be_error
    expect(service_response.reason).to eq :forbidden
    expect(service_response.message)
      .to eq 'You must be a member of `projects` or `groups` under the `user_access` keyword.'
  end

  context 'when user is member of an authorized group' do
    it 'authorizes developers', :aggregate_failures do
      deployment_group.add_member(user, :developer)
      expect(service_response).to be_success
      expect(service_response.payload[:user]).to include(id: user.id, username: user.username)
      expect(service_response.payload[:agent]).to include(id: agent.id, config_project: { id: agent.project.id })
    end

    it 'does not authorize reporters', :aggregate_failures do
      deployment_group.add_member(user, :reporter)
      expect(service_response).to be_error
      expect(service_response.reason).to eq :forbidden
      expect(service_response.message)
        .to eq 'You must be a member of `projects` or `groups` under the `user_access` keyword.'
    end
  end

  context 'when user is member of an authorized project' do
    it 'authorizes developers', :aggregate_failures do
      deployment_project.add_member(user, :developer)
      expect(service_response).to be_success
      expect(service_response.payload[:user]).to include(id: user.id, username: user.username)
      expect(service_response.payload[:agent]).to include(id: agent.id, config_project: { id: agent.project.id })
    end

    it 'does not authorize reporters', :aggregate_failures do
      deployment_project.add_member(user, :reporter)
      expect(service_response).to be_error
      expect(service_response.reason).to eq :forbidden
      expect(service_response.message)
        .to eq 'You must be a member of `projects` or `groups` under the `user_access` keyword.'
    end
  end

  context 'when config is empty' do
    let(:user_access_config) { {} }

    it 'returns an error', :aggregate_failures do
      expect(service_response).to be_error
      expect(service_response.reason).to eq :forbidden
      expect(service_response.message).to eq '`user_access` keyword is not found in agent config file.'
    end
  end
end
