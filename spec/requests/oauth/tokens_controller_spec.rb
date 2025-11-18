# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::TokensController, feature_category: :system_access do
  let_it_be(:organization) { create(:organization) }

  describe 'POST /oauth/token' do
    context 'with dynamic user scope', :aggregate_failures do
      def expect_token_info_appended_to_logs
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
            method.call(payload)

            expect(payload[:metadata]).to have_key(:oauth_access_token_id)
            expect(payload[:metadata][:oauth_access_token_application_id]).to eq(oauth_application.id)
            expect(payload[:metadata][:oauth_access_token_scopes]).to eq(scopes)
          end
        end
      end

      let_it_be(:user) { create(:user) }
      let_it_be(:scopes) { "api user:#{user.id}" }
      let_it_be(:oauth_application) { create(:oauth_application, owner: nil, scopes: "api user:*") }
      let_it_be(:oauth_access_grant) { create(:oauth_access_grant, scopes: scopes, application: oauth_application, redirect_uri: oauth_application.redirect_uri) }

      context 'when authorization code flow' do
        let_it_be(:grant_type) { 'authorization_code' }

        it 'returns an access token with the dynamic scopes' do
          expect_token_info_appended_to_logs

          post(
            '/oauth/token',
            params: {
              grant_type: grant_type,
              client_secret: oauth_application.secret,
              client_id: oauth_application.uid,
              redirect_uri: oauth_application.redirect_uri,
              code: oauth_access_grant.plaintext_token
            }
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.parsed_body['scope']).to eq scopes
        end
      end

      context 'when refresh token flow' do
        let_it_be(:grant_type) { 'refresh_token' }
        let_it_be(:oauth_token) { create(:oauth_access_token, application: oauth_application, scopes: scopes, use_refresh_token: true) }

        it 'returns an access token with the dynamic scopes' do
          expect_token_info_appended_to_logs

          post(
            '/oauth/token',
            params: {
              grant_type: grant_type,
              refresh_token: oauth_token.plaintext_refresh_token,
              client_secret: oauth_application.secret,
              client_id: oauth_application.uid,
              redirect_uri: oauth_application.redirect_uri,
              scopes: scopes # must be passed for refresh token to have correct scopes until https://github.com/doorkeeper-gem/doorkeeper/pull/1754 is merged
            }
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.parsed_body['scope']).to eq scopes
        end
      end
    end

    describe 'refresh token hash logging' do
      let_it_be(:user) { create(:user) }
      let_it_be(:oauth_application) { create(:oauth_application, owner: nil) }
      let_it_be(:oauth_token) { create(:oauth_access_token, application: oauth_application, use_refresh_token: true) }
      let(:refresh_token) { oauth_token.plaintext_refresh_token }

      def expect_refresh_token_hash_logged(expected_hash:)
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
            method.call(payload)

            if expected_hash
              expect(payload[:metadata]).to have_key(:refresh_token_hash)
              expect(payload[:metadata][:refresh_token_hash]).to eq(expected_hash)
            end
          end
        end
      end

      def expect_no_refresh_token_hash_logged
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
            method.call(payload)

            expect(payload[:metadata]).not_to have_key(:refresh_token_hash)
          end
        end
      end

      context 'when grant_type is refresh_token and refresh_token param is present' do
        it 'logs the first 10 characters of SHA256 hash of the refresh token' do
          expected_hash = Digest::SHA256.hexdigest(refresh_token)[0..9]
          expect_refresh_token_hash_logged(expected_hash: expected_hash)

          post(
            '/oauth/token',
            params: {
              grant_type: 'refresh_token',
              refresh_token: refresh_token,
              client_secret: oauth_application.secret,
              client_id: oauth_application.uid
            }
          )

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when grant_type is refresh_token but refresh_token param is missing' do
        it 'does not log refresh_token_hash' do
          expect_no_refresh_token_hash_logged

          post(
            '/oauth/token',
            params: {
              grant_type: 'refresh_token',
              client_secret: oauth_application.secret,
              client_id: oauth_application.uid
            }
          )

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when grant_type is refresh_token but refresh_token param is blank' do
        it 'does not log refresh_token_hash' do
          expect_no_refresh_token_hash_logged

          post(
            '/oauth/token',
            params: {
              grant_type: 'refresh_token',
              refresh_token: '',
              client_secret: oauth_application.secret,
              client_id: oauth_application.uid
            }
          )

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when grant_type is not refresh_token' do
        let_it_be(:oauth_access_grant) { create(:oauth_access_grant, application: oauth_application, redirect_uri: oauth_application.redirect_uri) }

        it 'does not log refresh_token_hash even if refresh_token param is present' do
          expect_no_refresh_token_hash_logged

          post(
            '/oauth/token',
            params: {
              grant_type: 'authorization_code',
              refresh_token: refresh_token, # This shouldn't be used for authorization_code flow
              client_secret: oauth_application.secret,
              client_id: oauth_application.uid,
              redirect_uri: oauth_application.redirect_uri,
              code: oauth_access_grant.plaintext_token
            }
          )

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'for resource owner password credential flow', :aggregate_failures do
      let_it_be(:password) { User.random_password }

      def authenticate(with_password)
        post '/oauth/token', params: { grant_type: 'password', username: user.username, password: with_password }
      end

      context 'when user does not have two factor enabled' do
        let_it_be(:user) { create(:user, password: password, organizations: [organization]) }

        it 'authenticates successfully' do
          expect(::Gitlab::Auth).to receive(:find_with_user_password).and_call_original

          authenticate(password)

          expect(response).to have_gitlab_http_status(:ok)
          expect(user.reload.failed_attempts).to eq(0)
        end

        it 'fails to authenticate and increments failed attempts when using the incorrect password' do
          authenticate('incorrect_password')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(user.reload.failed_attempts).to eq(1)
        end
      end

      context 'when the user has two factor enabled' do
        let_it_be(:user) { create(:user, :two_factor, password: password) }

        it 'fails to authenticate and does not call GitLab::Auth even when using the correct password' do
          expect(::Gitlab::Auth).not_to receive(:find_with_user_password)

          authenticate(password)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(user.reload.failed_attempts).to eq(0)
        end
      end

      context "when the user's password is automatically set" do
        let_it_be(:user) { create(:user, password_automatically_set: true) }

        it 'fails to authenticate and does not call GitLab::Auth even when using the correct password' do
          expect(::Gitlab::Auth).not_to receive(:find_with_user_password)

          authenticate(password)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(user.reload.failed_attempts).to eq(0)
        end

        context 'when the user has an identity matching a provider that is not password-based' do
          before do
            create(:identity, provider: 'google_oauth2', user: user)
          end

          it 'fails to authenticate and does not call GitLab::Auth' do
            expect(::Gitlab::Auth).not_to receive(:find_with_user_password)

            authenticate(password)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(user.reload.failed_attempts).to eq(0)
          end
        end

        context 'when the user is a password-based omniauth user' do
          before do
            create(:identity, provider: 'ldapmain', user: user)
          end

          it 'forwards the request to Gitlab::Auth' do
            expect(::Gitlab::Auth).to receive(:find_with_user_password)

            authenticate(password)
          end
        end
      end
    end

    describe 'PKCE validation for dynamic applications' do
      let_it_be(:user) { create(:user) }

      context 'with dynamic OAuth application' do
        let_it_be(:oauth_application) { create(:oauth_application, :dynamic) }
        let_it_be(:oauth_access_grant) do
          create(:oauth_access_grant,
            application: oauth_application,
            redirect_uri: oauth_application.redirect_uri,
            resource_owner_id: user.id)
        end

        let(:base_params) do
          {
            grant_type: 'authorization_code',
            client_id: oauth_application.uid,
            client_secret: oauth_application.secret,
            redirect_uri: oauth_application.redirect_uri,
            code: oauth_access_grant.plaintext_token
          }
        end

        context 'when code_verifier is missing' do
          it 'returns bad request with PKCE error' do
            post('/oauth/token', params: base_params)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.parsed_body).to eq({
              'error' => 'invalid_request',
              'error_description' => 'PKCE code_verifier is required for dynamic OAuth applications'
            })
          end
        end

        context 'when code_verifier is blank' do
          it 'returns bad request with PKCE error' do
            post('/oauth/token', params: base_params.merge(code_verifier: ''))

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.parsed_body).to eq({
              'error' => 'invalid_request',
              'error_description' => 'PKCE code_verifier is required for dynamic OAuth applications'
            })
          end
        end

        context 'when code_verifier is present' do
          it 'allows the request to proceed past PKCE validation' do
            post('/oauth/token', params: base_params.merge(code_verifier: 'valid_code_verifier'))

            expect(response.parsed_body['error']).not_to eq('invalid_request')
            expect(response.parsed_body['error_description']).not_to include('PKCE code_verifier is required')
          end
        end

        context 'when refreshing access tokens with refresh_token' do
          let_it_be(:dynamic_oauth_application) do
            create(:oauth_application, :dynamic, confidential: false, scopes: 'mcp')
          end

          let_it_be(:oauth_token) do
            create(
              :oauth_access_token,
              application: dynamic_oauth_application,
              resource_owner_id: user.id,
              use_refresh_token: true,
              scopes: 'mcp'
            )
          end

          it 'does not require PKCE code_verifier for refresh token flow' do
            post('/oauth/token', params: {
              grant_type: 'refresh_token',
              refresh_token: oauth_token.plaintext_refresh_token,
              client_id: dynamic_oauth_application.uid,
              scopes: 'mcp'
            })

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.parsed_body).to have_key('access_token')
            expect(response.parsed_body['error']).to be_nil
          end
        end
      end

      context 'with non-dynamic OAuth application' do
        let_it_be(:oauth_application) { create(:oauth_application) }
        let_it_be(:oauth_access_grant) do
          create(:oauth_access_grant,
            application: oauth_application,
            redirect_uri: oauth_application.redirect_uri,
            resource_owner_id: user.id)
        end

        let(:base_params) do
          {
            grant_type: 'authorization_code',
            client_id: oauth_application.uid,
            client_secret: oauth_application.secret,
            redirect_uri: oauth_application.redirect_uri,
            code: oauth_access_grant.plaintext_token
          }
        end

        context 'when code_verifier is missing' do
          it 'does not enforce PKCE validation' do
            post('/oauth/token', params: base_params)

            # Should not be rejected due to missing code_verifier
            expect(response.parsed_body['error']).not_to eq('invalid_request')

            if response.parsed_body['error_description']
              expect(
                response.parsed_body['error_description']
              ).not_to include('PKCE')
            end
          end
        end
      end

      context 'with application that is explicitly not dynamic' do
        let_it_be(:oauth_application) { create(:oauth_application, :without_owner) }
        let_it_be(:oauth_access_grant) do
          create(:oauth_access_grant,
            application: oauth_application,
            redirect_uri: oauth_application.redirect_uri,
            resource_owner_id: user.id)
        end

        let(:base_params) do
          {
            grant_type: 'authorization_code',
            client_id: oauth_application.uid,
            client_secret: oauth_application.secret,
            redirect_uri: oauth_application.redirect_uri,
            code: oauth_access_grant.token
          }
        end

        context 'when code_verifier is missing' do
          it 'does not enforce PKCE validation' do
            post('/oauth/token', params: base_params)

            expect(response.parsed_body['error']).not_to eq('invalid_request')

            if response.parsed_body['error_description']
              expect(response.parsed_body['error_description'])
                .not_to include('PKCE')
            end
          end
        end
      end
    end
  end

  context 'for CORS requests' do
    let(:cors_request_headers) { { 'Origin' => 'http://notgitlab.com' } }
    let(:other_headers) { {} }
    let(:headers) { cors_request_headers.merge(other_headers) }
    let(:allowed_methods) { 'POST, OPTIONS' }
    let(:authorization_methods) { %w[Authorization X-CSRF-Token X-Requested-With] }

    shared_examples 'cross-origin POST request' do
      it 'allows cross-origin requests' do
        expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
        expect(response.headers['Access-Control-Allow-Methods']).to eq allowed_methods
        expect(response.headers['Access-Control-Allow-Headers']).to be_nil
        expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
      end
    end

    shared_examples 'CORS preflight OPTIONS request' do
      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'allows cross-origin requests' do
        expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
        expect(response.headers['Access-Control-Allow-Methods']).to eq allowed_methods
        expect(response.headers['Access-Control-Allow-Credentials']).to be_nil

        expect(
          Array.wrap(response.headers['Access-Control-Allow-Headers']).join("\n")
        ).to eq authorization_methods.join("\n")
      end
    end

    describe 'POST /oauth/token' do
      before do
        post '/oauth/token', headers: headers
      end

      it_behaves_like 'cross-origin POST request'
    end

    describe 'OPTIONS /oauth/token' do
      let(:other_headers) { { 'Access-Control-Request-Headers' => authorization_methods, 'Access-Control-Request-Method' => 'POST' } }

      before do
        options '/oauth/token', headers: headers
      end

      it_behaves_like 'CORS preflight OPTIONS request'
    end

    describe 'POST /oauth/revoke' do
      let(:other_headers) { { 'Content-Type' => 'application/x-www-form-urlencoded' } }

      before do
        post '/oauth/revoke', headers: headers, params: { token: '12345' }
      end

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it_behaves_like 'cross-origin POST request'
    end

    describe 'OPTIONS /oauth/revoke' do
      let(:other_headers) { { 'Access-Control-Request-Headers' => authorization_methods, 'Access-Control-Request-Method' => 'POST' } }

      before do
        options '/oauth/revoke', headers: headers
      end

      it_behaves_like 'CORS preflight OPTIONS request'
    end
  end
end
