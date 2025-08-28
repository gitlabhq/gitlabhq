# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'Call tool request', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, maintainers: [user]) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp, :api]) }

  let(:params) do
    {
      jsonrpc: '2.0',
      method: 'tools/call',
      params: tool_params,
      id: '1'
    }
  end

  describe 'POST /mcp_server with tools/call method' do
    let(:tool_params) do
      { name: 'get_issue', arguments: { id: project.full_path, issue_iid: issue.iid } }
    end

    context 'with valid tool name' do
      it 'returns success response' do
        post api('/mcp_server', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['jsonrpc']).to eq(params[:jsonrpc])
        expect(json_response['id']).to eq(params[:id])
        expect(json_response.keys).to include('result')
        expect(json_response['result']['content']).to be_an(Array)
        expect(json_response['result']['content'].first['type']).to eq('text')
        expect(json_response['result']['content'].first['text']).to include(issue.title)
        expect(json_response['result']['structuredContent']['title']).to eq(issue.title)
        expect(json_response['result']['isError']).to be_falsey
      end

      context 'with insufficient scopes' do
        let(:insufficient_access_token) { create(:oauth_access_token, user: user, scopes: [:api]) }

        it 'returns insufficient scopes error' do
          post api('/mcp_server', user, oauth_access_token: insufficient_access_token), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when a user does not have access to the project' do
        let_it_be(:issue) { create(:issue) }
        let_it_be(:project) { issue.project }

        it 'returns not found' do
          post api('/mcp_server', user, oauth_access_token: access_token), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include('404 Project Not Found')
          expect(json_response['result']['structuredContent']).to eq({
            "error" => { "message" => "404 Project Not Found" }
          })
        end
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
        post api('/mcp_server', user, oauth_access_token: access_token), params: invalid_params
      end

      it 'returns success HTTP status with error result' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('iid is missing')
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
        post api('/mcp_server', user, oauth_access_token: access_token), params: params
      end

      it 'returns invalid params error' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']['code']).to eq(-32602)
        expect(json_response['error']['data']['params']).to eq('name is unsupported')
      end
    end
  end

  describe '#get_merge_request' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    let(:tool_params) do
      { name: 'get_merge_request', arguments: { id: project.full_path, merge_request_iid: merge_request.iid } }
    end

    it 'returns success response' do
      post api('/mcp_server', user, oauth_access_token: access_token), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['content'].first['text']).to include(merge_request.title)
      expect(json_response['result']['structuredContent']['title']).to eq(merge_request.title)
      expect(json_response['result']['isError']).to be_falsey
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
