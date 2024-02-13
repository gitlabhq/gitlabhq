# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Clusters::Agents, feature_category: :deployment_management do
  let_it_be(:agent) { create(:cluster_agent) }

  let(:user) { agent.created_by_user }
  let(:unauthorized_user) { create(:user) }
  let!(:project) { agent.project }

  before do
    project.add_maintainer(user)
    project.add_guest(unauthorized_user)
  end

  describe 'GET /projects/:id/cluster_agents' do
    context 'authorized user' do
      it 'returns project agents' do
        get api("/projects/#{project.id}/cluster_agents", user)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(response).to match_response_schema('public_api/v4/agents')
          expect(json_response.count).to eq(1)
          expect(json_response.first['name']).to eq(agent.name)
        end
      end

      it 'returns empty list when no agents registered' do
        no_agents_project = create(:project, namespace: user.namespace)

        get api("/projects/#{no_agents_project.id}/cluster_agents", user)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(response).to match_response_schema('public_api/v4/agents')
          expect(json_response.count).to eq(0)
        end
      end
    end

    context 'unauthorized user' do
      it 'unable to access agents' do
        get api("/projects/#{project.id}/cluster_agents", unauthorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'avoids N+1 queries', :request_store do
      # Establish baseline
      get api("/projects/#{project.id}/cluster_agents", user)

      control = ActiveRecord::QueryRecorder.new do
        get api("/projects/#{project.id}/cluster_agents", user)
      end

      # Now create a second record and ensure that the API does not execute
      # any more queries than before
      create(:cluster_agent, project: project)

      expect do
        get api("/projects/#{project.id}/cluster_agents", user)
      end.not_to exceed_query_limit(control)
    end
  end

  describe 'GET /projects/:id/cluster_agents/:agent_id' do
    context 'authorized user' do
      it 'returns a project agent' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}", user)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/agent')
          expect(json_response['name']).to eq(agent.name)
        end
      end

      it 'returns a 404 error if agent id is not available' do
        get api("/projects/#{project.id}/cluster_agents/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthorized user' do
      it 'unable to access an existing agent' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}", unauthorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/cluster_agents' do
    it 'adds agent to project' do
      expect do
        post(api("/projects/#{project.id}/cluster_agents", user), params: { name: 'some-agent' })
      end.to change { project.cluster_agents.count }.by(1)

      aggregate_failures "testing response" do
        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/agent')
        expect(json_response['name']).to eq('some-agent')
      end
    end

    it 'returns a 400 error if name not given' do
      post api("/projects/#{project.id}/cluster_agents", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns a 400 error if name is invalid' do
      post api("/projects/#{project.id}/cluster_agents", user), params: { name: '#4^x' }

      aggregate_failures "testing response" do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message'])
          .to include("Name can contain only lowercase letters, digits, and '-', but cannot start or end with '-'")
      end
    end

    it 'returns 404 error if project does not exist' do
      post api("/projects/#{non_existing_record_id}/cluster_agents", user), params: { name: 'some-agent' }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'DELETE /projects/:id/cluster_agents/:agent_id' do
    it 'deletes agent from project' do
      expect do
        delete api("/projects/#{project.id}/cluster_agents/#{agent.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { project.cluster_agents.count }.by(-1)
    end

    it 'returns a 404 error when deleting non existent agent' do
      delete api("/projects/#{project.id}/cluster_agents/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 error if agent id not given' do
      delete api("/projects/#{project.id}/cluster_agents", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 403 if the user is unauthorized to delete' do
      delete api("/projects/#{project.id}/cluster_agents/#{agent.id}", unauthorized_user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/cluster_agents/#{agent.id}", user) }
    end
  end
end
