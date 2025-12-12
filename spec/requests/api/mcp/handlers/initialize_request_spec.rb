# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'Initialize request', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  before do
    stub_application_setting(instance_level_ai_beta_features_enabled: true)
  end

  describe 'POST /mcp with initialize method' do
    let(:base_params) do
      {
        jsonrpc: '2.0',
        method: 'initialize',
        id: '1'
      }
    end

    context 'when client sends latest protocol version' do
      let(:params) do
        base_params.merge(
          params: {
            protocolVersion: '2025-06-18'
          }
        )
      end

      before do
        post api('/mcp', user, oauth_access_token: access_token), params: params
      end

      it 'returns success' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['jsonrpc']).to eq(params[:jsonrpc])
        expect(json_response['id']).to eq(params[:id])
        expect(json_response.keys).to include('result')
      end

      it 'returns latest protocol version' do
        expect(json_response['result']['protocolVersion']).to eq('2025-06-18')
      end

      it 'returns capabilities' do
        expect(json_response['result']['capabilities']).to include(
          'tools' => { 'listChanged' => false }
        )
      end

      it 'returns server info' do
        expect(json_response['result']['serverInfo']).to include(
          'name' => 'Official GitLab MCP Server',
          'version' => Gitlab::VERSION
        )
      end
    end

    context 'when client sends older supported protocol version' do
      let(:params) do
        base_params.merge(
          params: {
            protocolVersion: '2025-03-26'
          }
        )
      end

      before do
        post api('/mcp', user, oauth_access_token: access_token), params: params
      end

      it 'returns success with older version' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['protocolVersion']).to eq('2025-03-26')
      end
    end

    context 'when client sends unsupported protocol version' do
      let(:params) do
        base_params.merge(
          params: {
            protocolVersion: '2024-11-05'
          }
        )
      end

      before do
        post api('/mcp', user, oauth_access_token: access_token), params: params
      end

      it 'returns version mismatch error' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']['code']).to eq(-32602)
        expect(json_response['error']['message']).to eq('Invalid params')
        expect(json_response['error']['data']['params']).to include('Unsupported protocol version')
        expect(json_response['error']['data']['params']).to include('2025-11-25')
        expect(json_response['error']['data']['params']).to include('2025-06-18')
        expect(json_response['error']['data']['params']).to include('2025-03-26')
        expect(json_response['error']['data']['params']).to include('2024-11-05')
      end
    end

    context 'when client sends no protocol version parameters' do
      let(:params) { base_params }

      before do
        post api('/mcp', user, oauth_access_token: access_token), params: params
      end

      it 'returns error indicating missing parameter' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']['code']).to eq(-32602)
        expect(json_response['error']['message']).to eq('Invalid params')
        expect(json_response['error']['data']['params']).to include('Missing required parameter')
        expect(json_response['error']['data']['params']).to include('protocolVersion')
        expect(json_response['error']['data']['params']).to include('2025-06-18')
        expect(json_response['error']['data']['params']).to include('2025-03-26')
        expect(json_response['error']['data']['params']).to include('2025-11-25')
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
