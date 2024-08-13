# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.ci_access_authorized_agents', feature_category: :deployment_management do
  include GraphqlHelpers

  let_it_be(:organization) { create(:group) }
  let_it_be(:agent_management_project) { create(:project, :private, group: organization) }
  let_it_be(:agent) { create(:cluster_agent, project: agent_management_project) }

  let_it_be(:deployment_project) { create(:project, :private, group: organization) }
  let_it_be(:deployment_developer) { create(:user, developer_of: deployment_project) }
  let_it_be(:deployment_reporter) { create(:user, reporter_of: deployment_project) }

  let(:user) { deployment_developer }

  let(:query) do
    %(
      query {
        project(fullPath: "#{deployment_project.full_path}") {
          ciAccessAuthorizedAgents {
            nodes {
              agent {
                id
                name
                project {
                  name
                }
              }
              config
            }
          }
        }
      }
    )
  end

  subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

  context 'with project authorization' do
    let!(:ci_access) { create(:agent_ci_access_project_authorization, agent: agent, project: deployment_project) }

    it 'returns the authorized agent' do
      authorized_agents = subject.dig('data', 'project', 'ciAccessAuthorizedAgents', 'nodes')

      expect(authorized_agents.count).to eq(1)

      authorized_agent = authorized_agents.first

      expect(authorized_agent['agent']['id']).to eq(agent.to_global_id.to_s)
      expect(authorized_agent['agent']['name']).to eq(agent.name)
      expect(authorized_agent['config']).to eq({ "default_namespace" => "production",
                                                 "protected_branches_only" => false })
      expect(authorized_agent['agent']['project']).to be_nil # User is not authorized to read other resources.
    end

    context 'when user is developer in the agent management project' do
      before do
        agent_management_project.add_developer(deployment_developer)
      end

      it 'returns the project information as well' do
        authorized_agent = subject.dig('data', 'project', 'ciAccessAuthorizedAgents', 'nodes').first

        expect(authorized_agent['agent']['project']['name']).to eq(agent_management_project.name)
      end
    end

    context 'when user is reporter' do
      let(:user) { deployment_reporter }

      it 'returns nothing' do
        expect(subject['data']['project']['ciAccessAuthorizedAgents']).to be_nil
      end
    end
  end

  context 'with group authorization' do
    let!(:ci_access) { create(:agent_ci_access_group_authorization, agent: agent, group: organization) }

    it 'returns the authorized agent' do
      authorized_agents = subject.dig('data', 'project', 'ciAccessAuthorizedAgents', 'nodes')

      expect(authorized_agents.count).to eq(1)

      authorized_agent = authorized_agents.first

      expect(authorized_agent['agent']['id']).to eq(agent.to_global_id.to_s)
      expect(authorized_agent['agent']['name']).to eq(agent.name)
      expect(authorized_agent['config']).to eq({ "default_namespace" => "production",
                                                "protected_branches_only" => false })
      expect(authorized_agent['agent']['project']).to be_nil # User is not authorized to read other resources.
    end

    context 'when user is developer in the agent management project' do
      before do
        agent_management_project.add_developer(deployment_developer)
      end

      it 'returns the project information as well' do
        authorized_agent = subject.dig('data', 'project', 'ciAccessAuthorizedAgents', 'nodes').first

        expect(authorized_agent['agent']['project']['name']).to eq(agent_management_project.name)
      end
    end

    context 'when user is reporter' do
      let(:user) { deployment_reporter }

      it 'returns nothing' do
        expect(subject['data']['project']['ciAccessAuthorizedAgents']).to be_nil
      end
    end
  end

  context 'when deployment project is not authorized to ci_access to the agent' do
    it 'returns empty' do
      authorized_agents = subject.dig('data', 'project', 'ciAccessAuthorizedAgents', 'nodes')

      expect(authorized_agents).to be_empty
    end
  end
end
