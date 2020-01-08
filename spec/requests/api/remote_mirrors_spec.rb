# frozen_string_literal: true

require 'spec_helper'

describe API::RemoteMirrors do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :remote_mirror) }
  let_it_be(:developer) { create(:user) { |u| project.add_developer(u) } }

  describe 'GET /projects/:id/remote_mirrors' do
    let(:route) { "/projects/#{project.id}/remote_mirrors" }

    it 'requires `admin_remote_mirror` permission' do
      get api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a list of remote mirrors' do
      project.add_maintainer(user)

      get api(route, user)

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to match_response_schema('remote_mirrors')
    end

    # TODO: Remove flag: https://gitlab.com/gitlab-org/gitlab/issues/38121
    context 'with the `remote_mirrors_api` feature disabled' do
      before do
        stub_feature_flags(remote_mirrors_api: false)
      end

      it 'responds with `not_found`' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { ->(id) { "/projects/#{project.id}/remote_mirrors/#{id}" } }
    let(:mirror) { project.remote_mirrors.first }

    it 'requires `admin_remote_mirror` permission' do
      put api(route[mirror.id], developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'updates a remote mirror' do
      project.add_maintainer(user)

      put api(route[mirror.id], user), params: {
        enabled: '0',
        only_protected_branches: 'true'
      }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response['enabled']).to eq(false)
      expect(json_response['only_protected_branches']).to eq(true)
    end

    # TODO: Remove flag: https://gitlab.com/gitlab-org/gitlab/issues/38121
    context 'with the `remote_mirrors_api` feature disabled' do
      before do
        stub_feature_flags(remote_mirrors_api: false)
      end

      it 'responds with `not_found`' do
        put api(route[mirror.id], user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
