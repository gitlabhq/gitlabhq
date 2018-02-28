require 'spec_helper'

describe 'OpenID Connect requests' do
  let(:user) { create :user }
  let(:access_grant) { create :oauth_access_grant, application: application, resource_owner_id: user.id }
  let(:access_token) { create :oauth_access_token, application: application, resource_owner_id: user.id }

  def request_access_token
    login_as user

    post '/oauth/token',
      grant_type: 'authorization_code',
      code: access_grant.token,
      redirect_uri: application.redirect_uri,
      client_id: application.uid,
      client_secret: application.secret
  end

  def request_user_info
    get '/oauth/userinfo', nil, 'Authorization' => "Bearer #{access_token.token}"
  end

  def hashed_subject
    Digest::SHA256.hexdigest("#{user.id}-#{Rails.application.secrets.secret_key_base}")
  end

  context 'Application without OpenID scope' do
    let(:application) { create :oauth_application, scopes: 'api' }

    it 'token response does not include an ID token' do
      request_access_token

      expect(json_response).to include 'access_token'
      expect(json_response).not_to include 'id_token'
    end

    it 'userinfo response is unauthorized' do
      request_user_info

      expect(response).to have_gitlab_http_status 403
      expect(response.body).to be_blank
    end
  end

  context 'Application with OpenID scope' do
    let(:application) { create :oauth_application, scopes: 'openid' }

    it 'token response includes an ID token' do
      request_access_token

      expect(json_response).to include 'id_token'
    end

    context 'UserInfo payload' do
      let(:user) do
        create(
          :user,
          name: 'Alice',
          username: 'alice',
          emails: [private_email, public_email],
          email: private_email.email,
          public_email: public_email.email,
          website_url: 'https://example.com',
          avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png")
        )
      end

      let!(:public_email) { build :email, email: 'public@example.com' }
      let!(:private_email) { build :email, email: 'private@example.com' }

      let!(:group1) { create :group }
      let!(:group2) { create :group }
      let!(:group3) { create :group, parent: group2 }
      let!(:group4) { create :group, parent: group3 }

      before do
        group1.add_user(user, GroupMember::OWNER)
        group3.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it 'includes all user information and group memberships' do
        request_user_info

        expect(json_response).to match(a_hash_including({
          'sub'            => hashed_subject,
          'name'           => 'Alice',
          'nickname'       => 'alice',
          'email'          => 'public@example.com',
          'email_verified' => true,
          'website'        => 'https://example.com',
          'profile'        => 'http://localhost/alice',
          'picture'        => "http://localhost/uploads/-/system/user/avatar/#{user.id}/dk.png",
          'groups'         => anything
        }))

        expected_groups = [group1.full_path, group3.full_path]
        expected_groups << group4.full_path if Group.supports_nested_groups?
        expect(json_response['groups']).to match_array(expected_groups)
      end
    end

    context 'ID token payload' do
      before do
        request_access_token
        @payload = JSON::JWT.decode(json_response['id_token'], :skip_verification)
      end

      it 'includes the Gitlab root URL' do
        expect(@payload['iss']).to eq Gitlab.config.gitlab.url
      end

      it 'includes the hashed user ID' do
        expect(@payload['sub']).to eq hashed_subject
      end

      it 'includes the time of the last authentication', :clean_gitlab_redis_shared_state do
        expect(@payload['auth_time']).to eq user.current_sign_in_at.to_i
      end

      it 'does not include any unknown properties' do
        expect(@payload.keys).to eq %w[iss sub aud exp iat auth_time]
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
        user.block

        expect do
          request_access_token
        end.to raise_error UncaughtThrowError
      end
    end

    context 'when user is ldap_blocked' do
      it 'returns authentication error' do
        access_grant
        user.ldap_block

        expect do
          request_access_token
        end.to raise_error UncaughtThrowError
      end
    end
  end
end
