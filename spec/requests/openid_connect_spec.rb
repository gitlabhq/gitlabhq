require 'spec_helper'

describe 'OpenID Connect requests' do
  let(:user) do
    create(
      :user,
      name: 'Alice',
      username: 'alice',
      email: 'private@example.com',
      emails: [public_email],
      public_email: public_email.email,
      website_url: 'https://example.com',
      avatar: fixture_file_upload('spec/fixtures/dk.png')
    )
  end

  let(:public_email) { build :email, email: 'public@example.com' }

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
      'email_verified' => false,
      'website'        => 'https://example.com',
      'profile'        => 'http://localhost/alice',
      'picture'        => "http://localhost/uploads/-/system/user/avatar/#{user.id}/dk.png",
      'groups'         => kind_of(Array)
    }
  end

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

  context 'Application without OpenID scope' do
    let(:application) { create :oauth_application, scopes: 'api' }

    it 'token response does not include an ID token' do
      request_access_token!

      expect(json_response).to include 'access_token'
      expect(json_response).not_to include 'id_token'
    end

    it 'userinfo response is unauthorized' do
      request_user_info!

      expect(response).to have_gitlab_http_status 403
      expect(response.body).to be_blank
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
        expect(json_response['email_verified']).to eq(false)
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

      it 'does not include any unknown properties' do
        expect(@payload.keys).to eq %w[iss sub aud exp iat auth_time sub_legacy]
      end
    end

    # These 2 calls shouldn't actually throw, they should be handled as an
    # unauthorized request, so we should be able to check the response.
    #
    # This was not possible due to an issue with Warden:
    # https://github.com/hassox/warden/pull/162
    #
    # When the patch gets merged and we update Warden, these specs will need to
    # updated to check the response instead of a raised exception.
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/40218
    context 'when user is blocked' do
      it 'returns authentication error' do
        access_grant
        user.block!

        expect do
          request_access_token!
        end.to raise_error UncaughtThrowError
      end
    end

    context 'when user is ldap_blocked' do
      it 'returns authentication error' do
        access_grant
        user.ldap_block!

        expect do
          request_access_token!
        end.to raise_error UncaughtThrowError
      end
    end
  end

  context 'OpenID configuration information' do
    it 'correctly returns the configuration' do
      get '/.well-known/openid-configuration'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['issuer']).to eq('http://localhost')
      expect(json_response['jwks_uri']).to eq('http://www.example.com/oauth/discovery/keys')
      expect(json_response['scopes_supported']).to eq(%w[api read_user read_repository write_repository sudo openid profile email])
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
    end
  end
end
