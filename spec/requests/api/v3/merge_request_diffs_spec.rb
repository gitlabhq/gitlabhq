require "spec_helper"

describe API::V3::MergeRequestDiffs, 'MergeRequestDiffs' do
  let!(:user)          { create(:user) }
  let!(:merge_request) { create(:merge_request, importing: true) }
  let!(:project)       { merge_request.target_project }

  before do
    merge_request.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
    merge_request.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e')
    project.add_master(user)
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_id/versions' do
    it 'returns 200 for a valid merge request' do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/versions", user)
      merge_request_diff = merge_request.merge_request_diffs.last

      expect(response.status).to eq 200
      expect(json_response.size).to eq(merge_request.merge_request_diffs.size)
      expect(json_response.first['id']).to eq(merge_request_diff.id)
      expect(json_response.first['head_commit_sha']).to eq(merge_request_diff.head_commit_sha)
    end

    it 'returns a 404 when merge_request_id not found' do
      get v3_api("/projects/#{project.id}/merge_requests/999/versions", user)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_id/versions/:version_id' do
    it 'returns a 200 for a valid merge request' do
      merge_request_diff = merge_request.merge_request_diffs.first
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/versions/#{merge_request_diff.id}", user)

      expect(response.status).to eq 200
      expect(json_response['id']).to eq(merge_request_diff.id)
      expect(json_response['head_commit_sha']).to eq(merge_request_diff.head_commit_sha)
      expect(json_response['diffs'].size).to eq(merge_request_diff.diffs.size)
    end

    it 'returns a 404 when merge_request_id not found' do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/versions/999", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
