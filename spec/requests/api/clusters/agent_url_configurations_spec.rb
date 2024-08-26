# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Clusters::AgentUrlConfigurations, feature_category: :deployment_management do
  let_it_be(:agent) { create(:cluster_agent) }
  let_it_be(:project) { agent.project }
  let_it_be(:user) { agent.created_by_user }
  let_it_be(:unauthorized_user) { create(:user, :with_namespace, guest_of: project) }

  before_all do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/cluster_agents/:agent_id/url_configurations' do
    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      context 'with authorized user' do
        let_it_be(:url_configuration) { create(:cluster_agent_url_configuration, :public_key_auth, agent: agent) }
        let_it_be(:agent_without_url_cfgs) { create(:cluster_agent, project: project, created_by_user: user) }

        it 'returns agent url configurations', :aggregate_failures do
          get api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/agent_url_configurations')
          expect(json_response[0]['id']).to eq(url_configuration.id)
          expect(json_response[0]['agent_id']).to eq(agent.id)
          expect(json_response[0]['url']).to eq('grpc://agent.example.com')
        end

        it 'returns a 404 if agent does not exist' do
          path = "/projects/#{project.id}/cluster_agents/#{non_existing_record_id}/url_configurations"

          get api(path, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns empty list when no url configurations are created' do
          get api("/projects/#{project.id}/cluster_agents/#{agent_without_url_cfgs.id}/url_configurations", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_empty
        end
      end

      context 'with unauthorized user' do
        it 'cannot access url configurations' do
          get api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations",
            unauthorized_user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when receptive agents are disabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
      end

      it 'returns not found' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id' do
    let_it_be(:url_configuration) { create(:cluster_agent_url_configuration, :public_key_auth, agent: agent) }

    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      context 'with authorized user' do
        it 'returns an agent url configuration', :aggregate_failures do
          get api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{url_configuration.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/agent_url_configuration')
          expect(json_response['id']).to eq(url_configuration.id)
          expect(json_response['agent_id']).to eq(agent.id)
          expect(json_response['url']).to eq('grpc://agent.example.com')
        end

        it 'returns a 404 if agent does not exist' do
          path = "/projects/#{project.id}/cluster_agents/#{non_existing_record_id}" \
            "/url_configurations/#{non_existing_record_id}"

          get api(path, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns a 404 error if agent url configuration id is not available' do
          get api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{non_existing_record_id}",
            user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with unauthorized user' do
        it 'cannot access single agent url configuration' do
          get api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{url_configuration.id}",
            unauthorized_user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'cannot access url configuration from agent of another project' do
          another_project = create(:project, namespace: unauthorized_user.namespace)
          another_agent = create(:cluster_agent, project: another_project, created_by_user: unauthorized_user)

          get api(
            "/projects/#{another_project.id}/cluster_agents/#{another_agent.id}" \
              "url_configurations/#{url_configuration.id}",
            unauthorized_user
          )

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when receptive agents are disabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
      end

      it 'returns not found' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{url_configuration.id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/cluster_agents/:agent_id/url_configurations' do
    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      context 'when using defaults' do
        let_it_be(:params) { { url: 'grpcs://localhost:4242' } }

        it 'creates a new agent url configuration', :aggregate_failures do
          post(api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user), params: params)

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/agent_url_configuration')
          expect(json_response['agent_id']).to eq(agent.id)
          expect(json_response['url']).to eq(params[:url])
          expect(json_response['public_key']).not_to be_nil
          expect(json_response['client_cert']).to be_nil
        end
      end

      context 'when providing client cert and key' do
        let_it_be(:client_cert) do
          Base64.encode64(File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')))
        end

        let_it_be(:client_key) { Base64.encode64(File.read(Rails.root.join('spec/fixtures/clusters/sample_key.key'))) }

        let_it_be(:params) do
          {
            url: 'grpcs://localhost:4242',
            client_cert: client_cert,
            client_key: client_key
          }
        end

        it 'creates a new agent url configuration', :aggregate_failures do
          post(api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user), params: params)

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/agent_url_configuration')
          expect(json_response['agent_id']).to eq(agent.id)
          expect(json_response['url']).to eq(params[:url])
          expect(json_response['public_key']).to be_nil
          expect(json_response['client_cert']).to eq(client_cert)
        end
      end

      context 'when providing ca cert' do
        let_it_be(:ca_cert) { Base64.encode64(File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem'))) }

        let_it_be(:params) do
          {
            url: 'grpcs://localhost:4242',
            ca_cert: ca_cert
          }
        end

        it 'creates a new agent url configuration', :aggregate_failures do
          post(api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user), params: params)

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/agent_url_configuration')
          expect(json_response['agent_id']).to eq(agent.id)
          expect(json_response['url']).to eq(params[:url])
          expect(json_response['ca_cert']).to eq(ca_cert)
        end
      end

      context 'when providing tls host' do
        let_it_be(:params) do
          {
            url: 'grpcs://localhost:4242',
            tls_host: 'example.com'
          }
        end

        it 'creates a new agent url configuration', :aggregate_failures do
          post(api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user), params: params)

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/agent_url_configuration')
          expect(json_response['agent_id']).to eq(agent.id)
          expect(json_response['url']).to eq(params[:url])
          expect(json_response['tls_host']).to eq('example.com')
        end
      end

      it 'returns a 400 error if url not given' do
        post api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 404 error if project does not exist' do
        post api("/projects/#{non_existing_record_id}/cluster_agents/url_configurations", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 404 error if agent does not exist' do
        post api("/projects/#{project.id}/cluster_agents/#{non_existing_record_id}/url_configurations", user),
          params: {
            url: 'grpcs://localhost:4242'
          }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'with unauthorized user' do
        it 'prevents to create agent url configuration' do
          post api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", unauthorized_user),
            params: { url: "grpcs://localhost:4242" }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when an already registered url configuration' do
        let_it_be(:receptive_agent) { create(:cluster_agent, project: project, is_receptive: true) }

        before_all do
          create(:cluster_agent_url_configuration, agent: receptive_agent, created_by_user: user)
          project.add_maintainer(user)
        end

        it 'returns a bad request (400) error', :aggregate_failures do
          params = {
            url: 'grpcs://localhost:4242'
          }
          post(
            api("/projects/#{project.id}/cluster_agents/#{receptive_agent.id}/url_configurations", user),
            params: params
          )

          expect(response).to have_gitlab_http_status(:bad_request)

          error_message = json_response['message']
          expect(error_message).to eq('400 Bad request - URL configuration already exists for this agent')
        end
      end
    end

    context 'when receptive agents are disabled' do
      let_it_be(:params) { { url: 'grpcs://localhost:4242' } }

      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
      end

      it 'returns not found' do
        post(api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations", user), params: params)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id' do
    let_it_be(:url_configuration) { create(:cluster_agent_url_configuration, :public_key_auth, agent: agent) }

    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      it 'deletes agent url configuration' do
        expect do
          delete api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{url_configuration.id}",
            user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { ::Clusters::Agents::UrlConfiguration.count }.by(-1)
      end

      it 'returns a 404 error when given agent_id does not exist' do
        path = "/projects/#{project.id}/cluster_agents/#{non_existing_record_id}" \
          "/url_configurations/#{non_existing_record_id}"

        delete api(path, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 error when deleting non existent agent url configuration' do
        delete api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{non_existing_record_id}",
          user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 if the user is unauthorized to delete' do
        delete api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{url_configuration.id}",
          unauthorized_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'cannot delete url configuration from agent of another project' do
        another_project = create(:project, namespace: unauthorized_user.namespace)
        another_agent = create(:cluster_agent, project: another_project, created_by_user: unauthorized_user)

        delete api(
          "/projects/#{another_project.id}/cluster_agents/#{another_agent.id}/url_configurations" \
            "/#{url_configuration.id}", unauthorized_user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when receptive agents are disabled' do
      let_it_be(:params) { { url: 'grpcs://localhost:4242' } }

      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
      end

      it 'returns not found' do
        delete api("/projects/#{project.id}/cluster_agents/#{agent.id}/url_configurations/#{url_configuration.id}",
          user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
