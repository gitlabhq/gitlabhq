# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OpenID Connect requests' do
  let(:user) do
    create(
      :user,
      name: 'Alice',
      username: 'alice',
      email: 'private@example.com',
      website_url: 'https://example.com',
      avatar: fixture_file_upload('spec/fixtures/dk.png')
    )
  end

  let(:access_grant) { create :oauth_access_grant, application: application, resource_owner_id: user.id }
  let(:access_token) { create :oauth_access_token, application: application, resource_owner_id: user.id }

  let(:hashed_subject) do
    Digest::SHA256.hexdigest("#{user.id}-#{Rails.application.secrets.secret_key_base}")
  end

  let(:id_token_claims) do
    {
      'sub'        => user.id.to_s,
      'sub_legacy' => hashed_subject
    }
  end

  let(:user_info_claims) do
    {
      'name'           => 'Alice',
      'nickname'       => 'alice',
      'email'          => 'public@example.com',
      'email_verified' => true,
      'website'        => 'https://example.com',
      'profile'        => 'http://localhost/alice',
      'picture'        => "http://localhost/uploads/-/system/user/avatar/#{user.id}/dk.png",
      'groups'         => kind_of(Array)
    }
  end

  let(:cors_request_headers) { { 'Origin' => 'http://notgitlab.com' } }

  def request_access_token!
    login_as user

    post '/oauth/token',
      params: {
        grant_type: 'authorization_code',
        code: access_grant.token,
        redirect_uri: application.redirect_uri,
        client_id: application.uid,
        client_secret: application.secret
      }
  end

  def request_user_info!
    get '/oauth/userinfo', params: {}, headers: { 'Authorization' => "Bearer #{access_token.token}" }
  end

  before do
    email = create(:email, :confirmed, email: 'public@example.com', user: user)
    user.update!(public_email: email.email)
  end

  context 'Application without OpenID scope' do
    let(:application) { create :oauth_application, scopes: 'api' }

    it 'token response does not include an ID token' do
      request_access_token!

      expect(json_response).to include 'access_token'
      expect(json_response).not_to include 'id_token'
    end

    it 'userinfo response is unauthorized' do
      request_user_info!

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(response.body).to be_blank
    end
  end

  shared_examples 'cross-origin GET request' do
    it 'allows cross-origin request' do
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, HEAD'
      expect(response.headers['Access-Control-Allow-Headers']).to be_nil
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end

  shared_examples 'cross-origin GET and POST request' do
    it 'allows cross-origin request' do
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, HEAD, POST'
      expect(response.headers['Access-Control-Allow-Headers']).to be_nil
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end

  context 'Application with OpenID scope' do
    let(:application) { create :oauth_application, scopes: 'openid' }

    it 'token response includes an ID token' do
      request_access_token!

      expect(json_response).to include 'id_token'
    end

    context 'UserInfo payload' do
      let!(:group1) { create :group }
      let!(:group2) { create :group }
      let!(:group3) { create :group, parent: group2 }
      let!(:group4) { create :group, parent: group3 }

      before do
        group1.add_user(user, GroupMember::OWNER)
        group3.add_user(user, Gitlab::Access::DEVELOPER)

        request_user_info!
      end

      it 'includes all user information and group memberships' do
        expect(json_response).to match(id_token_claims.merge(user_info_claims))

        expected_groups = [group1.full_path, group3.full_path]
        expected_groups << group4.full_path
        expect(json_response['groups']).to match_array(expected_groups)
      end

      it 'does not include any unknown claims' do
        expect(json_response.keys).to eq %w[sub sub_legacy] + user_info_claims.keys
      end

      it 'includes email and email_verified claims' do
        expect(json_response.keys).to include('email', 'email_verified')
      end

      it 'has public email in email claim' do
        expect(json_response['email']).to eq(user.public_email)
      end

      it 'has false in email_verified claim' do
        expect(json_response['email_verified']).to eq(true)
      end
    end

    context 'ID token payload' do
      before do
        request_access_token!
        @payload = JSON::JWT.decode(json_response['id_token'], :skip_verification)
      end

      it 'includes the subject claims' do
        expect(@payload).to match(a_hash_including(id_token_claims))
      end

      it 'includes the GitLab root URL' do
        expect(@payload['iss']).to eq Gitlab.config.gitlab.url
      end

      it 'includes the time of the last authentication', :clean_gitlab_redis_shared_state do
        expect(@payload['auth_time']).to eq user.current_sign_in_at.to_i
      end

      it 'has public email in email claim' do
        expect(@payload['email']).to eq(user.public_email)
      end

      it 'has true in email_verified claim' do
        expect(@payload['email_verified']).to eq(true)
      end

      it 'does not include any unknown properties' do
        expect(@payload.keys).to eq %w[iss sub aud exp iat auth_time sub_legacy email email_verified]
      end
    end

    context 'when user is blocked' do
      it 'redirects to login page' do
        access_grant
        user.block!

        request_access_token!

        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'when user is ldap_blocked' do
      it 'redirects to login page' do
        access_grant
        user.ldap_block!

        request_access_token!

        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'OpenID Discovery keys' do
      context 'with a cross-origin request' do
        before do
          get '/oauth/discovery/keys', headers: cors_request_headers
        end

        it 'returns data' do
          expect(response).to have_gitlab_http_status(:ok)
        end

        it_behaves_like 'cross-origin GET request'
      end

      context 'with a cross-origin preflight OPTIONS request' do
        before do
          options '/oauth/discovery/keys', headers: cors_request_headers
        end

        it_behaves_like 'cross-origin GET request'
      end
    end

    context 'OpenID WebFinger endpoint' do
      context 'with a cross-origin request' do
        before do
          get '/.well-known/webfinger', headers: cors_request_headers, params: { resource: 'user@example.com' }
        end

        it 'returns data' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['subject']).to eq('user@example.com')
        end

        it_behaves_like 'cross-origin GET request'
      end
    end

    context 'with a cross-origin preflight OPTIONS request' do
      before do
        options '/.well-known/webfinger', headers: cors_request_headers, params: { resource: 'user@example.com' }
      end

      it_behaves_like 'cross-origin GET request'
    end
  end

  context 'OpenID configuration information' do
    it 'correctly returns the configuration' do
      get '/.well-known/openid-configuration'

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['issuer']).to eq('http://localhost')
      expect(json_response['jwks_uri']).to eq('http://www.example.com/oauth/discovery/keys')
      expect(json_response['scopes_supported']).to eq(%w[api read_user read_api read_repository write_repository sudo openid profile email])
    end

    context 'with a cross-origin request' do
      before do
        get '/.well-known/openid-configuration', headers: cors_request_headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['issuer']).to eq('http://localhost')
        expect(json_response['jwks_uri']).to eq('http://www.example.com/oauth/discovery/keys')
        expect(json_response['scopes_supported']).to eq(%w[api read_user read_api read_repository write_repository sudo openid profile email])
      end

      it_behaves_like 'cross-origin GET request'
    end

    context 'with a cross-origin preflight OPTIONS request' do
      before do
        options '/.well-known/openid-configuration', headers: cors_request_headers
      end

      it_behaves_like 'cross-origin GET request'
    end
  end

  context 'Application with OpenID and email scopes' do
    let(:application) { create :oauth_application, scopes: 'openid email' }

    it 'token response includes an ID token' do
      request_access_token!

      expect(json_response).to include 'id_token'
    end

    context 'UserInfo payload' do
      before do
        request_user_info!
      end

      it 'includes the email and email_verified claims' do
        expect(json_response.keys).to include('email', 'email_verified')
      end

      it 'has private email in email claim' do
        expect(json_response['email']).to eq(user.email)
      end

      it 'has true in email_verified claim' do
        expect(json_response['email_verified']).to eq(true)
      end

      context 'with a cross-origin request' do
        before do
          get '/oauth/userinfo', headers: cors_request_headers
        end

        it_behaves_like 'cross-origin GET and POST request'
      end

      context 'with a cross-origin POST request' do
        before do
          post '/oauth/userinfo', headers: cors_request_headers
        end

        it_behaves_like 'cross-origin GET and POST request'
      end

      context 'with a cross-origin preflight OPTIONS request' do
        before do
          options '/oauth/userinfo', headers: cors_request_headers
        end

        it_behaves_like 'cross-origin GET and POST request'
      end
    end

    context 'ID token payload' do
      before do
        request_access_token!
        @payload = JSON::JWT.decode(json_response['id_token'], :skip_verification)
      end

      it 'has private email in email claim' do
        expect(@payload['email']).to eq(user.email)
      end

      it 'has true in email_verified claim' do
        expect(@payload['email_verified']).to eq(true)
      end
    end
  end
end
