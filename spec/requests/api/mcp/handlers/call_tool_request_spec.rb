# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'Call tool request', feature_category: :api do
  let_it_be(:user) { create(:user) }
  let(:oauth_token) { instance_double(Doorkeeper::AccessToken) }

  before do
    allow(Doorkeeper::OAuth::Token).to receive(:from_request).and_return(oauth_token)
  end

  describe 'POST /mcp with tools/call method' do
    context 'with valid tool name' do
      let(:mock_tool_name) { 'get_mcp_server_version' }
      let(:params) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: { name: mock_tool_name },
          id: '1'
        }
      end

      before do
        post api('/mcp', user), params: params
      end

      it 'returns success response' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['jsonrpc']).to eq(params[:jsonrpc])
        expect(json_response['id']).to eq(params[:id])
        expect(json_response.keys).to include('result')
      end

      it 'returns tool result with content' do
        expect(json_response['result']['content']).to be_an(Array)
        expect(json_response['result']['content'].first).to include(
          'type' => 'text',
          'text' => Gitlab::VERSION.to_s
        )
      end

      it 'returns isError false' do
        expect(json_response['result']['isError']).to be_falsey
      end
    end

    context 'with tool validation errors' do
      let(:invalid_params) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_issue',
            arguments: { id: 'project-id' }
          },
          id: '1'
        }
      end

      before do
        post api('/mcp', user), params: invalid_params
      end

      it 'returns success HTTP status with error result' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('iid is missing')
      end
    end

    context 'without params' do
      let(:params) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          id: '1'
        }
      end

      before do
        post api('/mcp', user), params: params
      end

      it 'returns invalid params error' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']['code']).to eq(-32602)
        expect(json_response['error']['message']).to eq('Invalid params')
        expect(json_response['error']['data']['params']).to eq('name is missing')
      end
    end

    context 'with empty name' do
      let(:params) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: { name: '' },
          id: '1'
        }
      end

      before do
        post api('/mcp', user), params: params
      end

      it 'returns invalid params error' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']['code']).to eq(-32602)
        expect(json_response['error']['data']['params']).to eq('name is empty')
      end
    end

    context 'with unknown tool name' do
      let(:params) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: { name: 'unknown_tool' },
          id: '1'
        }
      end

      before do
        post api('/mcp', user), params: params
      end

      it 'returns invalid params error' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']['code']).to eq(-32602)
        expect(json_response['error']['data']['params']).to eq('name is unsupported')
      end
    end
  end

  context 'without OAuth token' do
    before do
      allow(Doorkeeper::OAuth::Token).to receive(:from_request).and_return(nil)
    end

    it 'returns unauthorized' do
      params = {
        jsonrpc: '2.0',
        method: 'tools/call',
        params: { name: 'get_mcp_server_version' },
        id: '1'
      }

      post api('/mcp', user), params: params

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(json_response['message']).to eq('401 Unauthorized')
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
