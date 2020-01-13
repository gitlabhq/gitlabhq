# frozen_string_literal: true

require 'spec_helper'

describe API::Users do
  let(:user)  { create(:user, username: 'user.with.dot') }
  let(:admin) { create(:admin) }
  let(:key) { create(:key, user: user) }
  let(:gpg_key) { create(:gpg_key, user: user) }
  let(:email) { create(:email, user: user) }
  let(:omniauth_user) { create(:omniauth_user) }
  let(:ldap_user) { create(:omniauth_user, provider: 'ldapmain') }
  let(:ldap_blocked_user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }
  let(:not_existing_user_id) { (User.maximum('id') || 0 ) + 10 }
  let(:not_existing_pat_id) { (PersonalAccessToken.maximum('id') || 0 ) + 10 }
  let(:private_user) { create(:user, private_profile: true) }

  shared_examples 'rendering user status' do
    it 'returns the status if there was one' do
      create(:user_status, user: user)

      get api(path, user)

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response['message']).to be_present
      expect(json_response['message_html']).to be_present
      expect(json_response['emoji']).to be_present
    end

    it 'returns an empty response if there was no status' do
      get api(path, user)

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response['message']).to be_nil
      expect(json_response['emoji']).to be_nil
    end
  end

  describe 'GET /users' do
    context "when unauthenticated" do
      it "returns authorization error when the `username` parameter is not passed" do
        get api("/users")

        expect(response).to have_gitlab_http_status(403)
      end

      it "returns the user when a valid `username` parameter is passed" do
        get api("/users"), params: { username: user.username }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.size).to eq(1)
        expect(json_response[0]['id']).to eq(user.id)
        expect(json_response[0]['username']).to eq(user.username)
      end

      it "returns the user when a valid `username` parameter is passed (case insensitive)" do
        get api("/users"), params: { username: user.username.upcase }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.size).to eq(1)
        expect(json_response[0]['id']).to eq(user.id)
        expect(json_response[0]['username']).to eq(user.username)
      end

      it "returns an empty response when an invalid `username` parameter is passed" do
        get api("/users"), params: { username: 'invalid' }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(0)
      end

      it "does not return the highest role" do
        get api("/users"), params: { username: user.username }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'highest_role'
      end

      context "when public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it "returns authorization error when the `username` parameter refers to an inaccessible user" do
          get api("/users"), params: { username: user.username }

          expect(response).to have_gitlab_http_status(403)
        end

        it "returns authorization error when the `username` parameter is not passed" do
          get api("/users")

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context "when authenticated" do
      # These specs are written just in case API authentication is not required anymore
      context "when public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        context 'when authenticate as a regular user' do
          it "renders 200" do
            get api("/users", user)

            expect(response).to match_response_schema('public_api/v4/user/basics')
          end
        end

        context 'when authenticate as an admin' do
          it "renders 200" do
            get api("/users", admin)

            expect(response).to match_response_schema('public_api/v4/user/basics')
          end
        end
      end

      it "returns an array of users" do
        get api("/users", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        username = user.username
        expect(json_response.detect do |user|
          user['username'] == username
        end['username']).to eq(username)
      end

      it "returns an array of blocked users" do
        ldap_blocked_user
        create(:user, state: 'blocked')

        get api("/users?blocked=true", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response).to all(include('state' => /(blocked|ldap_blocked)/))
      end

      it "returns one user" do
        get api("/users?username=#{omniauth_user.username}", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.first['username']).to eq(omniauth_user.username)
      end

      it "returns one user (case insensitive)" do
        get api("/users?username=#{omniauth_user.username.upcase}", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.first['username']).to eq(omniauth_user.username)
      end

      it "returns a 403 when non-admin user searches by external UID" do
        get api("/users?extern_uid=#{omniauth_user.identities.first.extern_uid}&provider=#{omniauth_user.identities.first.provider}", user)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'does not reveal the `is_admin` flag of the user' do
        get api('/users', user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'is_admin'
      end
    end

    context "when admin" do
      context 'when sudo is defined' do
        it 'does not return 500' do
          admin_personal_access_token = create(:personal_access_token, user: admin, scopes: [:sudo])
          get api("/users?sudo=#{user.id}", admin, personal_access_token: admin_personal_access_token)

          expect(response).to have_gitlab_http_status(:success)
        end
      end

      it "returns an array of users" do
        get api("/users", admin)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(response).to include_pagination_headers
      end

      it "returns an array of external users" do
        create(:user, external: true)

        get api("/users?external=true", admin)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(response).to include_pagination_headers
        expect(json_response).to all(include('external' => true))
      end

      it "returns one user by external UID" do
        get api("/users?extern_uid=#{omniauth_user.identities.first.extern_uid}&provider=#{omniauth_user.identities.first.provider}", admin)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['username']).to eq(omniauth_user.username)
      end

      it "returns 400 error if provider with no extern_uid" do
        get api("/users?extern_uid=#{omniauth_user.identities.first.extern_uid}", admin)

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 error if provider with no extern_uid" do
        get api("/users?provider=#{omniauth_user.identities.first.provider}", admin)

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns a user created before a specific date" do
        user = create(:user, created_at: Date.new(2000, 1, 1))

        get api("/users?created_before=2000-01-02T00:00:00.060Z", admin)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['username']).to eq(user.username)
      end

      it "returns no users created before a specific date" do
        create(:user, created_at: Date.new(2001, 1, 1))

        get api("/users?created_before=2000-01-02T00:00:00.060Z", admin)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(0)
      end

      it "returns users created before and after a specific date" do
        user = create(:user, created_at: Date.new(2001, 1, 1))

        get api("/users?created_before=2001-01-02T00:00:00.060Z&created_after=1999-01-02T00:00:00.060", admin)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['username']).to eq(user.username)
      end

      it 'returns the correct order when sorted by id' do
        admin
        user

        get api('/users', admin), params: { order_by: 'id', sort: 'asc' }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(2)
        expect(json_response.first['id']).to eq(admin.id)
        expect(json_response.last['id']).to eq(user.id)
      end

      it 'returns users with 2fa enabled' do
        admin
        user
        user_with_2fa = create(:user, :two_factor_via_otp)

        get api('/users', admin), params: { two_factor: 'enabled' }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(user_with_2fa.id)
      end

      it 'returns 400 when provided incorrect sort params' do
        get api('/users', admin), params: { order_by: 'magic', sort: 'asc' }

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context "when authenticated and ldap is enabled" do
      it "returns non-ldap user" do
        create :omniauth_user, provider: "ldapserver1"

        get api("/users", user), params: { skip_ldap: "true" }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first["username"]).to eq user.username
      end
    end
  end

  describe "GET /users/:id" do
    it "returns a user by id" do
      get api("/users/#{user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response['username']).to eq(user.username)
    end

    it "does not return the user's `is_admin` flag" do
      get api("/users/#{user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'is_admin'
    end

    it "does not return the user's `highest_role`" do
      get api("/users/#{user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'highest_role'
    end

    context 'when authenticated as admin' do
      it 'includes the `is_admin` field' do
        get api("/users/#{user.id}", admin)

        expect(response).to match_response_schema('public_api/v4/user/admin')
        expect(json_response['is_admin']).to be(false)
      end

      it "includes the `created_at` field for private users" do
        get api("/users/#{private_user.id}", admin)

        expect(response).to match_response_schema('public_api/v4/user/admin')
        expect(json_response.keys).to include 'created_at'
      end
      it 'includes the `highest_role` field' do
        get api("/users/#{user.id}", admin)

        expect(response).to match_response_schema('public_api/v4/user/admin')
        expect(json_response['highest_role']).to be(0)
      end
    end

    context 'for an anonymous user' do
      it "returns a user by id" do
        get api("/users/#{user.id}")

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response['username']).to eq(user.username)
      end

      it "returns a 404 if the target user is present but inaccessible" do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(nil, :read_user, user).and_return(false)

        get api("/users/#{user.id}")

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns the `created_at` field for public users" do
        get api("/users/#{user.id}")

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response.keys).to include 'created_at'
      end

      it "does not return the `created_at` field for private users" do
        get api("/users/#{private_user.id}")

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response.keys).not_to include 'created_at'
      end
    end

    it "returns a 404 error if user id not found" do
      get api("/users/0", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      get api("/users/1ASDF", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /users/:id_or_username/status' do
    context 'when finding the user by id' do
      it_behaves_like 'rendering user status' do
        let(:path) { "/users/#{user.id}/status" }
      end
    end

    context 'when finding the user by username' do
      it_behaves_like 'rendering user status' do
        let(:path) { "/users/#{user.username}/status" }
      end
    end

    context 'when finding the user by username (case insensitive)' do
      it_behaves_like 'rendering user status' do
        let(:path) { "/users/#{user.username.upcase}/status" }
      end
    end
  end

  describe "POST /users" do
    before do
      admin
    end

    it "creates user" do
      expect do
        post api("/users", admin), params: attributes_for(:user, projects_limit: 3)
      end.to change { User.count }.by(1)
    end

    it "creates user with correct attributes" do
      post api('/users', admin), params: attributes_for(:user, admin: true, can_create_group: true)
      expect(response).to have_gitlab_http_status(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(true)
      expect(new_user.can_create_group).to eq(true)
    end

    it "creates user with optional attributes" do
      optional_attributes = { confirm: true }
      attributes = attributes_for(:user).merge(optional_attributes)

      post api('/users', admin), params: attributes

      expect(response).to have_gitlab_http_status(201)
    end

    it "creates non-admin user" do
      post api('/users', admin), params: attributes_for(:user, admin: false, can_create_group: false)
      expect(response).to have_gitlab_http_status(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(false)
      expect(new_user.can_create_group).to eq(false)
    end

    it "creates non-admin users by default" do
      post api('/users', admin), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(false)
    end

    it "returns 201 Created on success" do
      post api("/users", admin), params: attributes_for(:user, projects_limit: 3)
      expect(response).to match_response_schema('public_api/v4/user/admin')
      expect(response).to have_gitlab_http_status(201)
    end

    it 'creates non-external users by default' do
      post api("/users", admin), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.external).to be_falsy
    end

    it 'allows an external user to be created' do
      post api("/users", admin), params: attributes_for(:user, external: true)
      expect(response).to have_gitlab_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.external).to be_truthy
    end

    it "creates user with reset password" do
      post api('/users', admin), params: attributes_for(:user, reset_password: true).except(:password)

      expect(response).to have_gitlab_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user.recently_sent_password_reset?).to eq(true)
    end

    it "creates user with random password" do
      params = attributes_for(:user, force_random_password: true, reset_password: true)
      post api('/users', admin), params: params

      expect(response).to have_gitlab_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user.valid_password?(params[:password])).to eq(false)
      expect(new_user.recently_sent_password_reset?).to eq(true)
    end

    it "creates user with private profile" do
      post api('/users', admin), params: attributes_for(:user, private_profile: true)

      expect(response).to have_gitlab_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user).not_to eq(nil)
      expect(new_user.private_profile?).to eq(true)
    end

    it "does not create user with invalid email" do
      post api('/users', admin),
           params: {
             email: 'invalid email',
             password: 'password',
             name: 'test'
           }
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 error if name not given' do
      post api('/users', admin), params: attributes_for(:user).except(:name)
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 error if password not given' do
      post api('/users', admin), params: attributes_for(:user).except(:password)
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 error if email not given' do
      post api('/users', admin), params: attributes_for(:user).except(:email)
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 error if username not given' do
      post api('/users', admin), params: attributes_for(:user).except(:username)
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 error if user does not validate' do
      post api('/users', admin),
           params: {
             password: 'pass',
             email: 'test@example.com',
             username: 'test!',
             name: 'test',
             bio: 'g' * 256,
             projects_limit: -1
           }
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['password'])
        .to eq(['is too short (minimum is 8 characters)'])
      expect(json_response['message']['bio'])
        .to eq(['is too long (maximum is 255 characters)'])
      expect(json_response['message']['projects_limit'])
        .to eq(['must be greater than or equal to 0'])
      expect(json_response['message']['username'])
        .to eq([Gitlab::PathRegex.namespace_format_message])
    end

    it "is not available for non admin users" do
      post api("/users", user), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(403)
    end

    context 'with existing user' do
      before do
        post api('/users', admin),
             params: {
               email: 'test@example.com',
               password: 'password',
               username: 'test',
               name: 'foo'
             }
      end

      it 'returns 409 conflict error if user with same email exists' do
        expect do
          post api('/users', admin),
               params: {
                 name: 'foo',
                 email: 'test@example.com',
                 password: 'password',
                 username: 'foo'
               }
        end.to change { User.count }.by(0)
        expect(response).to have_gitlab_http_status(409)
        expect(json_response['message']).to eq('Email has already been taken')
      end

      it 'returns 409 conflict error if same username exists' do
        expect do
          post api('/users', admin),
               params: {
                 name: 'foo',
                 email: 'foo@example.com',
                 password: 'password',
                 username: 'test'
               }
        end.to change { User.count }.by(0)
        expect(response).to have_gitlab_http_status(409)
        expect(json_response['message']).to eq('Username has already been taken')
      end

      it 'returns 409 conflict error if same username exists (case insensitive)' do
        expect do
          post api('/users', admin),
               params: {
                 name: 'foo',
                 email: 'foo@example.com',
                 password: 'password',
                 username: 'TEST'
               }
        end.to change { User.count }.by(0)
        expect(response).to have_gitlab_http_status(409)
        expect(json_response['message']).to eq('Username has already been taken')
      end

      it 'creates user with new identity' do
        post api("/users", admin), params: attributes_for(:user, provider: 'github', extern_uid: '67890')

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['identities'].first['extern_uid']).to eq('67890')
        expect(json_response['identities'].first['provider']).to eq('github')
      end
    end

    context "scopes" do
      let(:user) { admin }
      let(:path) { '/users' }
      let(:api_call) { method(:api) }

      include_examples 'does not allow the "read_user" scope'
    end
  end

  describe "PUT /users/:id" do
    let!(:admin_user) { create(:admin) }

    it "returns 200 OK on success" do
      put api("/users/#{user.id}", admin), params: { bio: 'new test bio' }

      expect(response).to match_response_schema('public_api/v4/user/admin')
      expect(response).to have_gitlab_http_status(200)
    end

    context 'updating name' do
      context 'when the ability to update their name is disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: true)
        end

        it 'updates the user with new name' do
          put api("/users/#{user.id}", admin), params: { name: 'New Name' }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['name']).to eq('New Name')
        end
      end
    end

    it "updates user with new bio" do
      put api("/users/#{user.id}", admin), params: { bio: 'new test bio' }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['bio']).to eq('new test bio')
      expect(user.reload.bio).to eq('new test bio')
    end

    it "updates user with new password and forces reset on next login" do
      put api("/users/#{user.id}", admin), params: { password: '12345678' }

      expect(response).to have_gitlab_http_status(200)
      expect(user.reload.password_expires_at).to be <= Time.now
    end

    it "updates user with organization" do
      put api("/users/#{user.id}", admin), params: { organization: 'GitLab' }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['organization']).to eq('GitLab')
      expect(user.reload.organization).to eq('GitLab')
    end

    it 'updates user with avatar' do
      put api("/users/#{user.id}", admin), params: { avatar: fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }

      user.reload

      expect(user.avatar).to be_present
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['avatar_url']).to include(user.avatar_path)
    end

    it 'updates user with a new email' do
      old_email = user.email
      old_notification_email = user.notification_email
      put api("/users/#{user.id}", admin), params: { email: 'new@email.com' }

      user.reload

      expect(response).to have_gitlab_http_status(200)
      expect(user).to be_confirmed
      expect(user.email).to eq(old_email)
      expect(user.notification_email).to eq(old_notification_email)
      expect(user.unconfirmed_email).to eq('new@email.com')
    end

    it 'skips reconfirmation when requested' do
      put api("/users/#{user.id}", admin), params: { email: 'new@email.com', skip_reconfirmation: true }

      user.reload

      expect(response).to have_gitlab_http_status(200)
      expect(user).to be_confirmed
      expect(user.email).to eq('new@email.com')
    end

    it 'updates user with his own username' do
      put api("/users/#{user.id}", admin), params: { username: user.username }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['username']).to eq(user.username)
      expect(user.reload.username).to eq(user.username)
    end

    it "updates user's existing identity" do
      put api("/users/#{omniauth_user.id}", admin), params: { provider: 'ldapmain', extern_uid: '654321' }

      expect(response).to have_gitlab_http_status(200)
      expect(omniauth_user.reload.identities.first.extern_uid).to eq('654321')
    end

    it 'updates user with new identity' do
      put api("/users/#{user.id}", admin), params: { provider: 'github', extern_uid: 'john' }

      expect(response).to have_gitlab_http_status(200)
      expect(user.reload.identities.first.extern_uid).to eq('john')
      expect(user.reload.identities.first.provider).to eq('github')
    end

    it "updates admin status" do
      put api("/users/#{user.id}", admin), params: { admin: true }

      expect(response).to have_gitlab_http_status(200)
      expect(user.reload.admin).to eq(true)
    end

    it "updates external status" do
      put api("/users/#{user.id}", admin), params: { external: true }

      expect(response.status).to eq 200
      expect(json_response['external']).to eq(true)
      expect(user.reload.external?).to be_truthy
    end

    it "updates private profile" do
      put api("/users/#{user.id}", admin), params: { private_profile: true }

      expect(response).to have_gitlab_http_status(200)
      expect(user.reload.private_profile).to eq(true)
    end

    it "updates private profile when nil is given to false" do
      admin.update(private_profile: true)

      put api("/users/#{user.id}", admin), params: { private_profile: nil }

      expect(user.reload.private_profile).to eq(false)
    end

    it "does not update admin status" do
      put api("/users/#{admin_user.id}", admin), params: { can_create_group: false }

      expect(response).to have_gitlab_http_status(200)
      expect(admin_user.reload.admin).to eq(true)
      expect(admin_user.can_create_group).to eq(false)
    end

    it "does not allow invalid update" do
      put api("/users/#{user.id}", admin), params: { email: 'invalid email' }

      expect(response).to have_gitlab_http_status(400)
      expect(user.reload.email).not_to eq('invalid email')
    end

    context 'when the current user is not an admin' do
      it "is not available" do
        expect do
          put api("/users/#{user.id}", user), params: attributes_for(:user)
        end.not_to change { user.reload.attributes }

        expect(response).to have_gitlab_http_status(403)
      end
    end

    it "returns 404 for non-existing user" do
      put api("/users/0", admin), params: { bio: 'update should fail' }

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 if invalid ID" do
      put api("/users/ASDF", admin)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 400 error if user does not validate' do
      put api("/users/#{user.id}", admin),
          params: {
            password: 'pass',
            email: 'test@example.com',
            username: 'test!',
            name: 'test',
            bio: 'g' * 256,
            projects_limit: -1
          }
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['password'])
        .to eq(['is too short (minimum is 8 characters)'])
      expect(json_response['message']['bio'])
        .to eq(['is too long (maximum is 255 characters)'])
      expect(json_response['message']['projects_limit'])
        .to eq(['must be greater than or equal to 0'])
      expect(json_response['message']['username'])
        .to eq([Gitlab::PathRegex.namespace_format_message])
    end

    it 'returns 400 if provider is missing for identity update' do
      put api("/users/#{omniauth_user.id}", admin), params: { extern_uid: '654321' }

      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 if external UID is missing for identity update' do
      put api("/users/#{omniauth_user.id}", admin), params: { provider: 'ldap' }

      expect(response).to have_gitlab_http_status(400)
    end

    context "with existing user" do
      before do
        post api("/users", admin), params: { email: 'test@example.com', password: 'password', username: 'test', name: 'test' }
        post api("/users", admin), params: { email: 'foo@bar.com', password: 'password', username: 'john', name: 'john' }
        @user = User.all.last
      end

      it 'returns 409 conflict error if email address exists' do
        put api("/users/#{@user.id}", admin), params: { email: 'test@example.com' }

        expect(response).to have_gitlab_http_status(409)
        expect(@user.reload.email).to eq(@user.email)
      end

      it 'returns 409 conflict error if username taken' do
        @user_id = User.all.last.id
        put api("/users/#{@user.id}", admin), params: { username: 'test' }

        expect(response).to have_gitlab_http_status(409)
        expect(@user.reload.username).to eq(@user.username)
      end

      it 'returns 409 conflict error if username taken (case insensitive)' do
        @user_id = User.all.last.id
        put api("/users/#{@user.id}", admin), params: { username: 'TEST' }

        expect(response).to have_gitlab_http_status(409)
        expect(@user.reload.username).to eq(@user.username)
      end
    end
  end

  describe "POST /users/:id/keys" do
    before do
      admin
    end

    it "does not create invalid ssh key" do
      post api("/users/#{user.id}/keys", admin), params: { title: "invalid key" }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create key without title' do
      post api("/users/#{user.id}/keys", admin), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('title is missing')
    end

    it "creates ssh key" do
      key_attrs = attributes_for :key
      expect do
        post api("/users/#{user.id}/keys", admin), params: key_attrs
      end.to change { user.keys.count }.by(1)
    end

    it "returns 400 for invalid ID" do
      post api("/users/0/keys", admin)
      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe 'GET /user/:id/keys' do
    it 'returns 404 for non-existing user' do
      user_id = not_existing_user_id

      get api("/users/#{user_id}/keys")

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of ssh keys' do
      user.keys << key
      user.save

      get api("/users/#{user.id}/keys")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(key.title)
    end
  end

  describe 'DELETE /user/:id/keys/:key_id' do
    before do
      admin
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/keys/42")
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'deletes existing key' do
        user.keys << key
        user.save

        expect do
          delete api("/users/#{user.id}/keys/#{key.id}", admin)

          expect(response).to have_gitlab_http_status(204)
        end.to change { user.keys.count }.by(-1)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/users/#{user.id}/keys/#{key.id}", admin) }
      end

      it 'returns 404 error if user not found' do
        user.keys << key
        user.save
        delete api("/users/0/keys/#{key.id}", admin)
        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/keys/42", admin)
        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Key Not Found')
      end
    end
  end

  describe 'POST /users/:id/keys' do
    before do
      admin
    end

    it 'does not create invalid GPG key' do
      post api("/users/#{user.id}/gpg_keys", admin)

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'creates GPG key' do
      key_attrs = attributes_for :gpg_key
      expect do
        post api("/users/#{user.id}/gpg_keys", admin), params: key_attrs

        expect(response).to have_gitlab_http_status(201)
      end.to change { user.gpg_keys.count }.by(1)
    end

    it 'returns 400 for invalid ID' do
      post api('/users/0/gpg_keys', admin)

      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe 'GET /user/:id/gpg_keys' do
    before do
      admin
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/users/#{user.id}/gpg_keys")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get api('/users/0/gpg_keys', admin)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/gpg_keys/42", admin)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 GPG Key Not Found')
      end

      it 'returns array of GPG keys' do
        user.gpg_keys << gpg_key
        user.save

        get api("/users/#{user.id}/gpg_keys", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['key']).to eq(gpg_key.key)
      end
    end
  end

  describe 'DELETE /user/:id/gpg_keys/:key_id' do
    before do
      admin
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/keys/42")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'deletes existing key' do
        user.gpg_keys << gpg_key
        user.save

        expect do
          delete api("/users/#{user.id}/gpg_keys/#{gpg_key.id}", admin)

          expect(response).to have_gitlab_http_status(204)
        end.to change { user.gpg_keys.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.keys << key
        user.save

        delete api("/users/0/gpg_keys/#{gpg_key.id}", admin)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/gpg_keys/42", admin)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 GPG Key Not Found')
      end
    end
  end

  describe 'POST /user/:id/gpg_keys/:key_id/revoke' do
    before do
      admin
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/users/#{user.id}/gpg_keys/42/revoke")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'revokes existing key' do
        user.gpg_keys << gpg_key
        user.save

        expect do
          post api("/users/#{user.id}/gpg_keys/#{gpg_key.id}/revoke", admin)

          expect(response).to have_gitlab_http_status(:accepted)
        end.to change { user.gpg_keys.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.gpg_keys << gpg_key
        user.save

        post api("/users/0/gpg_keys/#{gpg_key.id}/revoke", admin)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        post api("/users/#{user.id}/gpg_keys/42/revoke", admin)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 GPG Key Not Found')
      end
    end
  end

  describe "POST /users/:id/emails" do
    before do
      admin
    end

    it "does not create invalid email" do
      post api("/users/#{user.id}/emails", admin), params: {}

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('email is missing')
    end

    it "creates unverified email" do
      email_attrs = attributes_for :email
      expect do
        post api("/users/#{user.id}/emails", admin), params: email_attrs
      end.to change { user.emails.count }.by(1)

      email = Email.find_by(user_id: user.id, email: email_attrs[:email])
      expect(email).not_to be_confirmed
    end

    it "returns a 400 for invalid ID" do
      post api("/users/0/emails", admin)

      expect(response).to have_gitlab_http_status(400)
    end

    it "creates verified email" do
      email_attrs = attributes_for :email
      email_attrs[:skip_confirmation] = true

      post api("/users/#{user.id}/emails", admin), params: email_attrs

      expect(response).to have_gitlab_http_status(201)

      email = Email.find_by(user_id: user.id, email: email_attrs[:email])
      expect(email).to be_confirmed
    end
  end

  describe 'GET /user/:id/emails' do
    before do
      admin
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/users/#{user.id}/emails")
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get api('/users/0/emails', admin)
        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of emails' do
        user.emails << email
        user.save

        get api("/users/#{user.id}/emails", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['email']).to eq(email.email)
      end

      it "returns a 404 for invalid ID" do
        get api("/users/ASDF/emails", admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'DELETE /user/:id/emails/:email_id' do
    before do
      admin
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/emails/42")
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'deletes existing email' do
        user.emails << email
        user.save

        expect do
          delete api("/users/#{user.id}/emails/#{email.id}", admin)

          expect(response).to have_gitlab_http_status(204)
        end.to change { user.emails.count }.by(-1)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/users/#{user.id}/emails/#{email.id}", admin) }
      end

      it 'returns 404 error if user not found' do
        user.emails << email
        user.save
        delete api("/users/0/emails/#{email.id}", admin)
        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if email not foud' do
        delete api("/users/#{user.id}/emails/42", admin)
        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Email Not Found')
      end

      it "returns a 404 for invalid ID" do
        delete api("/users/ASDF/emails/bar", admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "DELETE /users/:id" do
    let!(:namespace) { user.namespace }
    let!(:issue) { create(:issue, author: user) }

    before do
      admin
    end

    it "deletes user", :sidekiq_might_not_need_inline do
      perform_enqueued_jobs { delete api("/users/#{user.id}", admin) }

      expect(response).to have_gitlab_http_status(204)
      expect { User.find(user.id) }.to raise_error ActiveRecord::RecordNotFound
      expect { Namespace.find(namespace.id) }.to raise_error ActiveRecord::RecordNotFound
    end

    context "sole owner of a group" do
      let!(:group) { create(:group).tap { |group| group.add_owner(user) } }

      context "hard delete disabled" do
        it "does not delete user" do
          perform_enqueued_jobs { delete api("/users/#{user.id}", admin)}
          expect(response).to have_gitlab_http_status(409)
        end
      end

      context "hard delete enabled" do
        it "delete user and group", :sidekiq_might_not_need_inline do
          perform_enqueued_jobs { delete api("/users/#{user.id}?hard_delete=true", admin)}
          expect(response).to have_gitlab_http_status(204)
          expect(Group.exists?(group.id)).to be_falsy
        end
      end
    end

    it_behaves_like '412 response' do
      let(:request) { api("/users/#{user.id}", admin) }
    end

    it "does not delete for unauthenticated user" do
      perform_enqueued_jobs { delete api("/users/#{user.id}") }
      expect(response).to have_gitlab_http_status(401)
    end

    it "is not available for non admin users" do
      perform_enqueued_jobs { delete api("/users/#{user.id}", user) }
      expect(response).to have_gitlab_http_status(403)
    end

    it "returns 404 for non-existing user" do
      perform_enqueued_jobs { delete api("/users/0", admin) }
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      perform_enqueued_jobs { delete api("/users/ASDF", admin) }

      expect(response).to have_gitlab_http_status(404)
    end

    context "hard delete disabled" do
      it "moves contributions to the ghost user", :sidekiq_might_not_need_inline do
        perform_enqueued_jobs { delete api("/users/#{user.id}", admin) }

        expect(response).to have_gitlab_http_status(204)
        expect(issue.reload).to be_persisted
        expect(issue.author.ghost?).to be_truthy
      end
    end

    context "hard delete enabled" do
      it "removes contributions", :sidekiq_might_not_need_inline do
        perform_enqueued_jobs { delete api("/users/#{user.id}?hard_delete=true", admin) }

        expect(response).to have_gitlab_http_status(204)
        expect(Issue.exists?(issue.id)).to be_falsy
      end
    end
  end

  describe "GET /user" do
    let(:personal_access_token) { create(:personal_access_token, user: user).token }

    shared_examples 'get user info' do |version|
      context 'with regular user' do
        context 'with personal access token' do
          it 'returns 403 without private token when sudo is defined' do
            get api("/user?private_token=#{personal_access_token}&sudo=123", version: version)

            expect(response).to have_gitlab_http_status(403)
          end
        end

        it 'returns current user without private token when sudo not defined' do
          get api("/user", user, version: version)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/user/public')
          expect(json_response['id']).to eq(user.id)
        end

        context "scopes" do
          let(:path) { "/user" }
          let(:api_call) { method(:api) }

          include_examples 'allows the "read_user" scope', version
        end
      end

      context 'with admin' do
        let(:admin_personal_access_token) { create(:personal_access_token, user: admin).token }

        context 'with personal access token' do
          it 'returns 403 without private token when sudo defined' do
            get api("/user?private_token=#{admin_personal_access_token}&sudo=#{user.id}", version: version)

            expect(response).to have_gitlab_http_status(403)
          end

          it 'returns initial current user without private token but with is_admin when sudo not defined' do
            get api("/user?private_token=#{admin_personal_access_token}", version: version)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/user/admin')
            expect(json_response['id']).to eq(admin.id)
          end
        end
      end

      context 'with unauthenticated user' do
        it "returns 401 error if user is unauthenticated" do
          get api("/user", version: version)

          expect(response).to have_gitlab_http_status(401)
        end
      end
    end

    it_behaves_like 'get user info', 'v3'
    it_behaves_like 'get user info', 'v4'
  end

  describe "GET /user/keys" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/keys")
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of ssh keys" do
        user.keys << key
        user.save

        get api("/user/keys", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first["title"]).to eq(key.title)
      end

      context "scopes" do
        let(:path) { "/user/keys" }
        let(:api_call) { method(:api) }

        include_examples 'allows the "read_user" scope'
      end
    end
  end

  describe "GET /user/keys/:key_id" do
    it "returns single key" do
      user.keys << key
      user.save
      get api("/user/keys/#{key.id}", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response["title"]).to eq(key.title)
    end

    it "returns 404 Not Found within invalid ID" do
      get api("/user/keys/42", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 404 error if admin accesses user's ssh key" do
      user.keys << key
      user.save
      admin
      get api("/user/keys/#{key.id}", admin)
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/keys/ASDF", admin)

      expect(response).to have_gitlab_http_status(404)
    end

    context "scopes" do
      let(:path) { "/user/keys/#{key.id}" }
      let(:api_call) { method(:api) }

      include_examples 'allows the "read_user" scope'
    end
  end

  describe "POST /user/keys" do
    it "creates ssh key" do
      key_attrs = attributes_for :key
      expect do
        post api("/user/keys", user), params: key_attrs
      end.to change { user.keys.count }.by(1)
      expect(response).to have_gitlab_http_status(201)
    end

    it "returns a 401 error if unauthorized" do
      post api("/user/keys"), params: { title: 'some title', key: 'some key' }
      expect(response).to have_gitlab_http_status(401)
    end

    it "does not create ssh key without key" do
      post api("/user/keys", user), params: { title: 'title' }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create ssh key without title' do
      post api('/user/keys', user), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('title is missing')
    end

    it "does not create ssh key without title" do
      post api("/user/keys", user), params: { key: "somekey" }
      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe "DELETE /user/keys/:key_id" do
    it "deletes existed key" do
      user.keys << key
      user.save

      expect do
        delete api("/user/keys/#{key.id}", user)

        expect(response).to have_gitlab_http_status(204)
      end.to change { user.keys.count}.by(-1)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/user/keys/#{key.id}", user) }
    end

    it "returns 404 if key ID not found" do
      delete api("/user/keys/42", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.keys << key
      user.save
      delete api("/user/keys/#{key.id}")
      expect(response).to have_gitlab_http_status(401)
    end

    it "returns a 404 for invalid ID" do
      delete api("/users/keys/ASDF", admin)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /user/gpg_keys' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/user/gpg_keys')

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns array of GPG keys' do
        user.gpg_keys << gpg_key
        user.save

        get api('/user/gpg_keys', user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['key']).to eq(gpg_key.key)
      end

      context 'scopes' do
        let(:path) { '/user/gpg_keys' }
        let(:api_call) { method(:api) }

        include_examples 'allows the "read_user" scope'
      end
    end
  end

  describe 'GET /user/gpg_keys/:key_id' do
    it 'returns a single key' do
      user.gpg_keys << gpg_key
      user.save

      get api("/user/gpg_keys/#{gpg_key.id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['key']).to eq(gpg_key.key)
    end

    it 'returns 404 Not Found within invalid ID' do
      get api('/user/gpg_keys/42', user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it "returns 404 error if admin accesses user's GPG key" do
      user.gpg_keys << gpg_key
      user.save

      get api("/user/gpg_keys/#{gpg_key.id}", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns 404 for invalid ID' do
      get api('/users/gpg_keys/ASDF', admin)

      expect(response).to have_gitlab_http_status(404)
    end

    context 'scopes' do
      let(:path) { "/user/gpg_keys/#{gpg_key.id}" }
      let(:api_call) { method(:api) }

      include_examples 'allows the "read_user" scope'
    end
  end

  describe 'POST /user/gpg_keys' do
    it 'creates a GPG key' do
      key_attrs = attributes_for :gpg_key
      expect do
        post api('/user/gpg_keys', user), params: key_attrs

        expect(response).to have_gitlab_http_status(201)
      end.to change { user.gpg_keys.count }.by(1)
    end

    it 'returns a 401 error if unauthorized' do
      post api('/user/gpg_keys'), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(401)
    end

    it 'does not create GPG key without key' do
      post api('/user/gpg_keys', user)

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('key is missing')
    end
  end

  describe 'POST /user/gpg_keys/:key_id/revoke' do
    it 'revokes existing GPG key' do
      user.gpg_keys << gpg_key
      user.save

      expect do
        post api("/user/gpg_keys/#{gpg_key.id}/revoke", user)

        expect(response).to have_gitlab_http_status(:accepted)
      end.to change { user.gpg_keys.count}.by(-1)
    end

    it 'returns 404 if key ID not found' do
      post api('/user/gpg_keys/42/revoke', user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns 401 error if unauthorized' do
      user.gpg_keys << gpg_key
      user.save

      post api("/user/gpg_keys/#{gpg_key.id}/revoke")

      expect(response).to have_gitlab_http_status(401)
    end

    it 'returns a 404 for invalid ID' do
      post api('/users/gpg_keys/ASDF/revoke', admin)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'DELETE /user/gpg_keys/:key_id' do
    it 'deletes existing GPG key' do
      user.gpg_keys << gpg_key
      user.save

      expect do
        delete api("/user/gpg_keys/#{gpg_key.id}", user)

        expect(response).to have_gitlab_http_status(204)
      end.to change { user.gpg_keys.count}.by(-1)
    end

    it 'returns 404 if key ID not found' do
      delete api('/user/gpg_keys/42', user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns 401 error if unauthorized' do
      user.gpg_keys << gpg_key
      user.save

      delete api("/user/gpg_keys/#{gpg_key.id}")

      expect(response).to have_gitlab_http_status(401)
    end

    it 'returns a 404 for invalid ID' do
      delete api('/users/gpg_keys/ASDF', admin)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "GET /user/emails" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/emails")
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of emails" do
        user.emails << email
        user.save

        get api("/user/emails", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first["email"]).to eq(email.email)
      end

      context "scopes" do
        let(:path) { "/user/emails" }
        let(:api_call) { method(:api) }

        include_examples 'allows the "read_user" scope'
      end
    end
  end

  describe "GET /user/emails/:email_id" do
    it "returns single email" do
      user.emails << email
      user.save
      get api("/user/emails/#{email.id}", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response["email"]).to eq(email.email)
    end

    it "returns 404 Not Found within invalid ID" do
      get api("/user/emails/42", user)
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 404 error if admin accesses user's email" do
      user.emails << email
      user.save
      admin
      get api("/user/emails/#{email.id}", admin)
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/emails/ASDF", admin)

      expect(response).to have_gitlab_http_status(404)
    end

    context "scopes" do
      let(:path) { "/user/emails/#{email.id}" }
      let(:api_call) { method(:api) }

      include_examples 'allows the "read_user" scope'
    end
  end

  describe "POST /user/emails" do
    it "creates email" do
      email_attrs = attributes_for :email
      expect do
        post api("/user/emails", user), params: email_attrs
      end.to change { user.emails.count }.by(1)
      expect(response).to have_gitlab_http_status(201)
    end

    it "returns a 401 error if unauthorized" do
      post api("/user/emails"), params: { email: 'some email' }
      expect(response).to have_gitlab_http_status(401)
    end

    it "does not create email with invalid email" do
      post api("/user/emails", user), params: {}

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('email is missing')
    end
  end

  describe "DELETE /user/emails/:email_id" do
    it "deletes existed email" do
      user.emails << email
      user.save

      expect do
        delete api("/user/emails/#{email.id}", user)

        expect(response).to have_gitlab_http_status(204)
      end.to change { user.emails.count}.by(-1)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/user/emails/#{email.id}", user) }
    end

    it "returns 404 if email ID not found" do
      delete api("/user/emails/42", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.emails << email
      user.save
      delete api("/user/emails/#{email.id}")
      expect(response).to have_gitlab_http_status(401)
    end

    it "returns 400 for invalid ID" do
      delete api("/user/emails/ASDF", admin)

      expect(response).to have_gitlab_http_status(400)
    end
  end

  context 'activate and deactivate' do
    shared_examples '404' do
      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end

    describe 'POST /users/:id/activate' do
      context 'performed by a non-admin user' do
        it 'is not authorized to perform the action' do
          post api("/users/#{user.id}/activate", user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'performed by an admin user' do
        context 'for a deactivated user' do
          before do
            user.deactivate

            post api("/users/#{user.id}/activate", admin)
          end

          it 'activates a deactivated user' do
            expect(response).to have_gitlab_http_status(201)
            expect(user.reload.state).to eq('active')
          end
        end

        context 'for an active user' do
          before do
            user.activate

            post api("/users/#{user.id}/activate", admin)
          end

          it 'returns 201' do
            expect(response).to have_gitlab_http_status(201)
            expect(user.reload.state).to eq('active')
          end
        end

        context 'for a blocked user' do
          before do
            user.block

            post api("/users/#{user.id}/activate", admin)
          end

          it 'returns 403' do
            expect(response).to have_gitlab_http_status(403)
            expect(json_response['message']).to eq('403 Forbidden  - A blocked user must be unblocked to be activated')
            expect(user.reload.state).to eq('blocked')
          end
        end

        context 'for a ldap blocked user' do
          before do
            user.ldap_block

            post api("/users/#{user.id}/activate", admin)
          end

          it 'returns 403' do
            expect(response).to have_gitlab_http_status(403)
            expect(json_response['message']).to eq('403 Forbidden  - A blocked user must be unblocked to be activated')
            expect(user.reload.state).to eq('ldap_blocked')
          end
        end

        context 'for a user that does not exist' do
          before do
            post api("/users/0/activate", admin)
          end

          it_behaves_like '404'
        end
      end
    end

    describe 'POST /users/:id/deactivate' do
      context 'performed by a non-admin user' do
        it 'is not authorized to perform the action' do
          post api("/users/#{user.id}/deactivate", user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'performed by an admin user' do
        context 'for an active user' do
          let(:activity) { {} }
          let(:user) { create(:user, username: 'user.with.dot', **activity) }

          context 'with no recent activity' do
            let(:activity) { { last_activity_on: ::User::MINIMUM_INACTIVE_DAYS.next.days.ago } }

            before do
              post api("/users/#{user.id}/deactivate", admin)
            end

            it 'deactivates an active user' do
              expect(response).to have_gitlab_http_status(201)
              expect(user.reload.state).to eq('deactivated')
            end
          end

          context 'with recent activity' do
            let(:activity) { { last_activity_on: ::User::MINIMUM_INACTIVE_DAYS.pred.days.ago } }

            before do
              post api("/users/#{user.id}/deactivate", admin)
            end

            it 'does not deactivate an active user' do
              expect(response).to have_gitlab_http_status(403)
              expect(json_response['message']).to eq("403 Forbidden  - The user you are trying to deactivate has been active in the past #{::User::MINIMUM_INACTIVE_DAYS} days and cannot be deactivated")
              expect(user.reload.state).to eq('active')
            end
          end
        end

        context 'for a deactivated user' do
          before do
            user.deactivate

            post api("/users/#{user.id}/deactivate", admin)
          end

          it 'returns 201' do
            expect(response).to have_gitlab_http_status(201)
            expect(user.reload.state).to eq('deactivated')
          end
        end

        context 'for a blocked user' do
          before do
            user.block

            post api("/users/#{user.id}/deactivate", admin)
          end

          it 'returns 403' do
            expect(response).to have_gitlab_http_status(403)
            expect(json_response['message']).to eq('403 Forbidden  - A blocked user cannot be deactivated by the API')
            expect(user.reload.state).to eq('blocked')
          end
        end

        context 'for a ldap blocked user' do
          before do
            user.ldap_block

            post api("/users/#{user.id}/deactivate", admin)
          end

          it 'returns 403' do
            expect(response).to have_gitlab_http_status(403)
            expect(json_response['message']).to eq('403 Forbidden  - A blocked user cannot be deactivated by the API')
            expect(user.reload.state).to eq('ldap_blocked')
          end
        end

        context 'for a user that does not exist' do
          before do
            post api("/users/0/deactivate", admin)
          end

          it_behaves_like '404'
        end
      end
    end
  end

  describe 'POST /users/:id/block' do
    before do
      admin
    end

    it 'blocks existing user' do
      post api("/users/#{user.id}/block", admin)
      expect(response).to have_gitlab_http_status(201)
      expect(user.reload.state).to eq('blocked')
    end

    it 'does not re-block ldap blocked users' do
      post api("/users/#{ldap_blocked_user.id}/block", admin)
      expect(response).to have_gitlab_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      post api("/users/#{user.id}/block", user)
      expect(response).to have_gitlab_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      post api('/users/0/block', admin)
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end

  describe 'POST /users/:id/unblock' do
    let(:blocked_user) { create(:user, state: 'blocked') }
    let(:deactivated_user) { create(:user, state: 'deactivated') }

    before do
      admin
    end

    it 'unblocks existing user' do
      post api("/users/#{user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(201)
      expect(user.reload.state).to eq('active')
    end

    it 'unblocks a blocked user' do
      post api("/users/#{blocked_user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(201)
      expect(blocked_user.reload.state).to eq('active')
    end

    it 'does not unblock ldap blocked users' do
      post api("/users/#{ldap_blocked_user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not unblock deactivated users' do
      post api("/users/#{deactivated_user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(403)
      expect(deactivated_user.reload.state).to eq('deactivated')
    end

    it 'is not available for non admin users' do
      post api("/users/#{user.id}/unblock", user)
      expect(response).to have_gitlab_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      post api('/users/0/block', admin)
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      post api("/users/ASDF/block", admin)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  context "user activities", :clean_gitlab_redis_shared_state do
    let!(:old_active_user) { create(:user, last_activity_on: Time.utc(2000, 1, 1)) }
    let!(:newly_active_user) { create(:user, last_activity_on: 2.days.ago.midday) }

    context 'last activity as normal user' do
      it 'has no permission' do
        get api("/user/activities", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'as admin' do
      it 'returns the activities from the last 6 months' do
        get api("/user/activities", admin)

        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(1)

        activity = json_response.last

        expect(activity['username']).to eq(newly_active_user.username)
        expect(activity['last_activity_on']).to eq(2.days.ago.to_date.to_s)
        expect(activity['last_activity_at']).to eq(2.days.ago.to_date.to_s)
      end

      context 'passing a :from parameter' do
        it 'returns the activities from the given date' do
          get api("/user/activities?from=2000-1-1", admin)

          expect(response).to include_pagination_headers
          expect(json_response.size).to eq(2)

          activity = json_response.first

          expect(activity['username']).to eq(old_active_user.username)
          expect(activity['last_activity_on']).to eq(Time.utc(2000, 1, 1).to_date.to_s)
          expect(activity['last_activity_at']).to eq(Time.utc(2000, 1, 1).to_date.to_s)
        end
      end
    end
  end

  describe 'GET /user/status' do
    let(:path) { '/user/status' }

    it_behaves_like 'rendering user status'
  end

  describe 'PUT /user/status' do
    it 'saves the status' do
      put api('/user/status', user), params: { emoji: 'smirk', message: 'hello world' }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response['emoji']).to eq('smirk')
    end

    it 'renders errors when the status was invalid' do
      put api('/user/status', user), params: { emoji: 'does not exist', message: 'hello world' }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['emoji']).to be_present
    end

    it 'deletes the status when passing empty values' do
      put api('/user/status', user)

      expect(response).to have_gitlab_http_status(:success)
      expect(user.reload.status).to be_nil
    end
  end

  describe 'GET /users/:user_id/impersonation_tokens' do
    let!(:active_personal_access_token) { create(:personal_access_token, user: user) }
    let!(:revoked_personal_access_token) { create(:personal_access_token, :revoked, user: user) }
    let!(:expired_personal_access_token) { create(:personal_access_token, :expired, user: user) }
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let!(:revoked_impersonation_token) { create(:personal_access_token, :impersonation, :revoked, user: user) }

    it 'returns a 404 error if user not found' do
      get api("/users/#{not_existing_user_id}/impersonation_tokens", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api("/users/#{not_existing_user_id}/impersonation_tokens", user)

      expect(response).to have_gitlab_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns an array of all impersonated tokens' do
      get api("/users/#{user.id}/impersonation_tokens", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
    end

    it 'returns an array of active impersonation tokens if state active' do
      get api("/users/#{user.id}/impersonation_tokens?state=active", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response).to all(include('active' => true))
    end

    it 'returns an array of inactive personal access tokens if active is set to false' do
      get api("/users/#{user.id}/impersonation_tokens?state=inactive", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response).to all(include('active' => false))
    end
  end

  describe 'POST /users/:user_id/impersonation_tokens' do
    let(:name) { 'my new pat' }
    let(:expires_at) { '2016-12-28' }
    let(:scopes) { %w(api read_user) }
    let(:impersonation) { true }

    it 'returns validation error if impersonation token misses some attributes' do
      post api("/users/#{user.id}/impersonation_tokens", admin)

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns a 404 error if user not found' do
      post api("/users/#{not_existing_user_id}/impersonation_tokens", admin),
        params: {
          name: name,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      post api("/users/#{user.id}/impersonation_tokens", user),
        params: {
          name: name,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'creates a impersonation token' do
      post api("/users/#{user.id}/impersonation_tokens", admin),
        params: {
          name: name,
          expires_at: expires_at,
          scopes: scopes,
          impersonation: impersonation
        }

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['name']).to eq(name)
      expect(json_response['scopes']).to eq(scopes)
      expect(json_response['expires_at']).to eq(expires_at)
      expect(json_response['id']).to be_present
      expect(json_response['created_at']).to be_present
      expect(json_response['active']).to be_falsey
      expect(json_response['revoked']).to be_falsey
      expect(json_response['token']).to be_present
      expect(json_response['impersonation']).to eq(impersonation)
    end
  end

  describe 'GET /users/:user_id/impersonation_tokens/:impersonation_token_id' do
    let!(:personal_access_token) { create(:personal_access_token, user: user) }
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

    it 'returns 404 error if user not found' do
      get api("/users/#{not_existing_user_id}/impersonation_tokens/1", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      get api("/users/#{user.id}/impersonation_tokens/#{not_existing_pat_id}", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      get api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", user)

      expect(response).to have_gitlab_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns an impersonation token' do
      get api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['token']).not_to be_present
      expect(json_response['impersonation']).to be_truthy
    end
  end

  describe 'DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id' do
    let!(:personal_access_token) { create(:personal_access_token, user: user) }
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

    it 'returns a 404 error if user not found' do
      delete api("/users/#{not_existing_user_id}/impersonation_tokens/1", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      delete api("/users/#{user.id}/impersonation_tokens/#{not_existing_pat_id}", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      delete api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      delete api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", user)

      expect(response).to have_gitlab_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it_behaves_like '412 response' do
      let(:request) { api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin) }
    end

    it 'revokes a impersonation token' do
      delete api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin)

      expect(response).to have_gitlab_http_status(204)
      expect(impersonation_token.revoked).to be_falsey
      expect(impersonation_token.reload.revoked).to be_truthy
    end
  end

  it_behaves_like 'custom attributes endpoints', 'users' do
    let(:attributable) { user }
    let(:other_attributable) { admin }
  end
end
