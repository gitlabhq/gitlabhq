# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController, feature_category: :source_code_management do
  include GitHttpHelpers
  include GitlabShellHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :private, developers: user) }
  let_it_be(:public_project) { create(:project, :repository, :public) }

  let(:path) { "#{project.full_path}.git" }

  shared_examples 'a shell-authenticated SSH-over-HTTP endpoint rejecting unauthenticated requests' do
    context 'with valid Shell JWT but user without access' do
      let_it_be(:other_user) { create(:user) }

      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{other_user.id}" })
        )
      end

      it 'returns not found to avoid revealing project existence' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid Shell JWT for a blocked member' do
      let_it_be(:blocked) { create(:user, :blocked) }

      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{blocked.id}" })
        )
      end

      before_all do
        project.add_developer(blocked)
      end

      it 'rejects the blocked user without leaking a Workhorse Gitaly payload', :aggregate_failures do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.body).to eq('Your account has been blocked.')
        expect(response.body).not_to include('GL_ID')
        expect(response.media_type).not_to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end

    context 'with valid Shell JWT for a deactivated member' do
      let_it_be(:deactivated) { create(:user, :deactivated) }

      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{deactivated.id}" })
        )
      end

      before_all do
        project.add_developer(deactivated)
      end

      it 'rejects the deactivated user without leaking a Workhorse Gitaly payload', :aggregate_failures do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.body).to include('deactivated')
        expect(response.body).not_to include('GL_ID')
        expect(response.media_type).not_to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end

    context 'with invalid Shell JWT' do
      let(:headers) do
        workhorse_internal_api_request_header.merge(
          { Gitlab::Shell::API_HEADER => 'invalid-jwt' }
        )
      end

      it 'returns not found' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a validly-signed Shell JWT from the wrong issuer' do
      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(
            issuer: 'not-gitlab-shell',
            claims: { 'gl_id' => "user-#{user.id}" }
          )
        )
      end

      it 'returns not found' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with Shell JWT but no gl_id claim' do
      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header
        )
      end

      it 'returns not found' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with Shell JWT using deploy-token gl_id' do
      let_it_be(:deploy_token) { create(:deploy_token, :project, projects: [project]) }

      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "deploy-token-#{deploy_token.id}" })
        )
      end

      it 'rejects deploy tokens for SSH endpoints' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'without Shell JWT header' do
      let(:headers) { workhorse_internal_api_request_header }

      it 'returns not found' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /ssh-upload-pack' do
    subject(:make_request) { post "/#{path}/ssh-upload-pack", headers: headers }

    context 'with valid Shell JWT including gl_id' do
      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{user.id}" })
        )
      end

      it 'returns 200 with Workhorse Gitaly JSON', :aggregate_failures do
        expect(::Gitlab::GitAccessProject).to receive(:new).with(
          user,
          project,
          'ssh',
          hash_including(authentication_abilities: ::Gitlab::Auth.read_write_project_authentication_abilities)
        ).and_call_original

        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'GL_ID' => "user-#{user.id}",
          'GL_REPOSITORY' => "project-#{project.id}",
          'GL_USERNAME' => user.username
        )
        expect(json_response).to have_key('NeedAudit')
      end
    end

    context 'with Shell JWT via key-based gl_id' do
      let_it_be(:key) { create(:personal_key, user: user) }

      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "key-#{key.id}" })
        )
      end

      it 'resolves user from key and returns 200', :aggregate_failures do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['GL_ID']).to eq("user-#{user.id}")
        expect(json_response['GL_USERNAME']).to eq(user.username)
        expect(json_response).to have_key('NeedAudit')
      end
    end

    it_behaves_like 'a shell-authenticated SSH-over-HTTP endpoint rejecting unauthenticated requests'

    context 'when the enabled_git_access_protocol setting is ssh' do
      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{user.id}" })
        )
      end

      before do
        stub_application_setting(enabled_git_access_protocol: 'ssh')
      end

      it 'authorizes the SSH-over-HTTP request' do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the enabled_git_access_protocol setting is http' do
      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{user.id}" })
        )
      end

      before do
        stub_application_setting(enabled_git_access_protocol: 'http')
      end

      it 'rejects the SSH-over-HTTP request as an SSH protocol denial', :aggregate_failures do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.body).to eq('Git access over SSH is not allowed')
      end
    end

    context 'without Shell JWT header (only Workhorse header)' do
      let(:headers) { workhorse_internal_api_request_header }

      it 'returns not found for public and private projects', :aggregate_failures do
        post "/#{project.full_path}.git/ssh-upload-pack", headers: headers
        expect(response).to have_gitlab_http_status(:not_found)

        post "/#{public_project.full_path}.git/ssh-upload-pack", headers: headers
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /ssh-receive-pack' do
    subject(:make_request) { post "/#{path}/ssh-receive-pack", headers: headers }

    context 'with valid Shell JWT including gl_id' do
      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{user.id}" })
        )
      end

      it 'returns 200 with Workhorse Gitaly JSON', :aggregate_failures do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'GL_ID' => "user-#{user.id}",
          'GL_REPOSITORY' => "project-#{project.id}",
          'GL_USERNAME' => user.username
        )
        expect(json_response).to have_key('NeedAudit')
      end
    end

    context 'with valid Shell JWT for a read-only member' do
      let_it_be(:read_only_user) { create(:user) }

      let(:headers) do
        workhorse_internal_api_request_header.merge(
          gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{read_only_user.id}" })
        )
      end

      before_all do
        project.add_guest(read_only_user)
      end

      it 'denies the push through GitAccess', :aggregate_failures do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.body).to eq('You are not allowed to push code to this project.')
      end
    end

    it_behaves_like 'a shell-authenticated SSH-over-HTTP endpoint rejecting unauthenticated requests'
  end

  describe 'Shell JWT isolation from standard Git endpoints' do
    let(:headers) do
      workhorse_internal_api_request_header.merge(
        gitlab_shell_internal_api_request_header(claims: { 'gl_id' => "user-#{user.id}" })
      )
    end

    it 'does not authenticate POST /git-upload-pack with a Shell JWT' do
      post "/#{path}/git-upload-pack", headers: headers

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'does not authenticate POST /git-receive-pack with a Shell JWT' do
      post "/#{path}/git-receive-pack", headers: headers

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'does not authenticate GET /info/refs with a Shell JWT' do
      get "/#{path}/info/refs", params: { service: 'git-upload-pack' }, headers: headers

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
