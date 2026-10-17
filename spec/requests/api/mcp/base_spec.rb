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
          .to eq(%(Bearer realm="GitLab", scope="mcp", resource_metadata="#{metadata_url}"))
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

      context 'when signed in through the session, with no token' do
        before do
          sign_in(user)
          # sign_in's one-shot login skips /api/v4/mcp (ee/spec/spec_helper.rb), so another request starts the session.
          get api('/version')
        end

        it 'refuses the request as insufficient_scope', :aggregate_failures do
          post api('/mcp'),
            params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['error']).to eq('insufficient_scope')
        end
      end

      context 'when the token is refused' do
        let(:initialize_params) do
          { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }
        end

        let(:metadata_url) { "#{Gitlab.config.gitlab.url}/.well-known/oauth-protected-resource/api/v4/mcp" }

        def challenge(error, error_description, scope: 'mcp')
          %(Bearer realm="GitLab", error="#{error}", error_description="#{error_description}", ) +
            %(scope="#{scope}", resource_metadata="#{metadata_url}")
        end

        context 'with a token whose scopes do not cover the request' do
          let(:read_user_token) { create(:oauth_access_token, user: user, scopes: [:read_user]) }

          it 'answers with the challenge of the 401, naming the mcp scope in it and the body', :aggregate_failures do
            post api('/mcp', oauth_access_token: read_user_token), params: initialize_params

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['error']).to eq('insufficient_scope')
            expect(json_response['scope']).to eq('mcp')
            expect(response.headers['WWW-Authenticate']).to eq(
              challenge('insufficient_scope',
                'The request requires higher privileges than provided by the access token.')
            )
          end
        end

        context 'with a token that has api and not mcp' do
          let(:api_token) { create(:oauth_access_token, user: user, scopes: [:api]) }

          it 'answers with the challenge of the 401, naming the mcp scope in it and the body', :aggregate_failures do
            post api('/mcp', oauth_access_token: api_token), params: initialize_params

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['error']).to eq('insufficient_scope')
            expect(json_response['scope']).to eq('mcp')
            expect(response.headers['WWW-Authenticate']).to eq(
              challenge('insufficient_scope',
                'The request requires higher privileges than provided by the access token.')
            )
          end

          it 'logs the refusal as insufficient_scope, as the API guard does' do
            expect(API::API::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
              expect(data.stringify_keys).to include(
                'meta.auth_fail_reason' => 'insufficient_scope',
                'meta.auth_fail_token_id' => "OauthAccessToken/#{api_token.id}",
                'meta.auth_fail_requested_scopes' => 'mcp',
                'route' => '/api/:version/mcp'
              )
            end

            post api('/mcp', oauth_access_token: api_token), params: initialize_params
          end
        end

        context 'with a token that sudo needs another scope for' do
          let_it_be(:admin) { create(:admin) }
          let_it_be(:mcp_pat) { create(:personal_access_token, user: admin, scopes: [:mcp]) }

          it 'names the sudo scope in the challenge and the body', :enable_admin_mode, :aggregate_failures do
            post api('/mcp', personal_access_token: mcp_pat), params: initialize_params,
              headers: { 'Sudo' => user.username }

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['scope']).to eq('sudo')
            expect(response.headers['WWW-Authenticate']).to eq(
              challenge('insufficient_scope',
                'The request requires higher privileges than provided by the access token.', scope: 'sudo')
            )
          end
        end

        context 'with a revoked token' do
          let(:revoked_pat) { create(:personal_access_token, :revoked, user: user, scopes: [:mcp]) }

          it 'answers with the challenge of the 401, adding the error', :aggregate_failures do
            post api('/mcp', personal_access_token: revoked_pat), params: initialize_params

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['error']).to eq('invalid_token')
            expect(response.headers['WWW-Authenticate']).to eq(
              challenge('invalid_token', 'Token was revoked. You have to re-authorize from the user.')
            )
          end
        end

        context 'with an expired token' do
          let(:expired_pat) { create(:personal_access_token, :expired, user: user, scopes: [:mcp]) }

          it 'answers with the challenge of the 401, adding the error' do
            post api('/mcp', personal_access_token: expired_pat), params: initialize_params

            expect(response.headers['WWW-Authenticate']).to eq(
              challenge('invalid_token', 'Token is expired. You can either do re-authorization or token refresh.')
            )
          end
        end

        context 'with an impersonation token while impersonation is disabled' do
          let(:impersonation_pat) { create(:personal_access_token, :impersonation, user: user, scopes: [:mcp]) }

          before do
            stub_config_setting(impersonation_enabled: false)
          end

          it 'answers with the challenge of the 401, adding the error' do
            post api('/mcp', personal_access_token: impersonation_pat), params: initialize_params

            expect(response.headers['WWW-Authenticate']).to eq(
              challenge('invalid_token', 'Token is an impersonation token but impersonation was disabled.')
            )
          end
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

        it 'echoes the request id' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '1.0', method: 'initialize', id: '1' }

          expect(json_response['id']).to eq('1')
        end
      end

      context 'when params are invalid' do
        it 'returns JSON-RPC Invalid params error that echoes the request id' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: 'abc-123',
                      params: { protocolVersion: '1999-01-01' } }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32602)
          expect(json_response['id']).to eq('abc-123')
        end

        it 'preserves an integer request id' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: 7,
                      params: { protocolVersion: '1999-01-01' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['id']).to eq(7)
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

      context 'when optional id param is not present' do
        it 'is successful for notifications' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'notifications/initialized' }

          expect(response).to have_gitlab_http_status(:accepted)
          expect(response.body).to be_empty
        end
      end

      context 'when id param is an integer' do
        it 'preserves the integer type in the response' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: 1,
                      params: { protocolVersion: '2025-06-18' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(1)
          expect(json_response['id']).to be_a(Integer)
        end
      end

      context 'when id param is a string' do
        it 'preserves the string type in the response' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: 'abc-123',
                      params: { protocolVersion: '2025-06-18' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq('abc-123')
          expect(json_response['id']).to be_a(String)
        end
      end

      context 'when id param is neither an integer nor a string' do
        it 'returns JSON-RPC Invalid Request error' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: { foo: 'bar' },
                      params: { protocolVersion: '2025-06-18' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']['code']).to eq(-32600)
          expect(json_response['error']['data']['validations']).to include('id is invalid')
          expect(json_response['id']).to be_nil
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

      it 'returns forbidden' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: { jsonrpc: '2.0', method: 'initialize', id: '1', params: { protocolVersion: '2025-06-18' } }

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden - MCP server disabled for this instance')
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
          .to eq(%(Bearer realm="GitLab", scope="mcp", resource_metadata="#{metadata_url}"))
      end
    end

    context 'when authenticated' do
      it 'returns method not allowed' do
        get api('/mcp', user, oauth_access_token: access_token)

        expect(response).to have_gitlab_http_status(:method_not_allowed)
      end
    end

    context 'when mcp_server_enabled is false' do
      before do
        stub_application_setting(mcp_server_enabled: false)
      end

      it 'returns forbidden' do
        get api('/mcp', user, oauth_access_token: access_token)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden - MCP server disabled for this instance')
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
