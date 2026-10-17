# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MCP granular token authorization', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, freeze: false) { create(:project, :repository, group: group, maintainers: [user]) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:release) { create(:release, project: project) }

  let(:project_permissions) { [] }
  let(:project_scopes) do
    next [] if project_permissions.empty?

    [{ boundary: ::Authz::Boundary.for(project), permissions: project_permissions }]
  end

  let(:pat) do
    create(:granular_pat,
      user: user,
      boundary: ::Authz::Boundary.for(:user),
      permissions: :execute_mcp_tool,
      additional_scopes: project_scopes
    )
  end

  subject(:tool_result) do
    post api('/mcp', personal_access_token: pat),
      params: { jsonrpc: '2.0', method: 'tools/call', id: '1', params: tool_params }

    json_response['result']
  end

  before do
    stub_application_setting(instance_level_ai_beta_features_enabled: true)
  end

  shared_examples 'a tool enforcing granular token permissions' do |permissions|
    it 'denies a token that only has execute_mcp_tool' do
      expect(tool_result['isError']).to be(true)
    end

    context 'when the token has the matching project permissions' do
      let(:project_permissions) { permissions }

      it 'runs the tool' do
        expect(tool_result['isError']).to be(false)
      end
    end
  end

  context 'with a custom tool' do
    let(:tool_params) { { name: 'list_releases', arguments: { project_id: project.full_path } } }

    it_behaves_like 'a tool enforcing granular token permissions', %i[read_release]

    it 'reports the missing permission' do
      expect(tool_result['content'].first['text']).to include('Access denied: This operation requires')
    end
  end

  context 'with a REST tool' do
    let(:tool_params) { { name: 'get_issue', arguments: { id: project.full_path, issue_iid: issue.iid } } }

    it_behaves_like 'a tool enforcing granular token permissions', %i[read_work_item]
  end

  context 'with an aggregated tool' do
    let(:tool_params) do
      { name: 'search', arguments: { scope: 'work_items', search: issue.title, project_id: project.id.to_s } }
    end

    it_behaves_like 'a tool enforcing granular token permissions', %i[use_global_search]
  end
end
