# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'Call tool request', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, maintainers: [user]) }
  let_it_be(:project) { create(:project, :repository, group: group, maintainers: [user]) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  let(:params) do
    {
      jsonrpc: '2.0',
      method: 'tools/call',
      params: tool_params,
      id: '1'
    }
  end

  before do
    stub_application_setting(instance_level_ai_beta_features_enabled: true)
  end

  describe 'POST /mcp with tools/call method' do
    let(:tool_params) do
      { name: 'get_issue', arguments: { id: project.full_path, issue_iid: issue.iid } }
    end

    context 'with valid tool name' do
      subject(:tool_call) { post api('/mcp', user, oauth_access_token: access_token), params: params }

      it 'returns success response' do
        tool_call

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
          post api('/mcp', user, oauth_access_token: insufficient_access_token), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when a user does not have access to the project' do
        let_it_be(:issue) { create(:issue) }
        let_it_be(:project) { issue.project }

        it 'returns not found' do
          post api('/mcp', user, oauth_access_token: access_token), params: params

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

      subject(:call_tool) do
        post api('/mcp', user, oauth_access_token: access_token), params: invalid_params
      end

      before do
        call_tool
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

      subject(:tool_call) { post api('/mcp', user, oauth_access_token: access_token), params: params }

      it 'returns invalid params error' do
        tool_call

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']['code']).to eq(-32602)
        expect(json_response['error']['data']['params']).to include("Tool 'unknown_tool' not found")
      end
    end
  end

  describe 'merge request tools' do
    let_it_be(:merge_request) do
      create(:merge_request, :with_head_pipeline, source_project: project, target_project: project)
    end

    describe '#get_merge_request' do
      let(:tool_params) do
        { name: 'get_merge_request', arguments: { id: project.full_path, merge_request_iid: merge_request.iid } }
      end

      it 'returns success response' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['content'].first['text']).to include(merge_request.title)
        expect(json_response['result']['structuredContent']['title']).to eq(merge_request.title)
        expect(json_response['result']['isError']).to be_falsey
      end
    end

    describe '#get_merge_request_diffs' do
      let(:tool_params) do
        { name: 'get_merge_request_diffs', arguments: { id: project.full_path, merge_request_iid: merge_request.iid } }
      end

      it 'returns success response' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)

        first_diff = API::Entities::Diff.new(merge_request.merge_request_diff.paginated_diffs(1, 1).diffs.first).as_json
        expect(json_response['result']['content'].first['text']).to include(first_diff.to_json)
        expect(json_response['result']['structuredContent']['items']).to include(first_diff.stringify_keys)
        expect(json_response['result']['isError']).to be_falsey
      end
    end

    describe '#get_merge_request_commits' do
      let(:tool_params) do
        { name: 'get_merge_request_commits',
          arguments: { id: project.full_path, merge_request_iid: merge_request.iid } }
      end

      it 'returns success response' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)

        first_commit = API::Entities::Commit.new(merge_request.commits(load_from_gitaly: true).first).as_json
        expect(json_response['result']['content'].first['text']).to include(first_commit.to_json)
        expect(json_response['result']['structuredContent']['items']).to include(first_commit.stringify_keys)
        expect(json_response['result']['isError']).to be_falsey
      end
    end

    describe '#get_merge_request_pipelines' do
      let(:tool_params) do
        { name: 'get_merge_request_pipelines',
          arguments: { id: project.full_path, merge_request_iid: merge_request.iid } }
      end

      it 'returns success response' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        first_pipeline = ::API::Entities::Ci::PipelineBasic.new(merge_request.head_pipeline).as_json

        expect(json_response['result']['content'].first['text']).to include(first_pipeline.to_json)
        expect(json_response['result']['structuredContent']['items'][0].without('created_at', 'updated_at')).to eq(
          first_pipeline.stringify_keys.without('created_at', 'updated_at')
        )
        expect(json_response['result']['isError']).to be_falsey
      end
    end
  end

  describe 'issue tools' do
    let_it_be(:milestone) { create(:milestone, group: group) }
    let_it_be(:label) { create(:group_label, group: group) }
    let_it_be(:label2) { create(:group_label, group: group) }

    describe '#create_issue' do
      let(:tool_params) do
        {
          name: 'create_issue',
          arguments: {
            id: project.full_path,
            title: 'title',
            description: 'description',
            assignee_ids: [user.id],
            labels: "#{label.name},#{label2.name}",
            milestone_id: milestone.id
          }
        }
      end

      it 'returns success response' do
        expect do
          post api('/mcp', user, oauth_access_token: access_token), params: params
        end.to change { project.reload.issues.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)

        issue = project.issues.last
        expect(issue.title).to eq('title')
        expect(issue.description).to eq('description')
        expect(issue.assignees).to eq([user])
        expect(issue.labels).to contain_exactly(label, label2)
        expect(issue.milestone).to eq(milestone)
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
