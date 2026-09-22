# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mcp scope route restriction', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:mcp_token) { create(:personal_access_token, user: user, scopes: [:mcp]) }

  before_all do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/pipelines' do
    it 'is allowed, since this route is a registered mcp tool' do
      get api("/projects/#{project.id}/pipelines", personal_access_token: mcp_token)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  # Pipeline variables often hold credentials, and this route is not an mcp tool, so an
  # mcp-scoped token must not reach it even though it shares a verb with the tool routes.
  describe 'GET /projects/:id/pipelines/:pipeline_id/variables' do
    it 'is rejected, since this route is not a registered mcp tool' do
      get api("/projects/#{project.id}/pipelines/#{pipeline.id}/variables", personal_access_token: mcp_token)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['error']).to eq('insufficient_scope')
    end
  end

  describe 'PUT /projects/:id/merge_requests/:merge_request_iid' do
    it 'is allowed, since this route is a registered mcp tool' do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", personal_access_token: mcp_token),
        params: { title: 'Updated title' }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  # Merging bypasses review requirements, and this route is not an mcp tool, so an
  # mcp-scoped token must not reach it even though it shares a verb with the tool route above.
  describe 'PUT /projects/:id/merge_requests/:merge_request_iid/merge' do
    it 'is rejected, since this route is not a registered mcp tool' do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", personal_access_token: mcp_token)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['error']).to eq('insufficient_scope')
    end
  end
end
