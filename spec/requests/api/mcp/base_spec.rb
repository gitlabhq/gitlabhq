# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Mcp::Base, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  describe 'POST /mcp' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api('/mcp')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(mcp_server: false)
        end

        it 'returns not found' do
          post api('/mcp', user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when access token is PAT' do
        it 'returns forbidden' do
          post api('/mcp', user), params: { jsonrpc: '2.0', method: 'initialize', id: '1' }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when access token is OAuth without mcp scope' do
        let(:insufficient_access_token) { create(:oauth_access_token, user: user, scopes: [:api]) }

        it 'returns forbidden' do
          post api('/mcp', user, oauth_access_token: insufficient_access_token),
            params: { jsonrpc: '2.0', method: 'initialize', id: '1' }

          expect(response).to have_gitlab_http_status(:forbidden)
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
  end

  describe 'GET /mcp' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/mcp')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(mcp_server: false)
        end

        it 'returns not found' do
          get api('/mcp', user, oauth_access_token: access_token)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it 'returns not implemented' do
        get api('/mcp', user, oauth_access_token: access_token)

        expect(response).to have_gitlab_http_status(:not_implemented)
      end
    end
  end
end
