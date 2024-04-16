# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RemoteMirrors, feature_category: :source_code_management do
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

  describe 'GET /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror.id}" }
    let(:mirror) { project.remote_mirrors.first }

    it 'requires `admin_remote_mirror` permission' do
      get api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns at remote mirror' do
      project.add_maintainer(user)

      get api(route, user)

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to match_response_schema('remote_mirror')
    end
  end

  describe 'POST /projects/:id/remote_mirrors/:mirror_id/sync' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror_id}/sync" }
    let(:mirror) { project.remote_mirrors.first }
    let(:mirror_id) { mirror.id }

    context 'without enough permissions' do
      it 'requires `admin_remote_mirror` permission' do
        post api(route, developer)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with sufficient permissions' do
      before do
        project.add_maintainer(user)
      end

      it 'returns a successful response' do
        post api(route, user)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'when some error occurs' do
        before do
          mirror.update!(enabled: false)
        end

        it 'returns an error' do
          post api(route, user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to match(/Cannot proceed with the push mirroring/)
        end
      end

      context 'when mirror ID is missing' do
        let(:mirror_id) { non_existing_record_id }

        it 'returns a not found error' do
          post api(route, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /projects/:id/remote_mirrors' do
    let(:route) { "/projects/#{project.id}/remote_mirrors" }

    shared_examples 'creates a remote mirror' do
      it 'creates a remote mirror and returns response' do
        project.add_maintainer(user)

        post api(route, user), params: params

        enabled = params.fetch(:enabled, false)
        auth_method = params.fetch(:auth_method, 'password')
        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('remote_mirror')
        expect(json_response['enabled']).to eq(enabled)
        expect(json_response['auth_method']).to eq(auth_method)
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

      context 'auth method' do
        let(:params) { { url: 'https://foo:bar@test.com', enabled: true, auth_method: 'ssh_public_key' } }

        it_behaves_like 'creates a remote mirror'
      end
    end

    it 'returns error if url is invalid' do
      project.add_maintainer(user)

      post api(route, user), params: {
        url: 'ftp://foo:bar@test.com'
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['url']).to match_array(
        ["is blocked: Only allowed schemes are http, https, ssh, git"]
      )
    end

    context 'when auth method is invalid' do
      let(:params) { { url: 'https://foo:bar@test.com', enabled: true, auth_method: 'invalid' } }

      it 'returns an error' do
        project.add_maintainer(user)

        post api(route, user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('auth_method does not have a valid value')
      end
    end
  end

  describe 'PUT /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror.id}" }
    let(:mirror) { project.remote_mirrors.first }

    it 'requires `admin_remote_mirror` permission' do
      put api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'updates a remote mirror' do
      project.add_maintainer(user)

      put api(route, user), params: {
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

  describe 'DELETE /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { ->(id) { "/projects/#{project.id}/remote_mirrors/#{id}" } }
    let(:mirror) { project.remote_mirrors.first }

    it 'requires `admin_remote_mirror` permission' do
      expect { delete api(route[mirror.id], developer) }.not_to change { project.remote_mirrors.count }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns 404 for non existing id' do
        delete api(route[non_existing_record_id], user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns bad request if the update service fails' do
        expect_next_instance_of(Projects::UpdateService) do |service|
          expect(service).to receive(:execute).and_return(status: :error, message: 'message')
        end

        expect { delete api(route[mirror.id], user) }.not_to change { project.remote_mirrors.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => 'message' })
      end

      it 'deletes a remote mirror' do
        expect { delete api(route[mirror.id], user) }.to change { project.remote_mirrors.count }.from(1).to(0)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end
end
