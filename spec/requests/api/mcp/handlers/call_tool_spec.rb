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

    context 'when the tool is unlisted' do
      let(:tool_params) { { name: 'get_mcp_server_version', arguments: {} } }

      before do
        allow_next_instance_of(::Mcp::Tools::GetServerVersionService) do |tool|
          allow(tool).to receive(:unlisted?).and_return(true)
        end
      end

      it 'still executes because unlisted only affects discovery' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
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

    describe '#get_repository_file' do
      let(:tool_params) do
        {
          name: 'get_repository_file',
          arguments: { project_id: project.full_path, file_path: 'files/ruby/popen.rb', ref: project.default_branch }
        }
      end

      it 'returns success response' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['structuredContent']['path']).to eq('files/ruby/popen.rb')
        expect(json_response['result']['structuredContent']['content']).to include('module Popen')
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

  describe 'commit tools' do
    let_it_be(:commit) { project.commit }

    describe '#get_commit' do
      let(:tool_params) do
        { name: 'get_commit', arguments: { project_id: project.full_path, commit_sha: commit.sha } }
      end

      it 'returns success response', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['sha']).to eq(commit.sha)
        expect(json_response['result']['content'].first['text']).to include(commit.sha)
        expect(json_response['result']['isError']).to be_falsey
      end

      context 'with the diff facet and stats detail' do
        let(:tool_params) do
          {
            name: 'get_commit',
            arguments: {
              project_id: project.full_path, commit_sha: commit.sha, include: ['diff'], diff_detail: 'stats'
            }
          }
        end

        it 'includes diff stats', :aggregate_failures do
          post api('/mcp', user, oauth_access_token: access_token), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['structuredContent']['diffStatsSummary']).to include('additions', 'deletions')
          expect(json_response['result']['isError']).to be_falsey
        end
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

  describe '#fork_repository' do
    let_it_be(:target_group) { create(:group, maintainers: [user]) }

    let(:tool_params) do
      { name: 'fork_repository', arguments: { id: project.full_path, namespace_id: target_group.id } }
    end

    it 'forks the project into the target namespace', :aggregate_failures do
      post api('/mcp', user, oauth_access_token: access_token), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey
      structured_content = json_response['result']['structuredContent']
      expect(structured_content['forked_from_project']['id']).to eq(project.id)
      expect(structured_content['namespace']['id']).to eq(target_group.id)
      expect(structured_content['import_status']).to eq('scheduled')
    end

    context 'when the target namespace is given as a path' do
      let(:tool_params) do
        { name: 'fork_repository', arguments: { id: project.full_path, namespace_path: target_group.full_path } }
      end

      it 'forks the project into the target namespace', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        structured_content = json_response['result']['structuredContent']
        expect(structured_content['forked_from_project']['id']).to eq(project.id)
        expect(structured_content['namespace']['id']).to eq(target_group.id)
      end
    end

    context 'when the target namespace already has a project with the same path' do
      let_it_be(:existing_project) do
        create(:project, name: project.name, path: project.path, namespace: target_group)
      end

      it 'returns a conflict error', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('has already been taken')
      end
    end

    context 'when the project does not exist' do
      let(:tool_params) do
        { name: 'fork_repository', arguments: { id: non_existing_record_id } }
      end

      it 'returns a not found error', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('404 Project Not Found')
      end
    end

    context 'when the user does not have create-project rights in the target namespace' do
      let_it_be(:other_group) { create(:group, guests: [user]) }

      let(:tool_params) do
        { name: 'fork_repository', arguments: { id: project.full_path, namespace_id: other_group.id } }
      end

      it 'returns a not found error', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('404 Target Namespace Not Found')
      end
    end
  end

  describe '#accept_merge_request' do
    let_it_be(:merge_project) { create(:project, :repository, group: group, maintainers: [user]) }

    let(:merge_request) { create(:merge_request, source_project: merge_project) }

    context 'when merging immediately', :sidekiq_inline do
      let(:tool_params) do
        {
          name: 'accept_merge_request',
          arguments: {
            project_id: merge_project.full_path,
            merge_request_iid: merge_request.iid,
            sha: merge_request.diff_head_sha
          }
        }
      end

      it 'merges the merge request' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['structuredContent']['status']).to eq('merging')
        expect(merge_request.reload).to be_merged
      end
    end

    context 'when the sha is stale' do
      let(:tool_params) do
        {
          name: 'accept_merge_request',
          arguments: {
            project_id: merge_project.full_path,
            merge_request_iid: merge_request.iid,
            sha: 'deadbeef'
          }
        }
      end

      it 'refuses the merge' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be(true)
        expect(merge_request.reload).not_to be_merged
      end
    end
  end

  describe '#save_pipeline' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :running) }
    let_it_be(:cancelable_build) { create(:ci_build, :running, pipeline: pipeline) }

    context 'when creating a pipeline' do
      let(:tool_params) do
        {
          name: 'save_pipeline',
          arguments: {
            project_id: project.full_path,
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
          name: 'save_pipeline',
          arguments: {
            pipeline_id: pipeline.id,
            action: 'cancel'
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

    context 'when renaming a pipeline' do
      let(:tool_params) do
        {
          name: 'save_pipeline',
          arguments: {
            pipeline_id: pipeline.id,
            action: 'update',
            name: 'Nightly build'
          }
        }
      end

      it 'renames the pipeline', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['structuredContent']['name']).to eq('Nightly build')
        expect(pipeline.reload.name).to eq('Nightly build')
      end
    end

    context 'when retrying a pipeline' do
      let(:failed_pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :failed) }
      let!(:failed_build) { create(:ci_build, :failed, :retryable, pipeline: failed_pipeline) }

      let(:tool_params) do
        {
          name: 'save_pipeline',
          arguments: {
            pipeline_id: failed_pipeline.id,
            action: 'retry'
          }
        }
      end

      it 'retries the failed pipeline' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['structuredContent']).to include(
          'action' => 'retry', 'id' => failed_pipeline.id
        )
      end
    end

    context 'with error handling' do
      context 'with ambiguous parameters' do
        let(:tool_params) do
          { name: 'save_pipeline', arguments: { project_id: project.full_path } }
        end

        it 'returns clear error message' do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include(
            'Provide ref to create a pipeline, or pipeline_id and action'
          )
        end
      end

      context 'with pipeline_id but no action' do
        let(:tool_params) do
          { name: 'save_pipeline', arguments: { pipeline_id: pipeline.id } }
        end

        it 'returns clear error message' do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include(
            'Provide action: "retry", "cancel", or "update" when pipeline_id is set'
          )
        end
      end

      context 'with non-existent ref' do
        let(:tool_params) do
          {
            name: 'save_pipeline',
            arguments: {
              project_id: project.full_path,
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

  describe '#manage_pipeline' do
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
      context 'without pipeline_id' do
        let(:tool_params) do
          { name: 'manage_pipeline', arguments: { id: project.full_path } }
        end

        it 'returns clear error message' do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include('Validation error')
        end
      end

      context 'with non-existent pipeline_id' do
        let_it_be(:owner) { create(:user) }
        let_it_be(:owner_access_token) { create(:oauth_access_token, user: owner, scopes: [:mcp]) }

        let(:tool_params) do
          {
            name: 'manage_pipeline',
            arguments: {
              id: project.full_path,
              pipeline_id: non_existing_record_id
            }
          }
        end

        before_all do
          project.add_owner(owner)
        end

        it 'returns a not found error' do
          post api('/mcp', owner, oauth_access_token: owner_access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_truthy
          expect(json_response['result']['content'].first['text']).to include('Pipeline Not Found')
        end
      end
    end
  end

  describe '#list_branches' do
    let(:tool_params) do
      { name: 'list_branches', arguments: { id: project.full_path } }
    end

    shared_examples 'listing the project branches' do
      it 'returns the project branches', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey

        # The default page size is smaller than the fixture's branch count, so assert
        # the page belongs to this repository rather than naming a specific branch.
        items = json_response['result']['structuredContent']['items']
        expect(items).to be_present
        expect(project.repository.branch_names).to include(*items.pluck('name'))
        expect(items.first.keys).to include('name', 'default', 'protected', 'commit')
      end
    end

    context 'when branch_list_keyset_pagination is enabled' do
      before do
        stub_feature_flags(branch_list_keyset_pagination: project)
      end

      it_behaves_like 'listing the project branches'
    end

    context 'when branch_list_keyset_pagination is disabled' do
      before do
        stub_feature_flags(branch_list_keyset_pagination: false)
      end

      it_behaves_like 'listing the project branches'
    end

    context 'when filtering by name' do
      let(:tool_params) do
        { name: 'list_branches', arguments: { id: project.full_path, search: project.default_branch } }
      end

      it 'returns only branches matching the search term' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['items'].pluck('name'))
          .to contain_exactly(project.default_branch)
      end
    end

    context 'when the search term matches nothing' do
      let(:tool_params) do
        { name: 'list_branches', arguments: { id: project.full_path, search: 'does-not-exist' } }
      end

      it 'returns an empty list' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['items']).to be_empty
      end
    end

    context 'with pagination' do
      let(:tool_params) do
        { name: 'list_branches', arguments: { id: project.full_path, per_page: 2, page: 1 } }
      end

      # Page 1 is served by the Gitaly offset-header path while later pages fall back to
      # Kaminari, so the flag is pinned off to keep both pages on the same ordering.
      before do
        stub_feature_flags(branch_list_keyset_pagination: false)
      end

      it 'returns the requested page size' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['items'].size).to eq(2)
      end

      it 'returns a different page of branches for page 2', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params
        first_page = json_response['result']['structuredContent']['items'].pluck('name')

        post api('/mcp', user, oauth_access_token: access_token),
          params: params.deep_merge(params: { arguments: { page: 2 } })
        second_page = json_response['result']['structuredContent']['items'].pluck('name')

        expect(first_page.size).to eq(2)
        expect(second_page.size).to eq(2)
        expect(first_page & second_page).to be_empty
      end

      context 'when per_page exceeds the API maximum' do
        let(:tool_params) do
          { name: 'list_branches', arguments: { id: project.full_path, per_page: 500 } }
        end

        # The tool advertises no per_page ceiling of its own; the endpoint clamps to
        # Kaminari's max_per_page rather than rejecting the request.
        it 'clamps the page size instead of erroring', :aggregate_failures do
          post api('/mcp', user, oauth_access_token: access_token), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_falsey
          expect(json_response['result']['structuredContent']['items'].size)
            .to be_between(1, Kaminari.config.max_per_page)
        end
      end
    end

    context 'when caller does not have permission to read the repository' do
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:unauthorized_access_token) { create(:oauth_access_token, user: unauthorized_user, scopes: [:mcp]) }

      it 'returns a non-leaky not found error', :aggregate_failures do
        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('404 Project Not Found')
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

  describe '#list_project_members' do
    let_it_be(:inherited_developer) { create(:user, developer_of: group) }

    let(:tool_params) do
      { name: 'list_project_members', arguments: { project_id: project.full_path } }
    end

    it 'returns the direct project members with their roles', :aggregate_failures do
      post api('/mcp', user, oauth_access_token: access_token), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey

      items = json_response['result']['structuredContent']['items']
      expect(items.pluck('username')).to contain_exactly(user.username)
      expect(items.first).to include(
        'id' => user.id,
        'name' => user.name,
        'access_level' => Gitlab::Access::MAINTAINER,
        'access_level_name' => 'Maintainer',
        'expires_at' => nil
      )
    end

    context 'when include_inherited is true' do
      let(:tool_params) do
        { name: 'list_project_members', arguments: { project_id: project.full_path, include_inherited: true } }
      end

      it 'also returns members inherited from the parent group' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['items'].pluck('username'))
          .to include(inherited_developer.username)
      end
    end

    context 'when the caller cannot see the project' do
      let_it_be(:other_project) { create(:project, :private) }
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:unauthorized_access_token) do
        create(:oauth_access_token, user: unauthorized_user, scopes: [:mcp])
      end

      let(:tool_params) do
        { name: 'list_project_members', arguments: { project_id: other_project.full_path } }
      end

      it 'returns a non-leaky not found error', :aggregate_failures do
        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('not found or inaccessible')
      end
    end
  end

  describe '#list_releases' do
    # `Release belongs_to :project, touch: true`, so creating one writes to the project.
    # These projects cannot be frozen by `let_it_be`.
    let_it_be(:releases_project, freeze: false) do
      create(:project, :repository, group: group, maintainers: [user])
    end

    let_it_be(:other_project, freeze: false) { create(:project, :repository, maintainers: [user]) }

    let_it_be(:release_v1) do
      create(:release, project: releases_project, tag: 'v1.0', author: user, released_at: 3.days.ago)
    end

    let_it_be(:release_v2) do
      create(:release, project: releases_project, tag: 'v2.0', author: user, released_at: 2.days.ago)
    end

    let_it_be(:release_v3, freeze: false) do
      create(:release, project: releases_project, tag: 'v3.0', author: user, released_at: 1.day.ago)
    end

    let_it_be(:other_project_release) do
      create(:release, project: other_project, tag: 'v9.0', author: user)
    end

    let_it_be(:release_link) do
      create(:release_link, release: release_v3, name: 'Binary', url: 'https://example.com/v3.0/binary')
    end

    let(:tool_params) do
      { name: 'list_releases', arguments: { project_id: releases_project.full_path } }
    end

    let(:structured_content) { json_response['result']['structuredContent'] }

    it 'returns only the requested project releases, most recent first', :aggregate_failures do
      post api('/mcp', user, oauth_access_token: access_token), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey
      expect(structured_content['releases'].pluck('tag_name')).to eq(%w[v3.0 v2.0 v1.0])
    end

    it 'returns metadata-only entries with asset links', :aggregate_failures do
      post api('/mcp', user, oauth_access_token: access_token), params: params

      entry = structured_content['releases'].first
      expect(entry.keys).to match_array(%w[tag_name name released_at upcoming assets])
      expect(entry['assets']).to eq(
        'count' => 1,
        'links' => [{ 'name' => 'Binary', 'url' => 'https://example.com/v3.0/binary' }]
      )
    end

    it 'reports pagination state' do
      post api('/mcp', user, oauth_access_token: access_token), params: params

      expect(structured_content['metadata']).to eq(
        'page' => 1, 'per_page' => 20, 'has_more' => false
      )
    end

    context 'when identified by url instead of project_id' do
      let(:tool_params) do
        { name: 'list_releases', arguments: { url: releases_project.web_url } }
      end

      it 'resolves the project from the url' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(structured_content['releases'].pluck('tag_name')).to eq(%w[v3.0 v2.0 v1.0])
      end
    end

    context 'when neither url nor project_id is given' do
      let(:tool_params) { { name: 'list_releases', arguments: {} } }

      it 'returns an error naming the requirement', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text'])
          .to include('Provide exactly one of: url or project_id')
      end
    end

    context 'when arguments are omitted entirely' do
      let(:tool_params) { { name: 'list_releases' } }

      it 'returns an error naming the requirement', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text'])
          .to include('Provide exactly one of: url or project_id')
      end
    end

    context 'when both url and project_id are given' do
      let(:tool_params) do
        {
          name: 'list_releases',
          arguments: { url: releases_project.web_url, project_id: releases_project.full_path }
        }
      end

      it 'returns an error naming the requirement' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(json_response['result']['content'].first['text'])
          .to include('Provide exactly one of: url or project_id')
      end
    end

    context 'with pagination' do
      let(:tool_params) do
        { name: 'list_releases', arguments: { project_id: releases_project.full_path, per_page: 2 } }
      end

      it 'bounds the page and reports that more remain', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(structured_content['releases'].pluck('tag_name')).to eq(%w[v3.0 v2.0])
        expect(structured_content['metadata']).to eq(
          'page' => 1, 'per_page' => 2, 'has_more' => true
        )
      end

      it 'returns the remainder on the last page, with has_more false', :aggregate_failures do
        # `as: :json` matters: form encoding would send per_page as "2", and the schema requires
        # an integer.
        post api('/mcp', user, oauth_access_token: access_token),
          params: params.deep_merge(params: { arguments: { page: 2 } }), as: :json

        expect(structured_content['releases'].pluck('tag_name')).to eq(%w[v1.0])
        expect(structured_content['metadata']['has_more']).to be false
      end
    end

    context 'when per_page exceeds the maximum' do
      let(:tool_params) do
        { name: 'list_releases', arguments: { project_id: releases_project.full_path, per_page: 101 } }
      end

      it 'rejects the call rather than silently clamping', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('per_page')
      end
    end

    context 'when the project has no releases' do
      let_it_be(:empty_project) { create(:project, maintainers: [user]) }

      let(:tool_params) do
        { name: 'list_releases', arguments: { project_id: empty_project.full_path } }
      end

      it 'returns an empty list', :aggregate_failures do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(json_response['result']['isError']).to be_falsey
        expect(structured_content['releases']).to eq([])
        expect(structured_content['metadata']['has_more']).to be false
      end
    end

    context 'when the url points at a group' do
      let(:tool_params) do
        { name: 'list_releases', arguments: { url: group.web_url } }
      end

      it 'returns an error' do
        post api('/mcp', user, oauth_access_token: access_token), params: params

        expect(json_response['result']['isError']).to be_truthy
      end
    end

    context 'when caller cannot read the project' do
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:unauthorized_access_token) { create(:oauth_access_token, user: unauthorized_user, scopes: [:mcp]) }
      let_it_be(:private_project, freeze: false) { create(:project, :private) }
      let_it_be(:private_release) { create(:release, project: private_project, tag: 'v1.0') }

      let(:tool_params) do
        { name: 'list_releases', arguments: { project_id: private_project.full_path } }
      end

      it 'answers a private project exactly as it answers a missing one', :aggregate_failures do
        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token), params: params
        denied = json_response['result']['content'].first['text']

        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token),
          params: params.deep_merge(params: { arguments: { project_id: 'no/such-project' } })
        missing = json_response['result']['content'].first['text']

        expect(denied).to eq("Tool execution failed: Project '#{private_project.full_path}' not found or inaccessible")
        expect(missing).to eq("Tool execution failed: Project 'no/such-project' not found or inaccessible")
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

  describe '#get_job' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    # `let` rather than `let_it_be`, because a live trace does not survive between examples.
    let(:job) { create(:ci_build, :trace_live, :failed, pipeline: pipeline, name: 'rspec') }

    let(:arguments) { { id: project.full_path, job_id: job.id } }
    let(:tool_params) { { name: 'get_job', arguments: arguments } }

    it 'returns success response' do
      post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey
      expect(json_response['result']['structuredContent']).to include('id' => job.id, 'status' => 'failed')
      expect(json_response['result']['structuredContent']).not_to have_key('log')
    end

    context 'with the log facet' do
      let(:arguments) { super().merge(include: ['log']) }

      it 'returns the job log' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['log']['content']).to eq('BUILD TRACE')
      end
    end

    context 'when called as the get_job_log alias' do
      let(:tool_params) { { name: 'get_job_log', arguments: arguments } }

      it 'resolves to get_job and returns the log without an explicit include' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['structuredContent']['log']['content']).to eq('BUILD TRACE')
      end
    end

    context 'when caller does not have permission to read the job' do
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:unauthorized_access_token) { create(:oauth_access_token, user: unauthorized_user, scopes: [:mcp]) }

      it 'returns a non-leaky not-found error' do
        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('not found or inaccessible')
      end
    end
  end

  describe '#save_note' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:work_item) { create(:work_item, :issue, project: project) }

    context 'with a merge request target' do
      let(:tool_params) do
        {
          name: 'save_note',
          arguments: { project_id: project.full_path, merge_request_iid: merge_request.iid, body: 'LGTM' }
        }
      end

      it 'creates the note' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['structuredContent']['note']['body']).to eq('LGTM')
      end

      context 'when called as the create_merge_request_note alias' do
        let(:tool_params) do
          {
            name: 'create_merge_request_note',
            arguments: { project_id: project.full_path, merge_request_iid: merge_request.iid, body: 'LGTM' }
          }
        end

        it 'creates the note' do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_falsey
          expect(json_response['result']['structuredContent']['note']['body']).to eq('LGTM')
        end
      end
    end

    context 'with a work item target' do
      let(:tool_params) do
        {
          name: 'save_note',
          arguments: { project_id: project.full_path, work_item_iid: work_item.iid, body: 'Needs a rebase' }
        }
      end

      it 'creates the note' do
        post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_falsey
        expect(json_response['result']['structuredContent']['note']['body']).to eq('Needs a rebase')
      end

      context 'when called as the create_workitem_note alias' do
        let(:tool_params) do
          {
            name: 'create_workitem_note',
            arguments: { project_id: project.full_path, work_item_iid: work_item.iid, body: 'Needs a rebase' }
          }
        end

        it 'creates the note' do
          post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']['isError']).to be_falsey
          expect(json_response['result']['structuredContent']['note']['body']).to eq('Needs a rebase')
        end
      end
    end

    context 'when neither a merge request nor a work item identifier is provided' do
      let(:tool_params) do
        { name: 'save_note', arguments: { project_id: project.full_path, body: 'LGTM' } }
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

  describe '#list_repository_tree' do
    let(:arguments) { { project_id: project.full_path, path: 'files', ref: 'master' } }
    let(:tool_params) { { name: 'list_repository_tree', arguments: arguments } }

    it 'returns the tree entries at the requested path', :aggregate_failures do
      post api('/mcp', user, oauth_access_token: access_token), params: params, as: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_falsey
      expect(json_response['result']['structuredContent']['entries']).to include(
        a_hash_including('type' => 'tree', 'path' => 'files/ruby')
      )
      expect(json_response['result']['structuredContent']['pageInfo']).to include('hasNextPage' => false)
    end

    context 'when caller does not have access to the project' do
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:unauthorized_access_token) { create(:oauth_access_token, user: unauthorized_user, scopes: [:mcp]) }

      it 'returns an error without listing the tree' do
        post api('/mcp', unauthorized_user, oauth_access_token: unauthorized_access_token), params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['result']['isError']).to be_truthy
        expect(json_response['result']['content'].first['text']).to include('not found or inaccessible')
      end
    end
  end

  describe '#add_commit' do
    let_it_be(:guest) { create(:user) }
    let_it_be(:guest_access_token) { create(:oauth_access_token, user: guest, scopes: [:mcp]) }

    let(:tool_params) do
      {
        name: 'add_commit',
        arguments: {
          project_id: project.full_path,
          branch: project.default_branch,
          commit_message: 'Add MCP test file',
          actions: [{ action: 'create', file_path: 'mcp-test.txt', content: 'Test content' }]
        }
      }
    end

    before_all do
      project.add_guest(guest)
    end

    it 'returns an error when the user cannot push code' do
      expect do
        post api('/mcp', guest, oauth_access_token: guest_access_token), params: params, as: :json
      end.not_to change { project.repository.commit_count }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['result']['isError']).to be_truthy
      expect(json_response['result']['content'].first['text']).to include(
        "does not exist or you don't have permission to perform this action"
      )
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
