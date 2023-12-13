# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::TokensController, feature_category: :system_access do
  describe 'POST /oauth/token' do
    context 'for resource owner password credential flow', :aggregate_failures do
      let_it_be(:password) { User.random_password }

      def authenticate(with_password)
        post '/oauth/token', params: { grant_type: 'password', username: user.username, password: with_password }
      end

      context 'when user does not have two factor enabled' do
        let_it_be(:user) { create(:user, password: password) }

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
        expect(response.headers['Access-Control-Allow-Headers']).to eq authorization_methods
        expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
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
