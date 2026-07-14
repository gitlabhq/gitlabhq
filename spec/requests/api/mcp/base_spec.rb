# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Mcp::Base, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  before do
    stub_application_setting(instance_level_ai_beta_features_enabled: true)
  end

  describe 'POST /mcp' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api('/mcp')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns a WWW-Authenticate challenge pointing at the resource metadata', :aggregate_failures do
        post api('/mcp')

        metadata_url = "#{Gitlab.config.gitlab.url}/.well-known/oauth-protected-resource/api/v4/mcp"
        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate'])
          .to eq(%(Bearer realm="GitLab", resource_metadata="#{metadata_url}"))
      end
    end

    context 'when authenticated' do
      it 'is successful' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to eq({
          "id" => "1",
          "jsonrpc" => "2.0",
          "result" => {
            "capabilities" => {
              "tools" => {
                "listChanged" => false
              }
            },
            "protocolVersion" => "2025-06-18",
            "serverInfo" => {
              "name" => "Official GitLab MCP Server",
              "version" => Gitlab::VERSION
            }
          }
        })
      end

      context 'when access token is PAT' do
        it 'returns forbidden' do
          post api('/mcp', user), params: { jsonrpc: '2.0', method: 'initialize', id: '1',
                                            params: { protocolVersion: '2025-06-18' } }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when access token is OAuth without mcp scope' do
        let(:insufficient_access_token) { create(:oauth_access_token, user: user, scopes: [:api]) }

        it 'returns forbidden' do
          post api('/mcp', user, oauth_access_token: insufficient_access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when access token OAuth token has multiple scopes' do
        let(:insufficient_access_token) { create(:oauth_access_token, user: user, scopes: [:api, :mcp]) }

        it 'returns forbidden' do
          post api('/mcp', user, oauth_access_token: insufficient_access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when required jsonrpc param is missing' do
        it 'returns JSON-RPC Invalid Request error' do
          post api('/mcp', user, oauth_access_token: access_token), params: { id: '1', method: 'initialize' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32600)
          expect(json_response['error']['data']['validations']).to include('jsonrpc is missing')
        end
      end

      context 'when required jsonrpc param is empty' do
        it 'returns JSON-RPC Invalid Request error' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '', method: 'initialize', id: '1' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32600)
          expect(json_response['error']['data']['validations']).to include('jsonrpc is empty')
        end
      end

      context 'when required jsonrpc param is invalid value' do
        it 'returns JSON-RPC Invalid Request error' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '1.0', method: 'initialize', id: '1' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32600)
          expect(json_response['error']['data']['validations']).to include('jsonrpc does not have a valid value')
        end
      end

      context 'when required method param is missing' do
        it 'returns JSON-RPC Invalid Request error' do
          post api('/mcp', user, oauth_access_token: access_token), params: { jsonrpc: '2.0', id: '1' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32600)
          expect(json_response['error']['data']['validations']).to include('method is missing')
        end
      end

      context 'when required method param is empty' do
        it 'returns JSON-RPC Invalid Request error' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: '', id: '1' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32600)
          expect(json_response['error']['data']['validations']).to include('method is empty')
        end
      end

      context 'when optional id param is empty' do
        it 'returns JSON-RPC Invalid Request error' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: '' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32600)
          expect(json_response['error']['data']['validations']).to include('id is empty')
        end
      end

      context 'when method does not exist' do
        it 'returns JSON-RPC Method not found error' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'unknown/method', id: '1' }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['error']['code']).to eq(-32601)
          expect(json_response['error']['message']).to eq('Method not found')
        end
      end
    end

    context 'when mcp_server_enabled is true' do
      before do
        stub_application_setting(mcp_server_enabled: true)
      end

      it 'returns ok' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when mcp_server_enabled is false' do
      before do
        stub_application_setting(mcp_server_enabled: false)
      end

      it 'returns not_found' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'logs that the MCP server is not available' do
        expect_next_instance_of(Gitlab::Mcp::Logger) do |logger|
          expect(logger).to receive(:info).with(
            message: 'MCP server not available',
            event_name: 'permission_denied',
            ai_component: 'mcp_server',
            denial_reason: :instance_setting_disabled,
            Labkit::Fields::GL_USER_ID => user.id
          )
        end

        post api('/mcp', user, oauth_access_token: access_token),
          params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-11-25' } }
      end
    end

    context 'with granular token authorization' do
      it_behaves_like 'authorizing granular token permissions', :execute_mcp_tool, legacy_token_scopes: [:mcp] do
        let(:boundary_object) { :user }
        let(:request) do
          post api('/mcp', personal_access_token: pat), params: { jsonrpc: '2.0', method: 'tools/list', id: '1' }
        end
      end
    end
  end

  describe 'GET /mcp' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/mcp')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns a WWW-Authenticate challenge pointing at the resource metadata', :aggregate_failures do
        get api('/mcp')

        metadata_url = "#{Gitlab.config.gitlab.url}/.well-known/oauth-protected-resource/api/v4/mcp"
        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate'])
          .to eq(%(Bearer realm="GitLab", resource_metadata="#{metadata_url}"))
      end
    end

    context 'when authenticated' do
      it 'returns method not allowed' do
        get api('/mcp', user, oauth_access_token: access_token)

        expect(response).to have_gitlab_http_status(:method_not_allowed)
      end
    end

    context 'with granular token authorization' do
      it_behaves_like 'authorizing granular token permissions', :execute_mcp_tool,
        expected_success_status: :method_not_allowed, legacy_token_scopes: [:mcp] do
        let(:boundary_object) { :user }
        let(:request) { get api('/mcp', personal_access_token: pat) }
      end
    end
  end
end
