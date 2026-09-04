# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Authn::Userinfo, feature_category: :system_access do
  include_context 'with IAM authentication setup'

  let_it_be(:user) { create(:user) }

  let(:path) { '/iam/userinfo' }
  let(:iam_scopes) { %w[read_api] }
  let(:iam_jwt_token) do
    create_iam_access_token(user: user, scopes: iam_scopes, issuer: iam_issuer, private_key: private_key, kid: kid)
  end

  def get_userinfo(token)
    headers = token ? { 'Authorization' => "Bearer #{token}" } : {}
    get api(path), headers: headers
  end

  describe 'GET /iam/userinfo' do
    context 'with a valid IAM OAuth JWT' do
      before do
        stub_feature_flags(iam_svc_oauth: user)
        get_userinfo(iam_jwt_token)
      end

      it 'returns the UserinfoClaimsBuilder output' do
        expected_claims = Authn::IamService::UserinfoClaimsBuilder.new(user).claims.transform_keys(&:to_s)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(expected_claims)
      end
    end

    context 'without an Authorization header' do
      before do
        get_userinfo(nil)
      end

      it 'returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a malformed bearer token' do
      before do
        stub_feature_flags(iam_svc_oauth: user)
        get_userinfo('not-a-jwt-at-all')
      end

      it 'returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a JWT that has an invalid signature' do
      before do
        stub_feature_flags(iam_svc_oauth: user)
        other_key = OpenSSL::PKey::RSA.new(2048)
        tampered_token = create_iam_access_token(
          user: user, scopes: iam_scopes, issuer: iam_issuer, private_key: other_key, kid: kid
        )

        get_userinfo(tampered_token)
      end

      it 'returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with an expired IAM JWT' do
      let(:iam_jwt_token) do
        create_iam_access_token(user: user, scopes: iam_scopes, issuer: iam_issuer, private_key: private_key, kid: kid,
          expires_at: 1.hour.ago)
      end

      before do
        stub_feature_flags(iam_svc_oauth: user)
        get_userinfo(iam_jwt_token)
      end

      it 'returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with the iam_svc_oauth feature flag enabled only for a different user' do
      before do
        stub_feature_flags(iam_svc_oauth: create(:user))
        get_userinfo(iam_jwt_token)
      end

      it 'returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with the iam_svc_oauth feature flag disabled for everyone' do
      before do
        stub_feature_flags(iam_svc_oauth: false)
        get_userinfo(iam_jwt_token)
      end

      it 'returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with an IAM JWT scoped to openid only' do
      let(:iam_scopes) { %w[openid] }

      before do
        stub_feature_flags(iam_svc_oauth: user)
        get_userinfo(iam_jwt_token)
      end

      it 'returns the UserinfoClaimsBuilder output' do
        expected_claims = Authn::IamService::UserinfoClaimsBuilder.new(user).claims.transform_keys(&:to_s)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(expected_claims)
      end
    end

    context 'with an IAM JWT that lacks a sufficient scope' do
      let(:iam_scopes) { [] }

      before do
        stub_feature_flags(iam_svc_oauth: user)
        get_userinfo(iam_jwt_token)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the user is blocked' do
      let_it_be(:user) { create(:user, :blocked) }

      before do
        stub_feature_flags(iam_svc_oauth: user)
        get_userinfo(iam_jwt_token)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with a Doorkeeper OAuth access token' do
      let_it_be(:application) { create(:oauth_application) }
      let_it_be(:doorkeeper_token) do
        # Sufficient api scope so this exercises the IamOauthToken type
        # filter specifically, rather than incidentally failing the
        # shared scope check applied to every Grape endpoint.
        create(:oauth_access_token, resource_owner: user, application: application, scopes: 'api')
      end

      before do
        get_userinfo(doorkeeper_token.plaintext_token)
      end

      it 'rejects the token and returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a personal access token' do
      let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

      before do
        get_userinfo(personal_access_token.token)
      end

      it 'rejects the token and returns 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
