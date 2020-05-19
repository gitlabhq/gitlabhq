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
  end

  describe 'POST /projects/:id/remote_mirrors' do
    let(:route) { "/projects/#{project.id}/remote_mirrors" }

    shared_examples 'creates a remote mirror' do
      it 'creates a remote mirror and returns reponse' do
        project.add_maintainer(user)

        post api(route, user), params: params

        enabled = params.fetch(:enabled, false)
        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('remote_mirror')
        expect(json_response['enabled']).to eq(enabled)
      end
    end

    it 'requires `admin_remote_mirror` permission' do
      post api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'creates a remote mirror' do
      context 'disabled by default' do
        let(:params) { { url: 'https://foo:bar@test.com' } }

        it_behaves_like 'creates a remote mirror'
      end

      context 'enabled' do
        let(:params) { { url: 'https://foo:bar@test.com', enabled: true } }

        it_behaves_like 'creates a remote mirror'
      end
    end

    it 'returns error if url is invalid' do
      project.add_maintainer(user)

      post api(route, user), params: {
        url: 'ftp://foo:bar@test.com'
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['url']).to eq(["is blocked: Only allowed schemes are ssh, git, http, https"])
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
        only_protected_branches: 'true',
        keep_divergent_refs: 'true'
      }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response['enabled']).to eq(false)
      expect(json_response['only_protected_branches']).to eq(true)
      expect(json_response['keep_divergent_refs']).to eq(true)
    end
  end
end
