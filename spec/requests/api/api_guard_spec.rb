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

    context 'with an insufficient scope' do
      let(:challenge) do
        'Bearer realm="Protected by OAuth 2.0", error="insufficient_scope", ' \
          'error_description="The request requires higher privileges than provided by the access token."'
      end

      it 'responds with a WWW-Authenticate challenge naming the scopes the body names', :aggregate_failures do
        app.get 'willfail' do
          raise Gitlab::Auth::InsufficientScopeError, [:api, :read_api]
        end

        get api('/willfail')

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['scope']).to eq('api read_api')
        expect(response.headers['WWW-Authenticate']).to eq(%(#{challenge}, scope="api read_api"))
      end

      it 'names no scope in the body or the challenge when no scope is listed', :aggregate_failures do
        app.get 'willfail' do
          raise Gitlab::Auth::InsufficientScopeError, []
        end

        get api('/willfail')

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).not_to have_key('scope')
        expect(response.headers['WWW-Authenticate']).to eq(challenge)
      end

      context 'when the endpoint refuses the token' do
        let_it_be(:token) { create(:personal_access_token, scopes: [:read_user]) }

        it 'names only the scopes whose condition holds for the request', :aggregate_failures do
          app.allow_access_with_scope :read_user, if: ->(request) { request.post? }
          app.get 'scoped' do
            authenticate!
          end

          get api('/scoped', personal_access_token: token)

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['scope']).to eq('api read_api')
          expect(response.headers['WWW-Authenticate']).to eq(%(#{challenge}, scope="api read_api"))
        end
      end
    end

    it 'does not add a WWW-Authenticate challenge to an insufficient_granular_scope error', :aggregate_failures do
      app.get 'willfail' do
        raise Gitlab::Auth::GranularPermissionsError, ['message']
      end

      get api('/willfail')

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(response.headers['WWW-Authenticate']).to be_nil
    end

    context 'when the endpoint has a challenge of its own' do
      before do
        app.helpers do
          def bearer_challenge(error:, error_description:, scope: nil)
            %(Bearer realm="Endpoint", error="#{error}", error_description="#{error_description}", ) +
              %(scope="#{scope || 'own'}")
          end

          def bearer_challenge_scopes(_scopes)
            [:own]
          end
        end
      end

      it 'answers an invalid_token error with it', :aggregate_failures do
        app.get 'willfail' do
          raise Gitlab::Auth::ExpiredError
        end

        get api('/willfail')

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['error']).to eq('invalid_token')
        expect(response.headers['WWW-Authenticate']).to eq(
          'Bearer realm="Endpoint", error="invalid_token", ' \
            'error_description="Token is expired. You can either do re-authorization or token refresh.", ' \
            'scope="own"'
        )
      end

      it 'answers an insufficient_scope error with it, naming its scopes in the body too', :aggregate_failures do
        app.get 'willfail' do
          raise Gitlab::Auth::InsufficientScopeError, [:api, :read_api]
        end

        get api('/willfail')

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['scope']).to eq('own')
        expect(response.headers['WWW-Authenticate']).to eq(
          'Bearer realm="Endpoint", error="insufficient_scope", ' \
            'error_description="The request requires higher privileges than provided by the access token.", ' \
            'scope="own"'
        )
      end

      it 'keeps the challenge of an error RFC 6750 does not define', :aggregate_failures do
        app.get 'willfail' do
          raise Gitlab::Auth::DpopValidationError, 'message'
        end

        get api('/willfail')

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to eq('Bearer realm="Protected by OAuth 2.0"')
      end

      it 'adds none to an insufficient_granular_scope error' do
        app.get 'willfail' do
          raise Gitlab::Auth::GranularPermissionsError, ['message']
        end

        get api('/willfail')

        expect(response.headers['WWW-Authenticate']).to be_nil
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
