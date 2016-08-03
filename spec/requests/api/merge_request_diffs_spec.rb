require "spec_helper"

describe API::API, 'MergeRequestDiffs', api: true  do
  include ApiHelpers

  let!(:user)          { create(:user) }
  let!(:merge_request) { create(:merge_request, importing: true) }
  let!(:project)       { merge_request.target_project }

  before do
    merge_request.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
    merge_request.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e')
    project.team << [user, :master]
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_id/versions' do
    context 'valid merge request' do
      before { get api("/projects/#{project.id}/merge_requests/#{merge_request.id}/versions", user) }
      let(:merge_request_diff) { merge_request.merge_request_diffs.first }

      it { expect(response.status).to eq 200 }
      it { expect(json_response.size).to eq(merge_request.merge_request_diffs.size) }
      it { expect(json_response.first['id']).to eq(merge_request_diff.id) }
      it { expect(json_response.first['head_commit_sha']).to eq(merge_request_diff.head_commit_sha) }
    end

    it 'returns a 404 when merge_request_id not found' do
      get api("/projects/#{project.id}/merge_requests/999/versions", user)
      expect(response).to have_http_status(404)
    end
  end
end
