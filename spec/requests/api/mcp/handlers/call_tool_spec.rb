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

      context 'when x-gitlab-mcp-server-tool-name-prefix header is present' do
        subject(:tool_call) do
          post api('/mcp', user, oauth_access_token: access_token),
            params: params,
            headers: { 'X-Gitlab-Mcp-Server-Tool-Name-Prefix' => 'test_' }
        end

        let(:tool_params) { { name: 'test_get_issue', arguments: { id: project.full_path, issue_iid: issue.iid } } }

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

    context 'when a tool receives an unknown argument' do
      let(:invalid_params) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_work_item_types',
            arguments: { unexpected_argument: 'value' }
          },
          id: '1'
        }
      end

      subject(:call_tool) do
        post api('/mcp', user, oauth_access_token: access_token), params: invalid_params
      end

      it 'rejects the argument via the default additionalProperties: false' do
        call_tool

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text'])
          .to eq('Validation error: unexpected_argument is invalid')
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
        {
          name: 'get_merge_request',
          arguments: { project_id: project.full_path, merge_request_iid: merge_request.iid }
        }
      end

      it 'returns success response' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

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

  describe '#manage_pipeline' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :running) }
    let_it_be(:cancelable_build) { create(:ci_build, :running, pipeline: pipeline) }

    context 'when creating a pipeline' do
      let(:tool_params) do
        {
          name: 'manage_pipeline',
          arguments: {
            id: project.full_path,
            ref: project.default_branch
          }
        }
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(test: { script: 'echo test' }))
      end

      it 'creates a new pipeline' do
        expect do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json
        end.to change { project.ci_pipelines.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['structuredContent']['ref']).to eq(project.default_branch)
      end
    end

    context 'when canceling a pipeline' do
      let(:tool_params) do
        {
          name: 'manage_pipeline',
          arguments: {
            id: project.full_path,
            pipeline_id: pipeline.id,
            cancel: true
          }
        }
      end

      it 'cancels the pipeline', :sidekiq_inline do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(pipeline.reload.status).to be_in(%w[canceling canceled])
      end
    end

    context 'when retrying a pipeline' do
      let(:failed_pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :failed) }
      let!(:failed_build) { create(:ci_build, :failed, :retryable, pipeline: failed_pipeline) }

      let(:tool_params) do
        {
          name: 'manage_pipeline',
          arguments: {
            id: project.full_path,
            pipeline_id: failed_pipeline.id,
            retry: true
          }
        }
      end

      it 'retries the failed pipeline' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['content'].first['text']).to include('Pipeline retried successfully')
      end
    end

    context 'when deleting a pipeline' do
      let_it_be(:owner) { create(:user) }
      let_it_be(:owner_access_token) { create(:oauth_access_token, user: owner, scopes: [:mcp]) }
      let_it_be(:deletable_pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :success) }

      let(:tool_params) do
        {
          name: 'manage_pipeline',
          arguments: {
            id: project.full_path,
            pipeline_id: deletable_pipeline.id
          }
        }
      end

      before_all do
        project.add_owner(owner)
      end

      it 'deletes the pipeline' do
        expect do
          post api('/mcp', owner, oauth_access_token: owner_access_token), params: params, as: :json
        end.to change { project.ci_pipelines.count }.by(-1)

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when user does not have permission to delete' do
        let_it_be(:developer) { create(:user) }
        let_it_be(:developer_access_token) { create(:oauth_access_token, user: developer, scopes: [:mcp]) }

        let(:tool_params) do
          {
            name: 'manage_pipeline',
            arguments: {
              id: project.full_path,
              pipeline_id: deletable_pipeline.id
            }
          }
        end

        before_all do
          project.add_developer(developer)
        end

        it 'returns an error' do
          expect do
            post api('/mcp', developer, oauth_access_token: developer_access_token), params: params, as: :json
          end.not_to change { project.ci_pipelines.count }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include('403')
        end
      end
    end

    context 'with error handling' do
      context 'with ambiguous parameters' do
        let(:tool_params) do
          { name: 'manage_pipeline', arguments: { id: project.full_path } }
        end

        it 'returns clear error message' do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include('Cannot determine operation')
        end
      end

      context 'with non-existent ref' do
        let(:tool_params) do
          {
            name: 'manage_pipeline',
            arguments: {
              id: project.full_path,
              ref: 'non-existent-branch'
            }
          }
        end

        it 'returns error for invalid reference' do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include('Reference not found')
        end
      end
    end
  end

  describe '#list_pipelines' do
    let_it_be(:other_project) { create(:project, maintainers: [user]) }

    let_it_be(:success_pipeline) do
      create(:ci_pipeline, project: project, ref: 'master', status: :success, source: :push)
    end

    let_it_be(:failed_pipeline) do
      create(:ci_pipeline, project: project, ref: 'feature', status: :failed, source: :web)
    end

    let_it_be(:canceled_pipeline) do
      create(:ci_pipeline, project: project, ref: 'master', status: :canceled, source: :api)
    end

    let_it_be(:running_pipeline) do
      create(:ci_pipeline, project: project, ref: 'feature', status: :running, source: :schedule)
    end

    let_it_be(:other_project_pipeline) do
      create(:ci_pipeline, project: other_project, ref: 'master', status: :success, source: :push)
    end

    let(:tool_params) do
      { name: 'list_pipelines', arguments: { id: project.full_path } }
    end

    it 'returns only the requesting project pipelines with compact metadata', :aggregate_failures do
      post api('/mcp', user, oauth_access_token: access_token), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey

      items = json_response['result']['structuredContent']['items']
      expect(items.pluck('id')).to contain_exactly(
        success_pipeline.id, failed_pipeline.id, canceled_pipeline.id, running_pipeline.id
      )
      expect(items.first.keys).to include('id', 'status', 'ref', 'sha', 'source', 'web_url')
    end

    context 'when filtering by status' do
      let(:tool_params) do
        { name: 'list_pipelines', arguments: { id: project.full_path, status: 'failed' } }
      end

      it 'returns only pipelines matching the status' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response['result']['structuredContent']['items'].pluck('id')
        expect(ids).to contain_exactly(failed_pipeline.id)
      end
    end

    context 'when filtering by ref' do
      let(:tool_params) do
        { name: 'list_pipelines', arguments: { id: project.full_path, ref: 'feature' } }
      end

      it 'returns only pipelines matching the ref' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response['result']['structuredContent']['items'].pluck('id')
        expect(ids).to contain_exactly(failed_pipeline.id, running_pipeline.id)
      end
    end

    context 'when filtering by source' do
      let(:tool_params) do
        { name: 'list_pipelines', arguments: { id: project.full_path, source: 'web' } }
      end

      it 'returns only pipelines matching the source' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response['result']['structuredContent']['items'].pluck('id')
        expect(ids).to contain_exactly(failed_pipeline.id)
      end
    end

    context 'when filtering by created_after and created_before' do
      let_it_be(:old_pipeline) do
        create(:ci_pipeline, project: project, ref: 'master', created_at: 3.days.ago)
      end

      let(:tool_params) do
        {
          name: 'list_pipelines',
          arguments: {
            id: project.full_path,
            created_after: 2.days.ago.iso8601,
            created_before: 1.second.from_now.iso8601
          }
        }
      end

      it 'returns only pipelines created within the given range' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response['result']['structuredContent']['items'].pluck('id')
        expect(ids).to contain_exactly(
          success_pipeline.id, failed_pipeline.id, canceled_pipeline.id, running_pipeline.id
        )
      end

      context 'with a tight created_before upper bound' do
        let(:tool_params) do
          { name: 'list_pipelines', arguments: { id: project.full_path, created_before: 2.days.ago.iso8601 } }
        end

        it 'returns only pipelines created before the given time' do
          post api('/mcp', user, oauth_access_token: access_token), params: params

          expect(response).to have_gitlab_http_status(:ok)
          ids = json_response['result']['structuredContent']['items'].pluck('id')
          expect(ids).to contain_exactly(old_pipeline.id)
        end
      end
    end

    context 'when sorting by order_by and sort' do
      let(:tool_params) do
        { name: 'list_pipelines', arguments: { id: project.full_path, order_by: 'id', sort: 'asc' } }
      end

      it 'returns pipelines ordered accordingly' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response['result']['structuredContent']['items'].pluck('id')
        expect(ids).to eq(
          [success_pipeline.id, failed_pipeline.id, canceled_pipeline.id, running_pipeline.id].sort
        )
      end

      context 'with a non-default order_by column' do
        let(:tool_params) do
          { name: 'list_pipelines', arguments: { id: project.full_path, order_by: 'status', sort: 'asc' } }
        end

        it 'orders by the given column instead of the default' do
          post api('/mcp', user, oauth_access_token: access_token), params: params

          expect(response).to have_gitlab_http_status(:ok)
          ids = json_response['result']['structuredContent']['items'].pluck('id')
          expect(ids).to eq(
            [canceled_pipeline.id, failed_pipeline.id, running_pipeline.id, success_pipeline.id]
          )
        end
      end
    end

    context 'when combining ref and status filters' do
      let(:tool_params) do
        { name: 'list_pipelines', arguments: { id: project.full_path, ref: 'feature', status: 'running' } }
      end

      it 'returns only pipelines matching every filter' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response['result']['structuredContent']['items'].pluck('id')
        expect(ids).to contain_exactly(running_pipeline.id)
      end
    end

    context 'when no pipeline matches the filters' do
      let(:tool_params) do
        { name: 'list_pipelines', arguments: { id: project.full_path, ref: 'does-not-exist' } }
      end

      it 'returns an empty list' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['items']).to eq([])
      end
    end

    context 'with pagination' do
      let(:tool_params) do
        { name: 'list_pipelines', arguments: { id: project.full_path, per_page: 2, page: 1 } }
      end

      it 'returns the requested page size' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['items'].size).to eq(2)
      end

      it 'returns a different page of pipelines for page 2', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params
        first_page_ids = json_response['result']['structuredContent']['items'].pluck('id')

        post api('/mcp', user, oauth_access_token: access_token),
          params: params.deep_merge(params: { arguments: { page: 2 } })
        second_page_ids = json_response['result']['structuredContent']['items'].pluck('id')

        all_ids = [success_pipeline.id, failed_pipeline.id, canceled_pipeline.id, running_pipeline.id]
        expect(first_page_ids.size).to eq(2)
        expect(second_page_ids.size).to eq(2)
        expect(first_page_ids + second_page_ids).to match_array(all_ids)
      end
    end

    context 'when caller does not have permission to read pipelines' do
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:unauthorized_access_token) { create(:oauth_access_token, user: unauthorized_user, scopes: [:mcp]) }

      it 'returns a non-leaky not found error' do
        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('404 Project Not Found')
      end
    end
  end

  describe '#add_branch' do
    let(:tool_params) do
      { name: 'add_branch', arguments: { project_id: project.full_path, branch: 'my-feature', ref: 'master' } }
    end

    it 'creates the branch', :aggregate_failures do
      post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey
      expect(json_response['result']['structuredContent']['branch']['name']).to eq('my-feature')
      expect(project.repository.branch_exists?('my-feature')).to be true
    end

    context 'when called as the create_branch alias' do
      let(:tool_params) do
        {
          name: 'create_branch',
          arguments: { project_id: project.full_path, branch: 'another-feature', ref: 'master' }
        }
      end

      it 'creates the branch' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(project.repository.branch_exists?('another-feature')).to be true
      end
    end

    context 'when called with a url instead of project_id' do
      let(:tool_params) do
        {
          name: 'add_branch',
          arguments: {
            url: "https://gitlab.example.com/#{project.full_path}", branch: 'feature-via-url', ref: 'master'
          }
        }
      end

      it 'creates the branch' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(project.repository.branch_exists?('feature-via-url')).to be true
      end
    end

    context 'when the ref does not exist' do
      let(:tool_params) do
        { name: 'add_branch',
          arguments: { project_id: project.full_path, branch: 'my-feature', ref: 'does-not-exist' } }
      end

      it 'returns an error' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
      end
    end
  end

  # Facet, filter, and pagination behaviour is covered in the tool spec. These examples only cover
  # what the tool spec cannot: that arguments survive the JSON-RPC round trip and that the endpoint
  # enforces access.
  describe '#get_pipeline' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :success, source: :push) }
    let_it_be(:build) { create(:ci_build, :failed, pipeline: pipeline, name: 'rspec') }

    let(:arguments) { { id: project.full_path, pipeline_id: pipeline.id } }
    let(:tool_params) { { name: 'get_pipeline', arguments: arguments } }

    it 'returns success response' do
      post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey
      expect(json_response['result']['structuredContent']).to include(
        'id' => pipeline.id, 'status' => 'success', 'ref' => 'master'
      )
    end

    context 'with an include facet and a filter' do
      let(:arguments) { super().merge(include: ['jobs'], job_status: 'failed') }

      it 'returns the filtered facet' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['jobs'].pluck('id')).to contain_exactly(build.id)
      end
    end

    context 'when caller does not have permission to read the pipeline' do
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:unauthorized_access_token) { create(:oauth_access_token, user: unauthorized_user, scopes: [:mcp]) }

      it 'returns a non-leaky not-found error' do
        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('Project not found')
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
