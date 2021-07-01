# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Users do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user, reload: true) { create(:user, username: 'user.withdot') }
  let_it_be(:key) { create(:key, user: user) }
  let_it_be(:gpg_key) { create(:gpg_key, user: user) }
  let_it_be(:email) { create(:email, user: user) }

  let(:omniauth_user) { create(:omniauth_user) }
  let(:ldap_blocked_user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }
  let(:private_user) { create(:user, private_profile: true) }

  context 'admin notes' do
    let_it_be(:admin) { create(:admin, note: '2019-10-06 | 2FA added | user requested | www.gitlab.com') }
    let_it_be(:user, reload: true) { create(:user, note: '2018-11-05 | 2FA removed | user requested | www.gitlab.com') }

    describe 'POST /users' do
      context 'when unauthenticated' do
        it 'return authentication error' do
          post api('/users')

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when authenticated' do
        context 'as an admin' do
          it 'contains the note of the user' do
            optional_attributes = { note: 'Awesome Note' }
            attributes = attributes_for(:user).merge(optional_attributes)

            post api('/users', admin), params: attributes

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['note']).to eq(optional_attributes[:note])
          end
        end

        context 'as a regular user' do
          it 'does not allow creating new user' do
            post api('/users', user), params: attributes_for(:user)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end

    describe 'GET /users/:id' do
      context 'when unauthenticated' do
        it 'does not contain the note of the user' do
          get api("/users/#{user.id}")

          expect(json_response).not_to have_key('note')
        end
      end

      context 'when authenticated' do
        context 'as an admin' do
          it 'contains the note of the user' do
            get api("/users/#{user.id}", admin)

            expect(json_response).to have_key('note')
            expect(json_response['note']).to eq(user.note)
            expect(json_response).to have_key('sign_in_count')
          end
        end

        context 'as a regular user' do
          it 'does not contain the note of the user' do
            get api("/users/#{user.id}", user)

            expect(json_response).not_to have_key('note')
            expect(json_response).not_to have_key('sign_in_count')
          end
        end
      end
    end

    describe "PUT /users/:id" do
      context 'when user is an admin' do
        it "updates note of the user" do
          new_note = '2019-07-07 | Email changed | user requested | www.gitlab.com'

          expect do
            put api("/users/#{user.id}", admin), params: { note: new_note }
          end.to change { user.reload.note }
                   .from('2018-11-05 | 2FA removed | user requested | www.gitlab.com')
                   .to(new_note)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['note']).to eq(new_note)
        end
      end

      context 'when user is not an admin' do
        it "cannot update their own note" do
          expect do
            put api("/users/#{user.id}", user), params: { note: 'new note' }
          end.not_to change { user.reload.note }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    describe 'GET /users/' do
      context 'when unauthenticated' do
        it "does not contain the note of users" do
          get api("/users"), params: { username: user.username }

          expect(json_response.first).not_to have_key('note')
        end
      end

      context 'when authenticated' do
        context 'as a regular user' do
          it 'does not contain the note of users' do
            get api("/users", user), params: { username: user.username }

            expect(json_response.first).not_to have_key('note')
          end
        end

        context 'as an admin' do
          it 'contains the note of users' do
            get api("/users", admin), params: { username: user.username }

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response.first).to have_key('note')
            expect(json_response.first['note']).to eq '2018-11-05 | 2FA removed | user requested | www.gitlab.com'
          end
        end
      end
    end

    describe 'GET /user' do
      context 'when authenticated' do
        context 'as an admin' do
          context 'accesses their own profile' do
            it 'contains the note of the user' do
              get api("/user", admin)

              expect(json_response).to have_key('note')
              expect(json_response['note']).to eq(admin.note)
            end
          end

          context 'sudo' do
            let(:admin_personal_access_token) { create(:personal_access_token, user: admin, scopes: %w[api sudo]).token }

            context 'accesses the profile of another regular user' do
              it 'does not contain the note of the user' do
                get api("/user?private_token=#{admin_personal_access_token}&sudo=#{user.id}")

                expect(json_response['id']).to eq(user.id)
                expect(json_response).not_to have_key('note')
              end
            end

            context 'accesses the profile of another admin' do
              let(:admin_2) { create(:admin, note: '2010-10-10 | 2FA added | admin requested | www.gitlab.com') }

              it 'contains the note of the user' do
                get api("/user?private_token=#{admin_personal_access_token}&sudo=#{admin_2.id}")

                expect(json_response['id']).to eq(admin_2.id)
                expect(json_response).to have_key('note')
                expect(json_response['note']).to eq(admin_2.note)
              end
            end
          end
        end

        context 'as a regular user' do
          it 'does not contain the note of the user' do
            get api("/user", user)

            expect(json_response).not_to have_key('note')
          end
        end
      end
    end
  end

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

        expect(response).to have_gitlab_http_status(:forbidden)
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

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(0)
      end

      it "does not return the highest role" do
        get api("/users"), params: { username: user.username }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'highest_role'
      end

      it "does not return the current or last sign-in ip addresses" do
        get api("/users"), params: { username: user.username }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'current_sign_in_ip'
        expect(json_response.first.keys).not_to include 'last_sign_in_ip'
      end

      context "when public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it "returns authorization error when the `username` parameter refers to an inaccessible user" do
          get api("/users"), params: { username: user.username }

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it "returns authorization error when the `username` parameter is not passed" do
          get api("/users")

          expect(response).to have_gitlab_http_status(:forbidden)
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

      it "returns an array of external users" do
        create(:user)
        external_user = create(:user, external: true)

        get api("/users?external=true", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(1)
        expect(json_response[0]['id']).to eq(external_user.id)
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

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'does not reveal the `is_admin` flag of the user' do
        get api('/users', user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'is_admin'
      end

      context 'exclude_internal param' do
        let_it_be(:internal_user) { User.alert_bot }

        it 'returns all users when it is not set' do
          get api("/users?exclude_internal=false", user)

          expect(response).to match_response_schema('public_api/v4/user/basics')
          expect(response).to include_pagination_headers
          expect(json_response.map { |u| u['id'] }).to include(internal_user.id)
        end

        it 'returns all non internal users when it is set' do
          get api("/users?exclude_internal=true", user)

          expect(response).to match_response_schema('public_api/v4/user/basics')
          expect(response).to include_pagination_headers
          expect(json_response.map { |u| u['id'] }).not_to include(internal_user.id)
        end
      end

      context 'admins param' do
        it 'returns all users' do
          get api("/users?admins=true", user)

          expect(response).to match_response_schema('public_api/v4/user/basics')
          expect(json_response.size).to eq(2)
          expect(json_response.map { |u| u['id'] }).to include(user.id, admin.id)
        end
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

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns 400 error if provider with no extern_uid" do
        get api("/users?provider=#{omniauth_user.identities.first.provider}", admin)

        expect(response).to have_gitlab_http_status(:bad_request)
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
        # order of let_it_be definitions:
        # - admin
        # - user

        get api('/users', admin), params: { order_by: 'id', sort: 'asc' }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(2)
        expect(json_response.first['id']).to eq(admin.id)
        expect(json_response.last['id']).to eq(user.id)
      end

      it 'returns users with 2fa enabled' do
        user_with_2fa = create(:user, :two_factor_via_otp)

        get api('/users', admin), params: { two_factor: 'enabled' }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(user_with_2fa.id)
      end

      it "returns users without projects" do
        user_without_projects = create(:user)
        create(:project, namespace: user.namespace)
        create(:project, namespace: admin.namespace)

        get api('/users', admin), params: { without_projects: true }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(user_without_projects.id)
      end

      it 'returns 400 when provided incorrect sort params' do
        get api('/users', admin), params: { order_by: 'magic', sort: 'asc' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'admins param' do
      it 'returns only admins' do
        get api("/users?admins=true", admin)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(admin.id)
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

    it "does not return the user's sign in IPs" do
      get api("/users/#{user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'current_sign_in_ip'
      expect(json_response.keys).not_to include 'last_sign_in_ip'
    end

    it "does not contain plan or trial data" do
      get api("/users/#{user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'plan'
      expect(json_response.keys).not_to include 'trial'
    end

    context 'when job title is present' do
      let(:job_title) { 'Fullstack Engineer' }

      before do
        create(:user_detail, user: user, job_title: job_title)
      end

      it 'returns job title of a user' do
        get api("/users/#{user.id}", user)

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response['job_title']).to eq(job_title)
      end
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

      if Gitlab.ee?
        it 'does not include values for plan or trial' do
          get api("/users/#{user.id}", admin)

          expect(response).to match_response_schema('public_api/v4/user/basic')
        end
      else
        it 'does not include plan or trial data' do
          get api("/users/#{user.id}", admin)

          expect(response).to match_response_schema('public_api/v4/user/basic')
          expect(json_response.keys).not_to include 'plan'
          expect(json_response.keys).not_to include 'trial'
        end
      end

      context 'when user has not logged in' do
        it 'does not include the sign in IPs' do
          get api("/users/#{user.id}", admin)

          expect(response).to match_response_schema('public_api/v4/user/admin')
          expect(json_response).to include('current_sign_in_ip' => nil, 'last_sign_in_ip' => nil)
        end
      end

      context 'when user has logged in' do
        let_it_be(:signed_in_user) { create(:user, :with_sign_ins) }

        it 'includes the sign in IPs' do
          get api("/users/#{signed_in_user.id}", admin)

          expect(response).to match_response_schema('public_api/v4/user/admin')
          expect(json_response['current_sign_in_ip']).to eq('127.0.0.1')
          expect(json_response['last_sign_in_ip']).to eq('127.0.0.1')
        end
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

        expect(response).to have_gitlab_http_status(:not_found)
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

      it "returns the `followers` field for public users" do
        get api("/users/#{user.id}")

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response.keys).to include 'followers'
      end

      it "does not return the `followers` field for private users" do
        get api("/users/#{private_user.id}")

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response.keys).not_to include 'followers'
      end

      it "returns the `following` field for public users" do
        get api("/users/#{user.id}")

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response.keys).to include 'following'
      end

      it "does not return the `following` field for private users" do
        get api("/users/#{private_user.id}")

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response.keys).not_to include 'following'
      end
    end

    it "returns a 404 error if user id not found" do
      get api("/users/0", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      get api("/users/1ASDF", user)

      expect(response).to have_gitlab_http_status(:not_found)
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

  describe 'POST /users/:id/follow' do
    let(:followee) { create(:user) }

    context 'on an unfollowed user' do
      it 'follows the user' do
        post api("/users/#{followee.id}/follow", user)

        expect(user.followees).to contain_exactly(followee)
        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'on a followed user' do
      before do
        user.follow(followee)
      end

      it 'does not change following' do
        post api("/users/#{followee.id}/follow", user)

        expect(user.followees).to contain_exactly(followee)
        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end
  end

  describe 'POST /users/:id/unfollow' do
    let(:followee) { create(:user) }

    context 'on a followed user' do
      before do
        user.follow(followee)
      end

      it 'unfollow the user' do
        post api("/users/#{followee.id}/unfollow", user)

        expect(user.followees).to be_empty
        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'on an unfollowed user' do
      it 'does not change following' do
        post api("/users/#{followee.id}/unfollow", user)

        expect(user.followees).to be_empty
        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end
  end

  describe 'GET /users/:id/followers' do
    let(:follower) { create(:user) }

    context 'user has followers' do
      it 'lists followers' do
        follower.follow(user)

        get api("/users/#{user.id}/followers", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
      end

      it 'do not lists followers if profile is private' do
        follower.follow(private_user)

        get api("/users/#{private_user.id}/followers", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end

    context 'user does not have any follower' do
      it 'does list nothing' do
        get api("/users/#{user.id}/followers", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_empty
      end
    end
  end

  describe 'GET /users/:id/following' do
    let(:followee) { create(:user) }

    context 'user has followers' do
      it 'lists following user' do
        user.follow(followee)

        get api("/users/#{user.id}/following", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
      end

      it 'do not lists following user if profile is private' do
        user.follow(private_user)

        get api("/users/#{private_user.id}/following", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end

    context 'user does not have any follower' do
      it 'does list nothing' do
        get api("/users/#{user.id}/following", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_empty
      end
    end
  end

  describe "POST /users" do
    it "creates user" do
      expect do
        post api("/users", admin), params: attributes_for(:user, projects_limit: 3)
      end.to change { User.count }.by(1)
    end

    it "creates user with correct attributes" do
      post api('/users', admin), params: attributes_for(:user, admin: true, can_create_group: true)
      expect(response).to have_gitlab_http_status(:created)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(true)
      expect(new_user.can_create_group).to eq(true)
    end

    it "creates user with optional attributes" do
      optional_attributes = { confirm: true, theme_id: 2, color_scheme_id: 4 }
      attributes = attributes_for(:user).merge(optional_attributes)

      post api('/users', admin), params: attributes

      expect(response).to have_gitlab_http_status(:created)
    end

    it "creates non-admin user" do
      post api('/users', admin), params: attributes_for(:user, admin: false, can_create_group: false)
      expect(response).to have_gitlab_http_status(:created)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(false)
      expect(new_user.can_create_group).to eq(false)
    end

    it "creates non-admin users by default" do
      post api('/users', admin), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(:created)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(false)
    end

    it "returns 201 Created on success" do
      post api("/users", admin), params: attributes_for(:user, projects_limit: 3)
      expect(response).to match_response_schema('public_api/v4/user/admin')
      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates non-external users by default' do
      post api("/users", admin), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.external).to be_falsy
    end

    it 'allows an external user to be created' do
      post api("/users", admin), params: attributes_for(:user, external: true)
      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.external).to be_truthy
    end

    it "creates user with reset password" do
      post api('/users', admin), params: attributes_for(:user, reset_password: true).except(:password)

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user.recently_sent_password_reset?).to eq(true)
    end

    it "creates user with random password" do
      params = attributes_for(:user, force_random_password: true)
      params.delete(:password)
      post api('/users', admin), params: params

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user.encrypted_password).to be_present
    end

    it "creates user with private profile" do
      post api('/users', admin), params: attributes_for(:user, private_profile: true)

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user).not_to eq(nil)
      expect(new_user.private_profile?).to eq(true)
    end

    it "creates user with view_diffs_file_by_file" do
      post api('/users', admin), params: attributes_for(:user, view_diffs_file_by_file: true)

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user).not_to eq(nil)
      expect(new_user.user_preference.view_diffs_file_by_file?).to eq(true)
    end

    it "does not create user with invalid email" do
      post api('/users', admin),
        params: {
          email: 'invalid email',
          password: 'password',
          name: 'test'
        }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if name not given' do
      post api('/users', admin), params: attributes_for(:user).except(:name)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if password not given' do
      post api('/users', admin), params: attributes_for(:user).except(:password)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if email not given' do
      post api('/users', admin), params: attributes_for(:user).except(:email)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if username not given' do
      post api('/users', admin), params: attributes_for(:user).except(:username)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "doesn't create user with invalid optional attributes" do
      optional_attributes = { theme_id: 50, color_scheme_id: 50 }
      attributes = attributes_for(:user).merge(optional_attributes)

      post api('/users', admin), params: attributes

      expect(response).to have_gitlab_http_status(:bad_request)
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
      expect(response).to have_gitlab_http_status(:bad_request)
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
      expect(response).to have_gitlab_http_status(:forbidden)
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
        expect(response).to have_gitlab_http_status(:conflict)
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
        expect(response).to have_gitlab_http_status(:conflict)
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
        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to eq('Username has already been taken')
      end

      it 'creates user with new identity' do
        post api("/users", admin), params: attributes_for(:user, provider: 'github', extern_uid: '67890')

        expect(response).to have_gitlab_http_status(:created)
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
    it "returns 200 OK on success" do
      put api("/users/#{user.id}", admin), params: { bio: 'new test bio' }

      expect(response).to match_response_schema('public_api/v4/user/admin')
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'updating password' do
      def update_password(user, admin, password = User.random_password)
        put api("/users/#{user.id}", admin), params: { password: password }
      end

      context 'admin updates their own password' do
        it 'does not force reset on next login' do
          update_password(admin, admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(user.reload.password_expired?).to eq(false)
        end

        it 'does not enqueue the `admin changed your password` email' do
          expect { update_password(admin, admin) }
            .not_to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
        end

        it 'enqueues the `password changed` email' do
          expect { update_password(admin, admin) }
            .to have_enqueued_mail(DeviseMailer, :password_change)
        end
      end

      context 'admin updates the password of another user' do
        it 'forces reset on next login' do
          update_password(user, admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(user.reload.password_expired?).to eq(true)
        end

        it 'enqueues the `admin changed your password` email' do
          expect { update_password(user, admin) }
            .to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
        end

        it 'does not enqueue the `password changed` email' do
          expect { update_password(user, admin) }
            .not_to have_enqueued_mail(DeviseMailer, :password_change)
        end
      end
    end

    it "updates user with new bio" do
      put api("/users/#{user.id}", admin), params: { bio: 'new test bio' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['bio']).to eq('new test bio')
      expect(user.reload.bio).to eq('new test bio')
    end

    it "updates user with empty bio" do
      user.update!(bio: 'previous bio')

      put api("/users/#{user.id}", admin), params: { bio: '' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['bio']).to eq('')
      expect(user.reload.bio).to eq('')
    end

    it 'updates user with nil bio' do
      put api("/users/#{user.id}", admin), params: { bio: nil }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['bio']).to eq('')
      expect(user.reload.bio).to eq('')
    end

    it "updates user with organization" do
      put api("/users/#{user.id}", admin), params: { organization: 'GitLab' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['organization']).to eq('GitLab')
      expect(user.reload.organization).to eq('GitLab')
    end

    it 'updates user with avatar' do
      put api("/users/#{user.id}", admin), params: { avatar: fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }

      user.reload

      expect(user.avatar).to be_present
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['avatar_url']).to include(user.avatar_path)
    end

    it 'updates user with a new email' do
      old_email = user.email
      old_notification_email = user.notification_email
      put api("/users/#{user.id}", admin), params: { email: 'new@email.com' }

      user.reload

      expect(response).to have_gitlab_http_status(:ok)
      expect(user).to be_confirmed
      expect(user.email).to eq(old_email)
      expect(user.notification_email).to eq(old_notification_email)
      expect(user.unconfirmed_email).to eq('new@email.com')
    end

    it 'skips reconfirmation when requested' do
      put api("/users/#{user.id}", admin), params: { email: 'new@email.com', skip_reconfirmation: true }

      user.reload

      expect(response).to have_gitlab_http_status(:ok)
      expect(user).to be_confirmed
      expect(user.email).to eq('new@email.com')
    end

    it 'updates user with their own username' do
      put api("/users/#{user.id}", admin), params: { username: user.username }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['username']).to eq(user.username)
      expect(user.reload.username).to eq(user.username)
    end

    it "updates user's existing identity" do
      put api("/users/#{omniauth_user.id}", admin), params: { provider: 'ldapmain', extern_uid: '654321' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(omniauth_user.reload.identities.first.extern_uid).to eq('654321')
    end

    it 'updates user with new identity' do
      put api("/users/#{user.id}", admin), params: { provider: 'github', extern_uid: 'john' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.identities.first.extern_uid).to eq('john')
      expect(user.reload.identities.first.provider).to eq('github')
    end

    it "updates admin status" do
      put api("/users/#{user.id}", admin), params: { admin: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.admin).to eq(true)
    end

    it "updates external status" do
      put api("/users/#{user.id}", admin), params: { external: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['external']).to eq(true)
      expect(user.reload.external?).to be_truthy
    end

    it "private profile is false by default" do
      put api("/users/#{user.id}", admin), params: {}

      expect(user.reload.private_profile).to eq(false)
    end

    it "does have default values for theme and color-scheme ID" do
      put api("/users/#{user.id}", admin), params: {}

      expect(user.reload.theme_id).to eq(Gitlab::Themes.default.id)
      expect(user.reload.color_scheme_id).to eq(Gitlab::ColorSchemes.default.id)
    end

    it "updates private profile" do
      put api("/users/#{user.id}", admin), params: { private_profile: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.private_profile).to eq(true)
    end

    it "updates viewing diffs file by file" do
      put api("/users/#{user.id}", admin), params: { view_diffs_file_by_file: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.user_preference.view_diffs_file_by_file?).to eq(true)
    end

    it "updates private profile to false when nil is given" do
      user.update!(private_profile: true)

      put api("/users/#{user.id}", admin), params: { private_profile: nil }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.private_profile).to eq(false)
    end

    it "does not modify private profile when field is not provided" do
      user.update!(private_profile: true)

      put api("/users/#{user.id}", admin), params: {}

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.private_profile).to eq(true)
    end

    it "does not modify theme or color-scheme ID when field is not provided" do
      theme = Gitlab::Themes.each.find { |t| t.id != Gitlab::Themes.default.id }
      scheme = Gitlab::ColorSchemes.each.find { |t| t.id != Gitlab::ColorSchemes.default.id }

      user.update!(theme_id: theme.id, color_scheme_id: scheme.id)

      put api("/users/#{user.id}", admin), params: {}

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.theme_id).to eq(theme.id)
      expect(user.reload.color_scheme_id).to eq(scheme.id)
    end

    it "does not update admin status" do
      admin_user = create(:admin)

      put api("/users/#{admin_user.id}", admin), params: { can_create_group: false }

      expect(response).to have_gitlab_http_status(:ok)
      expect(admin_user.reload.admin).to eq(true)
      expect(admin_user.can_create_group).to eq(false)
    end

    it "does not allow invalid update" do
      put api("/users/#{user.id}", admin), params: { email: 'invalid email' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(user.reload.email).not_to eq('invalid email')
    end

    it "updates theme id" do
      put api("/users/#{user.id}", admin), params: { theme_id: 5 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.theme_id).to eq(5)
    end

    it "does not update invalid theme id" do
      put api("/users/#{user.id}", admin), params: { theme_id: 50 }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(user.reload.theme_id).not_to eq(50)
    end

    it "updates color scheme id" do
      put api("/users/#{user.id}", admin), params: { color_scheme_id: 5 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.color_scheme_id).to eq(5)
    end

    it "does not update invalid color scheme id" do
      put api("/users/#{user.id}", admin), params: { color_scheme_id: 50 }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(user.reload.color_scheme_id).not_to eq(50)
    end

    context 'when the current user is not an admin' do
      it "is not available" do
        expect do
          put api("/users/#{user.id}", user), params: attributes_for(:user)
        end.not_to change { user.reload.attributes }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it "returns 404 for non-existing user" do
      put api("/users/0", admin), params: { bio: 'update should fail' }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 if invalid ID" do
      put api("/users/ASDF", admin)

      expect(response).to have_gitlab_http_status(:not_found)
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
      expect(response).to have_gitlab_http_status(:bad_request)
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

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 if external UID is missing for identity update' do
      put api("/users/#{omniauth_user.id}", admin), params: { provider: 'ldap' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context "with existing user" do
      before do
        post api("/users", admin), params: { email: 'test@example.com', password: 'password', username: 'test', name: 'test' }
        post api("/users", admin), params: { email: 'foo@bar.com', password: 'password', username: 'john', name: 'john' }
        @user = User.all.last
      end

      it 'returns 409 conflict error if email address exists' do
        put api("/users/#{@user.id}", admin), params: { email: 'test@example.com' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(@user.reload.email).to eq(@user.email)
      end

      it 'returns 409 conflict error if username taken' do
        @user_id = User.all.last.id
        put api("/users/#{@user.id}", admin), params: { username: 'test' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(@user.reload.username).to eq(@user.username)
      end

      it 'returns 409 conflict error if username taken (case insensitive)' do
        @user_id = User.all.last.id
        put api("/users/#{@user.id}", admin), params: { username: 'TEST' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(@user.reload.username).to eq(@user.username)
      end
    end
  end

  describe "PUT /user/:id/credit_card_validation" do
    let(:credit_card_validated_time) { Time.utc(2020, 1, 1) }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        put api("/user/#{user.id}/credit_card_validation"), params: { credit_card_validated_at: credit_card_validated_time }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as non-admin' do
      it "does not allow updating user's credit card validation", :aggregate_failures do
        put api("/user/#{user.id}/credit_card_validation", user), params: { credit_card_validated_at: credit_card_validated_time }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      it "updates user's credit card validation", :aggregate_failures do
        put api("/user/#{user.id}/credit_card_validation", admin), params: { credit_card_validated_at: credit_card_validated_time }

        expect(response).to have_gitlab_http_status(:ok)
        expect(user.reload.credit_card_validated_at).to eq(credit_card_validated_time)
      end

      it "returns 400 error if credit_card_validated_at is missing" do
        put api("/user/#{user.id}/credit_card_validation", admin), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 404 error if user not found' do
        put api("/user/#{non_existing_record_id}/credit_card_validation", admin), params: { credit_card_validated_at: credit_card_validated_time }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end
  end

  describe "DELETE /users/:id/identities/:provider" do
    let(:test_user) { create(:omniauth_user, provider: 'ldapmain') }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{test_user.id}/identities/ldapmain")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes identity of given provider' do
        expect do
          delete api("/users/#{test_user.id}/identities/ldapmain", admin)
        end.to change { test_user.identities.count }.by(-1)
        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/users/#{test_user.id}/identities/ldapmain", admin) }
      end

      it 'returns 404 error if user not found' do
        delete api("/users/0/identities/ldapmain", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if identity not found' do
        delete api("/users/#{test_user.id}/identities/saml", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Identity Not Found')
      end
    end
  end

  describe "POST /users/:id/keys" do
    it "does not create invalid ssh key" do
      post api("/users/#{user.id}/keys", admin), params: { title: "invalid key" }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create key without title' do
      post api("/users/#{user.id}/keys", admin), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('title is missing')
    end

    it "creates ssh key" do
      key_attrs = attributes_for :key
      expect do
        post api("/users/#{user.id}/keys", admin), params: key_attrs
      end.to change { user.keys.count }.by(1)
    end

    it 'creates SSH key with `expires_at` attribute' do
      optional_attributes = { expires_at: '2016-01-21T00:00:00.000Z' }
      attributes = attributes_for(:key).merge(optional_attributes)

      post api("/users/#{user.id}/keys", admin), params: attributes

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['expires_at']).to eq(optional_attributes[:expires_at])
    end

    it "returns 400 for invalid ID" do
      post api("/users/0/keys", admin)
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'GET /user/:id/keys' do
    it 'returns 404 for non-existing user' do
      get api("/users/#{non_existing_record_id}/keys")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of ssh keys' do
      user.keys << key

      get api("/users/#{user.id}/keys")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(key.title)
    end

    it 'returns array of ssh keys with comments replaced with'\
      'a simple identifier of username + hostname' do
      get api("/users/#{user.id}/keys")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array

      keys = json_response.map { |key_detail| key_detail['key'] }
      expect(keys).to all(include("#{user.name} (#{Gitlab.config.gitlab.host}"))
    end

    context 'N+1 queries' do
      before do
        get api("/users/#{user.id}/keys")
      end

      it 'avoids N+1 queries', :request_store do
        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api("/users/#{user.id}/keys")
        end.count

        create_list(:key, 2, user: user)

        expect do
          get api("/users/#{user.id}/keys")
        end.not_to exceed_all_query_limit(control_count)
      end
    end
  end

  describe 'GET /user/:user_id/keys' do
    it 'returns 404 for non-existing user' do
      get api("/users/#{non_existing_record_id}/keys")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of ssh keys' do
      user.keys << key

      get api("/users/#{user.username}/keys")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(key.title)
    end
  end

  describe 'DELETE /user/:id/keys/:key_id' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/keys/#{non_existing_record_id}")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes existing key' do
        user.keys << key

        expect do
          delete api("/users/#{user.id}/keys/#{key.id}", admin)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { user.keys.count }.by(-1)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/users/#{user.id}/keys/#{key.id}", admin) }
      end

      it 'returns 404 error if user not found' do
        user.keys << key

        delete api("/users/0/keys/#{key.id}", admin)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/keys/#{non_existing_record_id}", admin)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Key Not Found')
      end
    end
  end

  describe 'POST /users/:id/gpg_keys' do
    it 'does not create invalid GPG key' do
      post api("/users/#{user.id}/gpg_keys", admin)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'creates GPG key' do
      key_attrs = attributes_for :gpg_key, key: GpgHelpers::User2.public_key

      expect do
        post api("/users/#{user.id}/gpg_keys", admin), params: key_attrs

        expect(response).to have_gitlab_http_status(:created)
      end.to change { user.gpg_keys.count }.by(1)
    end

    it 'returns 400 for invalid ID' do
      post api('/users/0/gpg_keys', admin)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'GET /user/:id/gpg_keys' do
    it 'returns 404 for non-existing user' do
      get api('/users/0/gpg_keys')

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of GPG keys' do
      user.gpg_keys << gpg_key

      get api("/users/#{user.id}/gpg_keys")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['key']).to eq(gpg_key.key)
    end
  end

  describe 'GET /user/:id/gpg_keys/:key_id' do
    it 'returns 404 for non-existing user' do
      get api('/users/0/gpg_keys/1')

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns 404 for non-existing key' do
      get api("/users/#{user.id}/gpg_keys/0")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns a single GPG key' do
      user.gpg_keys << gpg_key

      get api("/users/#{user.id}/gpg_keys/#{gpg_key.id}")

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['key']).to eq(gpg_key.key)
    end
  end

  describe 'DELETE /user/:id/gpg_keys/:key_id' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/keys/#{non_existing_record_id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes existing key' do
        user.gpg_keys << gpg_key

        expect do
          delete api("/users/#{user.id}/gpg_keys/#{gpg_key.id}", admin)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { user.gpg_keys.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.keys << key

        delete api("/users/0/gpg_keys/#{gpg_key.id}", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/gpg_keys/#{non_existing_record_id}", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 GPG Key Not Found')
      end
    end
  end

  describe 'POST /user/:id/gpg_keys/:key_id/revoke' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/users/#{user.id}/gpg_keys/#{non_existing_record_id}/revoke")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'revokes existing key' do
        user.gpg_keys << gpg_key

        expect do
          post api("/users/#{user.id}/gpg_keys/#{gpg_key.id}/revoke", admin)

          expect(response).to have_gitlab_http_status(:accepted)
        end.to change { user.gpg_keys.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.gpg_keys << gpg_key

        post api("/users/0/gpg_keys/#{gpg_key.id}/revoke", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        post api("/users/#{user.id}/gpg_keys/#{non_existing_record_id}/revoke", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 GPG Key Not Found')
      end
    end
  end

  describe "POST /users/:id/emails" do
    it "does not create invalid email" do
      post api("/users/#{user.id}/emails", admin), params: {}

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('email is missing')
    end

    it "creates unverified email" do
      email_attrs = attributes_for :email
      expect do
        post api("/users/#{user.id}/emails", admin), params: email_attrs
      end.to change { user.emails.count }.by(1)

      expect(json_response['confirmed_at']).to be_nil
    end

    it "returns a 400 for invalid ID" do
      post api("/users/0/emails", admin)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "creates verified email" do
      email_attrs = attributes_for :email
      email_attrs[:skip_confirmation] = true

      post api("/users/#{user.id}/emails", admin), params: email_attrs

      expect(response).to have_gitlab_http_status(:created)

      expect(json_response['confirmed_at']).not_to be_nil
    end
  end

  describe 'GET /user/:id/emails' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/users/#{user.id}/emails")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get api('/users/0/emails', admin)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of emails' do
        user.emails << email

        get api("/users/#{user.id}/emails", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['email']).to eq(email.email)
      end

      it "returns a 404 for invalid ID" do
        get api("/users/ASDF/emails", admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /user/:id/emails/:email_id' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/emails/#{non_existing_record_id}")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes existing email' do
        user.emails << email

        expect do
          delete api("/users/#{user.id}/emails/#{email.id}", admin)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { user.emails.count }.by(-1)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/users/#{user.id}/emails/#{email.id}", admin) }
      end

      it 'returns 404 error if user not found' do
        user.emails << email

        delete api("/users/0/emails/#{email.id}", admin)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if email not foud' do
        delete api("/users/#{user.id}/emails/#{non_existing_record_id}", admin)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Email Not Found')
      end

      it "returns a 404 for invalid ID" do
        delete api("/users/ASDF/emails/bar", admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "DELETE /users/:id" do
    let_it_be(:issue) { create(:issue, author: user) }

    it "deletes user", :sidekiq_might_not_need_inline do
      namespace_id = user.namespace.id

      perform_enqueued_jobs { delete api("/users/#{user.id}", admin) }

      expect(response).to have_gitlab_http_status(:no_content)
      expect { User.find(user.id) }.to raise_error ActiveRecord::RecordNotFound
      expect { Namespace.find(namespace_id) }.to raise_error ActiveRecord::RecordNotFound
    end

    context "sole owner of a group" do
      let!(:group) { create(:group).tap { |group| group.add_owner(user) } }

      context "hard delete disabled" do
        it "does not delete user" do
          perform_enqueued_jobs { delete api("/users/#{user.id}", admin) }
          expect(response).to have_gitlab_http_status(:conflict)
        end
      end

      context "hard delete enabled" do
        it "delete user and group", :sidekiq_might_not_need_inline do
          perform_enqueued_jobs { delete api("/users/#{user.id}?hard_delete=true", admin) }
          expect(response).to have_gitlab_http_status(:no_content)
          expect(Group.exists?(group.id)).to be_falsy
        end
      end
    end

    it_behaves_like '412 response' do
      let(:request) { api("/users/#{user.id}", admin) }
    end

    it "does not delete for unauthenticated user" do
      perform_enqueued_jobs { delete api("/users/#{user.id}") }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "is not available for non admin users" do
      perform_enqueued_jobs { delete api("/users/#{user.id}", user) }
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it "returns 404 for non-existing user" do
      perform_enqueued_jobs { delete api("/users/0", admin) }
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      perform_enqueued_jobs { delete api("/users/ASDF", admin) }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context "hard delete disabled" do
      it "moves contributions to the ghost user", :sidekiq_might_not_need_inline do
        perform_enqueued_jobs { delete api("/users/#{user.id}", admin) }

        expect(response).to have_gitlab_http_status(:no_content)
        expect(issue.reload).to be_persisted
        expect(issue.author.ghost?).to be_truthy
      end
    end

    context "hard delete enabled" do
      it "removes contributions", :sidekiq_might_not_need_inline do
        perform_enqueued_jobs { delete api("/users/#{user.id}?hard_delete=true", admin) }

        expect(response).to have_gitlab_http_status(:no_content)
        expect(Issue.exists?(issue.id)).to be_falsy
      end
    end
  end

  describe "GET /user" do
    shared_examples 'get user info' do |version|
      context 'with regular user' do
        context 'with personal access token' do
          let(:personal_access_token) { create(:personal_access_token, user: user).token }

          it 'returns 403 without private token when sudo is defined' do
            get api("/user?private_token=#{personal_access_token}&sudo=123", version: version)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        it 'returns current user without private token when sudo not defined' do
          get api("/user", user, version: version)

          expect(response).to have_gitlab_http_status(:ok)
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

            expect(response).to have_gitlab_http_status(:forbidden)
          end

          it 'returns initial current user without private token but with is_admin when sudo not defined' do
            get api("/user?private_token=#{admin_personal_access_token}", version: version)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/user/admin')
            expect(json_response['id']).to eq(admin.id)
          end
        end
      end

      context 'with unauthenticated user' do
        it "returns 401 error if user is unauthenticated" do
          get api("/user", version: version)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    it_behaves_like 'get user info', 'v3'
    it_behaves_like 'get user info', 'v4'
  end

  describe "GET /user/preferences" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/preferences")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns user preferences" do
        user.user_preference.view_diffs_file_by_file = false
        user.user_preference.show_whitespace_in_diffs = true
        user.save!

        get api("/user/preferences", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["view_diffs_file_by_file"]).to eq(user.user_preference.view_diffs_file_by_file)
        expect(json_response["show_whitespace_in_diffs"]).to eq(user.user_preference.show_whitespace_in_diffs)
      end
    end
  end

  describe "GET /user/keys" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/keys")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns array of ssh keys" do
        user.keys << key

        get api("/user/keys", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first["title"]).to eq(key.title)
      end

      it 'returns array of ssh keys with comments replaced with'\
        'a simple identifier of username + hostname' do
        get api("/user/keys", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        keys = json_response.map { |key_detail| key_detail['key'] }
        expect(keys).to all(include("#{user.name} (#{Gitlab.config.gitlab.host}"))
      end

      context 'N+1 queries' do
        before do
          get api("/user/keys", user)
        end

        it 'avoids N+1 queries', :request_store do
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api("/user/keys", user)
          end.count

          create_list(:key, 2, user: user)

          expect do
            get api("/user/keys", user)
          end.not_to exceed_all_query_limit(control_count)
        end
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

      get api("/user/keys/#{key.id}", user)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response["title"]).to eq(key.title)
    end

    it 'exposes SSH key comment as a simple identifier of username + hostname' do
      get api("/user/keys/#{key.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['key']).to include("#{key.user_name} (#{Gitlab.config.gitlab.host})")
    end

    it "returns 404 Not Found within invalid ID" do
      get api("/user/keys/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 404 error if admin accesses user's ssh key" do
      user.keys << key
      admin

      get api("/user/keys/#{key.id}", admin)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/keys/ASDF", admin)

      expect(response).to have_gitlab_http_status(:not_found)
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
      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates SSH key with `expires_at` attribute' do
      optional_attributes = { expires_at: '2016-01-21T00:00:00.000Z' }
      attributes = attributes_for(:key).merge(optional_attributes)

      post api("/user/keys", user), params: attributes

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['expires_at']).to eq(optional_attributes[:expires_at])
    end

    it "returns a 401 error if unauthorized" do
      post api("/user/keys"), params: { title: 'some title', key: 'some key' }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "does not create ssh key without key" do
      post api("/user/keys", user), params: { title: 'title' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create ssh key without title' do
      post api('/user/keys', user), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('title is missing')
    end

    it "does not create ssh key without title" do
      post api("/user/keys", user), params: { key: "somekey" }
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe "DELETE /user/keys/:key_id" do
    it "deletes existed key" do
      user.keys << key

      expect do
        delete api("/user/keys/#{key.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { user.keys.count }.by(-1)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/user/keys/#{key.id}", user) }
    end

    it "returns 404 if key ID not found" do
      delete api("/user/keys/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.keys << key

      delete api("/user/keys/#{key.id}")
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "returns a 404 for invalid ID" do
      delete api("/users/keys/ASDF", admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /user/gpg_keys' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/user/gpg_keys')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns array of GPG keys' do
        user.gpg_keys << gpg_key

        get api('/user/gpg_keys', user)

        expect(response).to have_gitlab_http_status(:ok)
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

      get api("/user/gpg_keys/#{gpg_key.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['key']).to eq(gpg_key.key)
    end

    it 'returns 404 Not Found within invalid ID' do
      get api("/user/gpg_keys/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it "returns 404 error if admin accesses user's GPG key" do
      user.gpg_keys << gpg_key

      get api("/user/gpg_keys/#{gpg_key.id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns 404 for invalid ID' do
      get api('/users/gpg_keys/ASDF', admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'scopes' do
      let(:path) { "/user/gpg_keys/#{gpg_key.id}" }
      let(:api_call) { method(:api) }

      include_examples 'allows the "read_user" scope'
    end
  end

  describe 'POST /user/gpg_keys' do
    it 'creates a GPG key' do
      key_attrs = attributes_for :gpg_key, key: GpgHelpers::User2.public_key

      expect do
        post api('/user/gpg_keys', user), params: key_attrs

        expect(response).to have_gitlab_http_status(:created)
      end.to change { user.gpg_keys.count }.by(1)
    end

    it 'returns a 401 error if unauthorized' do
      post api('/user/gpg_keys'), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'does not create GPG key without key' do
      post api('/user/gpg_keys', user)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end
  end

  describe 'POST /user/gpg_keys/:key_id/revoke' do
    it 'revokes existing GPG key' do
      user.gpg_keys << gpg_key

      expect do
        post api("/user/gpg_keys/#{gpg_key.id}/revoke", user)

        expect(response).to have_gitlab_http_status(:accepted)
      end.to change { user.gpg_keys.count }.by(-1)
    end

    it 'returns 404 if key ID not found' do
      post api("/user/gpg_keys/#{non_existing_record_id}/revoke", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns 401 error if unauthorized' do
      user.gpg_keys << gpg_key

      post api("/user/gpg_keys/#{gpg_key.id}/revoke")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 404 for invalid ID' do
      post api('/users/gpg_keys/ASDF/revoke', admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'DELETE /user/gpg_keys/:key_id' do
    it 'deletes existing GPG key' do
      user.gpg_keys << gpg_key

      expect do
        delete api("/user/gpg_keys/#{gpg_key.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { user.gpg_keys.count }.by(-1)
    end

    it 'returns 404 if key ID not found' do
      delete api("/user/gpg_keys/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns 401 error if unauthorized' do
      user.gpg_keys << gpg_key

      delete api("/user/gpg_keys/#{gpg_key.id}")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 404 for invalid ID' do
      delete api('/users/gpg_keys/ASDF', admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /user/emails" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/emails")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns array of emails" do
        user.emails << email

        get api("/user/emails", user)

        expect(response).to have_gitlab_http_status(:ok)
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

      get api("/user/emails/#{email.id}", user)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response["email"]).to eq(email.email)
    end

    it "returns 404 Not Found within invalid ID" do
      get api("/user/emails/#{non_existing_record_id}", user)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 404 error if admin accesses user's email" do
      user.emails << email
      admin

      get api("/user/emails/#{email.id}", admin)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/emails/ASDF", admin)

      expect(response).to have_gitlab_http_status(:not_found)
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
      expect(response).to have_gitlab_http_status(:created)
    end

    it "returns a 401 error if unauthorized" do
      post api("/user/emails"), params: { email: 'some email' }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "does not create email with invalid email" do
      post api("/user/emails", user), params: {}

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('email is missing')
    end
  end

  describe "DELETE /user/emails/:email_id" do
    it "deletes existed email" do
      user.emails << email

      expect do
        delete api("/user/emails/#{email.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { user.emails.count }.by(-1)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/user/emails/#{email.id}", user) }
    end

    it "returns 404 if email ID not found" do
      delete api("/user/emails/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.emails << email

      delete api("/user/emails/#{email.id}")
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "returns 400 for invalid ID" do
      delete api("/user/emails/ASDF", admin)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'activate and deactivate' do
    shared_examples '404' do
      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end

    describe 'POST /users/:id/activate' do
      subject(:activate) { post api("/users/#{user_id}/activate", api_user) }

      let(:user_id) { user.id }

      context 'performed by a non-admin user' do
        let(:api_user) { user }

        it 'is not authorized to perform the action' do
          activate

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'performed by an admin user' do
        let(:api_user) { admin }

        context 'for a deactivated user' do
          before do
            user.deactivate
          end

          it 'activates a deactivated user' do
            activate

            expect(response).to have_gitlab_http_status(:created)
            expect(user.reload.state).to eq('active')
          end
        end

        context 'for an active user' do
          before do
            user.activate
          end

          it 'returns 201' do
            activate

            expect(response).to have_gitlab_http_status(:created)
            expect(user.reload.state).to eq('active')
          end
        end

        context 'for a blocked user' do
          before do
            user.block
          end

          it 'returns 403' do
            activate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('403 Forbidden - A blocked user must be unblocked to be activated')
            expect(user.reload.state).to eq('blocked')
          end
        end

        context 'for a ldap blocked user' do
          before do
            user.ldap_block
          end

          it 'returns 403' do
            activate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('403 Forbidden - A blocked user must be unblocked to be activated')
            expect(user.reload.state).to eq('ldap_blocked')
          end
        end

        context 'for a user that does not exist' do
          let(:user_id) { 0 }

          before do
            activate
          end

          it_behaves_like '404'
        end
      end
    end

    describe 'POST /users/:id/deactivate' do
      subject(:deactivate) { post api("/users/#{user_id}/deactivate", api_user) }

      let(:user_id) { user.id }

      context 'performed by a non-admin user' do
        let(:api_user) { user }

        it 'is not authorized to perform the action' do
          deactivate

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'performed by an admin user' do
        let(:api_user) { admin }

        context 'for an active user' do
          let(:activity) { {} }
          let(:user) { create(:user, **activity) }

          context 'with no recent activity' do
            let(:activity) { { last_activity_on: ::User::MINIMUM_INACTIVE_DAYS.next.days.ago } }

            it 'deactivates an active user' do
              deactivate

              expect(response).to have_gitlab_http_status(:created)
              expect(user.reload.state).to eq('deactivated')
            end
          end

          context 'with recent activity' do
            let(:activity) { { last_activity_on: ::User::MINIMUM_INACTIVE_DAYS.pred.days.ago } }

            it 'does not deactivate an active user' do
              deactivate

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(json_response['message']).to eq("403 Forbidden - The user you are trying to deactivate has been active in the past #{::User::MINIMUM_INACTIVE_DAYS} days and cannot be deactivated")
              expect(user.reload.state).to eq('active')
            end
          end
        end

        context 'for a deactivated user' do
          before do
            user.deactivate
          end

          it 'returns 201' do
            deactivate

            expect(response).to have_gitlab_http_status(:created)
            expect(user.reload.state).to eq('deactivated')
          end
        end

        context 'for a blocked user' do
          before do
            user.block
          end

          it 'returns 403' do
            deactivate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('403 Forbidden - A blocked user cannot be deactivated by the API')
            expect(user.reload.state).to eq('blocked')
          end
        end

        context 'for a ldap blocked user' do
          before do
            user.ldap_block
          end

          it 'returns 403' do
            deactivate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('403 Forbidden - A blocked user cannot be deactivated by the API')
            expect(user.reload.state).to eq('ldap_blocked')
          end
        end

        context 'for an internal user' do
          let(:user) { User.alert_bot }

          it 'returns 403' do
            deactivate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('403 Forbidden - An internal user cannot be deactivated by the API')
          end
        end

        context 'for a user that does not exist' do
          let(:user_id) { 0 }

          before do
            deactivate
          end

          it_behaves_like '404'
        end
      end
    end
  end

  context 'approve pending user' do
    shared_examples '404' do
      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end

    describe 'POST /users/:id/approve' do
      subject(:approve) { post api("/users/#{user_id}/approve", api_user) }

      let_it_be(:pending_user) { create(:user, :blocked_pending_approval) }
      let_it_be(:deactivated_user) { create(:user, :deactivated) }
      let_it_be(:blocked_user) { create(:user, :blocked) }

      context 'performed by a non-admin user' do
        let(:api_user) { user }
        let(:user_id) { pending_user.id }

        it 'is not authorized to perform the action' do
          expect { approve }.not_to change { pending_user.reload.state }
          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You are not allowed to approve a user')
        end
      end

      context 'performed by an admin user' do
        let(:api_user) { admin }

        context 'for a deactivated user' do
          let(:user_id) { deactivated_user.id }

          it 'does not approve a deactivated user' do
            expect { approve }.not_to change { deactivated_user.reload.state }
            expect(response).to have_gitlab_http_status(:conflict)
            expect(json_response['message']).to eq('The user you are trying to approve is not pending approval')
          end
        end

        context 'for an pending approval user' do
          let(:user_id) { pending_user.id }

          it 'returns 201' do
            expect { approve }.to change { pending_user.reload.state }.to('active')
            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['message']).to eq('Success')
          end
        end

        context 'for an active user' do
          let(:user_id) { user.id }

          it 'returns 201' do
            expect { approve }.not_to change { user.reload.state }
            expect(response).to have_gitlab_http_status(:conflict)
            expect(json_response['message']).to eq('The user you are trying to approve is not pending approval')
          end
        end

        context 'for a blocked user' do
          let(:user_id) { blocked_user.id }

          it 'returns 403' do
            expect { approve }.not_to change { blocked_user.reload.state }
            expect(response).to have_gitlab_http_status(:conflict)
            expect(json_response['message']).to eq('The user you are trying to approve is not pending approval')
          end
        end

        context 'for a ldap blocked user' do
          let(:user_id) { ldap_blocked_user.id }

          it 'returns 403' do
            expect { approve }.not_to change { ldap_blocked_user.reload.state }
            expect(response).to have_gitlab_http_status(:conflict)
            expect(json_response['message']).to eq('The user you are trying to approve is not pending approval')
          end
        end

        context 'for a user that does not exist' do
          let(:user_id) { non_existing_record_id }

          before do
            approve
          end

          it_behaves_like '404'
        end
      end
    end
  end

  describe 'POST /users/:id/block' do
    let(:blocked_user) { create(:user, state: 'blocked') }

    it 'blocks existing user' do
      post api("/users/#{user.id}/block", admin)

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:created)
        expect(response.body).to eq('true')
        expect(user.reload.state).to eq('blocked')
      end
    end

    it 'does not re-block ldap blocked users' do
      post api("/users/#{ldap_blocked_user.id}/block", admin)
      expect(response).to have_gitlab_http_status(:forbidden)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      post api("/users/#{user.id}/block", user)
      expect(response).to have_gitlab_http_status(:forbidden)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      post api('/users/0/block', admin)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error if user is internal' do
      internal_user = create(:user, :bot)

      post api("/users/#{internal_user.id}/block", admin)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('An internal user cannot be blocked')
    end

    it 'returns a 201 if user is already blocked' do
      post api("/users/#{blocked_user.id}/block", admin)

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:created)
        expect(response.body).to eq('null')
      end
    end
  end

  describe 'POST /users/:id/unblock' do
    let(:blocked_user) { create(:user, state: 'blocked') }
    let(:deactivated_user) { create(:user, state: 'deactivated') }

    it 'unblocks existing user' do
      post api("/users/#{user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(:created)
      expect(user.reload.state).to eq('active')
    end

    it 'unblocks a blocked user' do
      post api("/users/#{blocked_user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(:created)
      expect(blocked_user.reload.state).to eq('active')
    end

    it 'does not unblock ldap blocked users' do
      post api("/users/#{ldap_blocked_user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(:forbidden)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not unblock deactivated users' do
      post api("/users/#{deactivated_user.id}/unblock", admin)
      expect(response).to have_gitlab_http_status(:forbidden)
      expect(deactivated_user.reload.state).to eq('deactivated')
    end

    it 'is not available for non admin users' do
      post api("/users/#{user.id}/unblock", user)
      expect(response).to have_gitlab_http_status(:forbidden)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      post api('/users/0/block', admin)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      post api("/users/ASDF/block", admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /users/:id/memberships" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }

    let(:requesting_user) { create(:user) }

    before_all do
      project.add_guest(user)
      group.add_guest(user)
    end

    it "responses with 403" do
      get api("/users/#{user.id}/memberships", requesting_user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'requested by admin user' do
      let(:requesting_user) { create(:user, :admin) }

      it "responses successfully" do
        get api("/users/#{user.id}/memberships", requesting_user)

        aggregate_failures 'expect successful response including groups and projects' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/memberships')
          expect(response).to include_pagination_headers
          expect(json_response).to contain_exactly(
            a_hash_including('source_type' => 'Project'),
            a_hash_including('source_type' => 'Namespace')
          )
        end
      end

      it 'does not submit N+1 DB queries' do
        # Avoid setup queries
        get api("/users/#{user.id}/memberships", requesting_user)

        control = ActiveRecord::QueryRecorder.new do
          get api("/users/#{user.id}/memberships", requesting_user)
        end

        create_list(:project, 5).map { |project| project.add_guest(user) }

        expect do
          get api("/users/#{user.id}/memberships", requesting_user)
        end.not_to exceed_query_limit(control)
      end

      context 'with type filter' do
        it "only returns project memberships" do
          get api("/users/#{user.id}/memberships?type=Project", requesting_user)

          aggregate_failures do
            expect(json_response).to contain_exactly(a_hash_including('source_type' => 'Project'))
            expect(json_response).not_to include(a_hash_including('source_type' => 'Namespace'))
          end
        end

        it "only returns group memberships" do
          get api("/users/#{user.id}/memberships?type=Namespace", requesting_user)

          aggregate_failures do
            expect(json_response).to contain_exactly(a_hash_including('source_type' => 'Namespace'))
            expect(json_response).not_to include(a_hash_including('source_type' => 'Project'))
          end
        end

        it "recognizes unsupported types" do
          get api("/users/#{user.id}/memberships?type=foo", requesting_user)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  context "user activities", :clean_gitlab_redis_shared_state do
    let_it_be(:old_active_user) { create(:user, last_activity_on: Time.utc(2000, 1, 1)) }
    let_it_be(:newly_active_user) { create(:user, last_activity_on: 2.days.ago.midday) }

    context 'last activity as normal user' do
      it 'has no permission' do
        get api("/user/activities", user)

        expect(response).to have_gitlab_http_status(:forbidden)
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

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['emoji']).to be_present
    end

    it 'deletes the status when passing empty values' do
      put api('/user/status', user)

      expect(response).to have_gitlab_http_status(:success)
      expect(user.reload.status).to be_nil
    end

    context 'when clear_status_after is given' do
      it 'sets the clear_status_at column' do
        freeze_time do
          expected_clear_status_at = 3.hours.from_now

          put api('/user/status', user), params: { emoji: 'smirk', message: 'hello world', clear_status_after: '3_hours' }

          expect(response).to have_gitlab_http_status(:success)
          expect(user.status.reload.clear_status_at).to be_within(1.minute).of(expected_clear_status_at)
          expect(Time.parse(json_response["clear_status_at"])).to be_within(1.minute).of(expected_clear_status_at)
        end
      end

      it 'unsets the clear_status_at column' do
        user.create_status!(clear_status_at: 5.hours.ago)

        put api('/user/status', user), params: { emoji: 'smirk', message: 'hello world', clear_status_after: nil }

        expect(response).to have_gitlab_http_status(:success)
        expect(user.status.reload.clear_status_at).to be_nil
      end

      it 'raises error when unknown status value is given' do
        put api('/user/status', user), params: { emoji: 'smirk', message: 'hello world', clear_status_after: 'wrong' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'POST /users/:user_id/personal_access_tokens' do
    let(:name) { 'new pat' }
    let(:expires_at) { 3.days.from_now.to_date.to_s }
    let(:scopes) { %w(api read_user) }

    it 'returns error if required attributes are missing' do
      post api("/users/#{user.id}/personal_access_tokens", admin)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('name is missing, scopes is missing, scopes does not have a valid value')
    end

    it 'returns a 404 error if user not found' do
      post api("/users/#{non_existing_record_id}/personal_access_tokens", admin),
        params: {
          name: name,
          scopes: scopes,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 401 error when not authenticated' do
      post api("/users/#{user.id}/personal_access_tokens"),
        params: {
          name: name,
          scopes: scopes,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(json_response['message']).to eq('401 Unauthorized')
    end

    it 'returns a 403 error when authenticated as normal user' do
      post api("/users/#{user.id}/personal_access_tokens", user),
        params: {
          name: name,
          scopes: scopes,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'creates a personal access token when authenticated as admin' do
      post api("/users/#{user.id}/personal_access_tokens", admin),
        params: {
          name: name,
          expires_at: expires_at,
          scopes: scopes
        }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(name)
      expect(json_response['scopes']).to eq(scopes)
      expect(json_response['expires_at']).to eq(expires_at)
      expect(json_response['id']).to be_present
      expect(json_response['created_at']).to be_present
      expect(json_response['active']).to be_truthy
      expect(json_response['revoked']).to be_falsey
      expect(json_response['token']).to be_present
    end

    context 'when an error is thrown by the model' do
      let!(:admin_personal_access_token) { create(:personal_access_token, user: admin) }
      let(:error_message) { 'error message' }

      before do
        allow_next_instance_of(PersonalAccessToken) do |personal_access_token|
          allow(personal_access_token).to receive_message_chain(:errors, :full_messages)
                                            .and_return([error_message])

          allow(personal_access_token).to receive(:save).and_return(false)
        end
      end

      it 'returns the error' do
        post api("/users/#{user.id}/personal_access_tokens", personal_access_token: admin_personal_access_token),
          params: {
            name: name,
            expires_at: expires_at,
            scopes: scopes
          }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq(error_message)
      end
    end
  end

  describe 'GET /users/:user_id/impersonation_tokens' do
    let_it_be(:active_personal_access_token) { create(:personal_access_token, user: user) }
    let_it_be(:revoked_personal_access_token) { create(:personal_access_token, :revoked, user: user) }
    let_it_be(:expired_personal_access_token) { create(:personal_access_token, :expired, user: user) }
    let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let_it_be(:revoked_impersonation_token) { create(:personal_access_token, :impersonation, :revoked, user: user) }

    it 'returns a 404 error if user not found' do
      get api("/users/#{non_existing_record_id}/impersonation_tokens", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api("/users/#{non_existing_record_id}/impersonation_tokens", user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns an array of all impersonated tokens' do
      get api("/users/#{user.id}/impersonation_tokens", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
    end

    it 'returns an array of active impersonation tokens if state active' do
      get api("/users/#{user.id}/impersonation_tokens?state=active", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response).to all(include('active' => true))
    end

    it 'returns an array of inactive personal access tokens if active is set to false' do
      get api("/users/#{user.id}/impersonation_tokens?state=inactive", admin)

      expect(response).to have_gitlab_http_status(:ok)
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

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns a 404 error if user not found' do
      post api("/users/#{non_existing_record_id}/impersonation_tokens", admin),
        params: {
          name: name,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      post api("/users/#{user.id}/impersonation_tokens", user),
        params: {
          name: name,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(:forbidden)
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

      expect(response).to have_gitlab_http_status(:created)
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
    let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
    let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

    it 'returns 404 error if user not found' do
      get api("/users/#{non_existing_record_id}/impersonation_tokens/1", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      get api("/users/#{user.id}/impersonation_tokens/#{non_existing_record_id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      get api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns an impersonation token' do
      get api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['token']).not_to be_present
      expect(json_response['impersonation']).to be_truthy
    end
  end

  describe 'DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id' do
    let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
    let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

    it 'returns a 404 error if user not found' do
      delete api("/users/#{non_existing_record_id}/impersonation_tokens/1", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      delete api("/users/#{user.id}/impersonation_tokens/#{non_existing_record_id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      delete api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      delete api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it_behaves_like '412 response' do
      let(:request) { api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin) }
    end

    it 'revokes a impersonation token' do
      delete api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(impersonation_token.revoked).to be_falsey
      expect(impersonation_token.reload.revoked).to be_truthy
    end
  end

  it_behaves_like 'custom attributes endpoints', 'users' do
    let(:attributable) { user }
    let(:other_attributable) { admin }
  end
end
