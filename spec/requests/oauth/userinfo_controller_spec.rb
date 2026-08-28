# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::UserinfoController, feature_category: :system_access do
  include_context 'with IAM authentication setup'

  let_it_be_with_reload(:user) { create(:user) }

  let(:scopes) { %w[openid] }
  let(:iam_jwt) do
    create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid, scopes: scopes)
  end

  def get_userinfo(token)
    get '/oauth/userinfo', headers: { 'Authorization' => "Bearer #{token}" }
  end

  describe 'GET /oauth/userinfo' do
    context 'with an IAM-issued JWT' do
      it 'returns the user claims', :aggregate_failures do
        get_userinfo(iam_jwt)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['sub']).to eq(user.id.to_s)
      end

      it 'returns the same response as a Doorkeeper-issued token', :aggregate_failures do
        get_userinfo(iam_jwt)
        iam_response = json_response

        access_token = create(:oauth_access_token, resource_owner_id: user.id, scopes: 'openid')
        get_userinfo(access_token.plaintext_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(iam_response).to eq(json_response)
      end

      context 'when the token does not include the openid scope' do
        let(:scopes) { %w[api] }

        it 'returns forbidden' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when the token is expired' do
        let(:iam_jwt) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid,
            scopes: scopes, expires_at: 1.hour.ago)
        end

        it 'returns unauthorized' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when the user is blocked' do
        before do
          user.block!
        end

        it 'returns unauthorized' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when the iam_svc_oauth feature flag is disabled' do
        before do
          stub_feature_flags(iam_svc_oauth: false)
        end

        it 'returns unauthorized' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when the IAM service is disabled' do
        before do
          allow(Authn::IamAuthService).to receive(:enabled?).and_return(false)
        end

        it 'returns unauthorized' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'runs IAM JWT validation only once' do
          expect(Authn::Tokens::IamOauthToken).to receive(:from_jwt).once.and_call_original

          get_userinfo(iam_jwt)
        end
      end

      context 'with a malformed JWT' do
        it 'returns unauthorized' do
          get_userinfo('invalid.jwt.token')

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'with a wrong audience claim' do
        let(:iam_jwt) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid,
            scopes: scopes, aud: 'wrong-audience')
        end

        it 'returns unauthorized' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when the JWKS endpoint times out' do
        let(:iam_jwt) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: 'timeout_kid',
            scopes: scopes)
        end

        before do
          Rails.cache.delete("iam:jwks:#{iam_issuer}")
          stub_request(:get, "#{iam_issuer}/.well-known/jwks.json").to_timeout
        end

        it 'returns unauthorized' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when the JWKS service is unavailable' do
        let(:iam_jwt) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: 'unavailable_kid',
            scopes: scopes)
        end

        before do
          Rails.cache.delete("iam:jwks:#{iam_issuer}")
          stub_request(:get, "#{iam_issuer}/.well-known/jwks.json")
            .to_return(status: 503, body: 'Service Unavailable')
        end

        it 'returns unauthorized' do
          get_userinfo(iam_jwt)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'with a Doorkeeper-issued token' do
      it 'returns the user claims', :aggregate_failures do
        access_token = create(:oauth_access_token, resource_owner_id: user.id, scopes: 'openid')

        get_userinfo(access_token.plaintext_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['sub']).to eq(user.id.to_s)
      end
    end

    context 'without a token' do
      it 'returns unauthorized' do
        get '/oauth/userinfo'

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
