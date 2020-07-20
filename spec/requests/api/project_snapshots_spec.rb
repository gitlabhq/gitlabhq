# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectSnapshots do
  include WorkhorseHelpers

  let(:project) { create(:project) }
  let(:admin) { create(:admin) }

  before do
    allow(Feature::Gitaly).to receive(:server_feature_flags).and_return({
      'gitaly-feature-foobar' => 'true'
    })
  end

  describe 'GET /projects/:id/snapshot' do
    def expect_snapshot_response_for(repository)
      type, params = workhorse_send_data

      expect(type).to eq('git-snapshot')
      expect(params).to eq(
        'GitalyServer' => {
          'features' => { 'gitaly-feature-foobar' => 'true' },
          'address' => Gitlab::GitalyClient.address(repository.project.repository_storage),
          'token' => Gitlab::GitalyClient.token(repository.project.repository_storage)
        },
        'GetSnapshotRequest' => Gitaly::GetSnapshotRequest.new(
          repository: repository.gitaly_repository
        ).to_json
      )
    end

    it 'returns authentication error as project owner' do
      get api("/projects/#{project.id}/snapshot", project.owner)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns authentication error as unauthenticated user' do
      get api("/projects/#{project.id}/snapshot", nil)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'requests project repository raw archive as administrator' do
      get api("/projects/#{project.id}/snapshot", admin), params: { wiki: '0' }

      expect(response).to have_gitlab_http_status(:ok)
      expect_snapshot_response_for(project.repository)
    end

    it 'requests wiki repository raw archive as administrator' do
      get api("/projects/#{project.id}/snapshot", admin), params: { wiki: '1' }

      expect(response).to have_gitlab_http_status(:ok)
      expect_snapshot_response_for(project.wiki.repository)
    end
  end
end
