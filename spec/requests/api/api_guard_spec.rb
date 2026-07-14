# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::APIGuard, feature_category: :system_access do
  context 'when an AuthenticationError exception is raised in the API call' do
    let(:app) do
      Class.new(API::API)
    end

    [
      [Gitlab::Auth::MissingTokenError, :unauthorized, 'unauthorized'],
      [Gitlab::Auth::TokenNotFoundError, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::ExpiredError, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::RevokedError, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::ImpersonationDisabled, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::InsufficientScopeError, :forbidden, 'insufficient_scope'],
      [Gitlab::Auth::RestrictedLanguageServerClientError, :unauthorized, 'restricted_language_server_client_error'],
      [Gitlab::Auth::DpopValidationError, :unauthorized, 'dpop_error'],
      [Gitlab::Auth::GranularPermissionsError, :forbidden, 'insufficient_granular_scope']
    ].each do |exception_class, status, error|
      it "catches #{exception_class} and responds with #{status} status and an #{error} error" do
        app.get 'willfail' do
          raise exception_class, ['message']
        end

        get api('/willfail')

        expect(response).to have_gitlab_http_status(status)
        expect(json_response['error']).to eq(error)
      end
    end
  end

  describe '#find_user_from_sources' do
    let_it_be(:user) { create(:user) }
    let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
    let_it_be(:oauth_token) { create(:oauth_access_token, resource_owner_id: user.id, scopes: [:api]) }

    context 'on the default branch (endpoint does not call authenticate_with)' do
      let_it_be(:deploy_token) { create(:deploy_token, read_repository: true) }
      let_it_be(:ci_build) { create(:ci_build, :running, user: user) }

      let(:app) do
        Class.new(API::API) do
          route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true

          get 'whoami' do
            authenticate!

            { id: current_user.id }
          end
        end
      end

      it 'authenticates via find_user_from_bearer_token with a personal access token', :aggregate_failures do
        get api('/whoami', personal_access_token: personal_access_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
      end

      it 'authenticates via find_user_from_bearer_token with an OAuth token', :aggregate_failures do
        get api('/whoami', oauth_access_token: oauth_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
      end

      it 'authenticates via find_user_from_job_token with a job token', :aggregate_failures do
        get api('/whoami', job_token: ci_build.token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
      end

      it 'resolves a deploy token via deploy_token_from_request', :aggregate_failures do
        get api('/whoami'), headers: { 'Deploy-Token' => deploy_token.token }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(deploy_token.id)
      end

      # With no token, the chain falls through to user_from_warden, which yields no user here.
      # The positive warden/session path (find_user_from_warden returning a user) is covered by
      # spec/requests/api/helpers_spec.rb; it cannot be exercised here because these throwaway
      # endpoints are served directly by Rack::Test and bypass the warden session middleware.
      it 'returns unauthorized when no credentials resolve a user' do
        get api('/whoami')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'on the namespace-inheritable branch (endpoint calls authenticate_with)' do
      let(:app) do
        Class.new(API::API) do
          include ::API::Helpers::Authentication

          authenticate_with do |allow|
            allow.token_types(:personal_access_token).sent_through(:http_private_token_header)
          end

          get 'whoami' do
            authenticate!

            { id: current_user.id }
          end
        end
      end

      it 'authenticates via user_from_namespace_inheritable for a registered strategy', :aggregate_failures do
        get api('/whoami'), headers: { 'Private-Token' => personal_access_token.token }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
      end

      it 'ignores a credential supplied in an unregistered location' do
        # The same OAuth token authenticates on the default branch; here it must be ignored
        # because the credential is not in a registered location.
        get api('/whoami', oauth_access_token: oauth_token)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'rejects a non-PAT credential supplied in the registered location' do
        get api('/whoami'), headers: { 'Private-Token' => oauth_token.plaintext_token }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
