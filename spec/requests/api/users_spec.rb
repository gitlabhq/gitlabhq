# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Users, :with_current_organization, :aggregate_failures, feature_category: :user_management do
  include WorkhorseHelpers
  include KeysetPaginationHelpers
  include CryptoHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user, reload: true) { create(:user, username: 'user.withdot') }
  let_it_be(:key) { create(:key, user: user) }
  let_it_be(:gpg_key) { create(:gpg_key, user: user) }
  let_it_be(:email) { create(:email, user: user) }
  let_it_be(:organization) { create(:organization) }

  let(:blocked_user) { create(:user, :blocked) }
  let(:omniauth_user) { create(:omniauth_user) }
  let(:ldap_user) { create(:omniauth_user, provider: 'ldapmain') }
  let(:ldap_blocked_user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }
  let(:private_user) { create(:user, private_profile: true) }
  let(:deactivated_user) { create(:user, state: 'deactivated') }
  let(:banned_user) { create(:user, :banned) }
  let(:internal_user) { create(:user, :bot) }
  let(:user_with_2fa) { create(:user, :two_factor_via_otp) }
  let(:admin_with_2fa) { create(:admin, :two_factor_via_otp) }
  let(:user_without_pin) { create(:user) }

  context 'admin notes' do
    let_it_be(:admin) { create(:admin, note: '2019-10-06 | 2FA added | user requested | www.gitlab.com') }
    let_it_be(:user, reload: true) { create(:user, note: '2018-11-05 | 2FA removed | user requested | www.gitlab.com') }

    describe 'POST /users' do
      let(:path) { '/users' }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:params) { attributes_for(:user).merge({ note: 'Awesome Note' }) }
      end

      context 'when unauthenticated' do
        it 'return authentication error' do
          post api(path)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when authenticated' do
        context 'as an admin' do
          it 'contains the note of the user' do
            optional_attributes = { note: 'Awesome Note' }
            attributes = attributes_for(:user).merge(optional_attributes)

            post api(path, admin, admin_mode: true), params: attributes

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['note']).to eq(optional_attributes[:note])
          end
        end

        context 'as a regular user' do
          it 'does not allow creating new user' do
            post api(path, user), params: attributes_for(:user)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end

    describe "PUT /users/:id" do
      let(:path) { "/users/#{user.id}" }

      it_behaves_like 'PUT request permissions for admin mode' do
        let(:params) { { note: 'new note' } }
      end

      context 'when user is an admin' do
        it "updates note of the user" do
          new_note = '2019-07-07 | Email changed | user requested | www.gitlab.com'

          expect do
            put api(path, admin, admin_mode: true), params: { note: new_note }
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
            put api(path, user), params: { note: 'new note' }
          end.not_to change { user.reload.note }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    describe "PATCH /users/:id/disable_two_factor" do
      context "when current user is an admin" do
        it "returns a 204 when 2FA is disabled for the target user" do
          expect do
            patch api("/users/#{user_with_2fa.id}/disable_two_factor", admin, admin_mode: true)
          end.to change { user_with_2fa.reload.two_factor_enabled? }
                  .from(true)
                  .to(false)
          expect(response).to have_gitlab_http_status(:no_content)
        end

        it "uses TwoFactor Destroy Service" do
          destroy_service = instance_double(TwoFactor::DestroyService, execute: nil)
          expect(TwoFactor::DestroyService).to receive(:new)
            .with(admin, user: user_with_2fa)
            .and_return(destroy_service)
          expect(destroy_service).to receive(:execute)

          patch api("/users/#{user_with_2fa.id}/disable_two_factor", admin, admin_mode: true)
        end

        it "returns a 400 if 2FA is not enabled for the target user" do
          expect(TwoFactor::DestroyService).to receive(:new).and_call_original

          expect do
            patch api("/users/#{user.id}/disable_two_factor", admin, admin_mode: true)
          end.not_to change { user.reload.two_factor_enabled? }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("400 Bad request - Two-factor authentication is not enabled for this user")
        end

        it "returns a 403 if the target user is an admin" do
          expect(TwoFactor::DestroyService).not_to receive(:new)

          expect do
            patch api("/users/#{admin_with_2fa.id}/disable_two_factor", admin, admin_mode: true)
          end.not_to change { admin_with_2fa.reload.two_factor_enabled? }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq("403 Forbidden - Two-factor authentication for admins cannot be disabled via the API. Use the Rails console")
        end

        it "returns a 404 if the target user cannot be found" do
          expect(TwoFactor::DestroyService).not_to receive(:new)

          patch api("/users/#{non_existing_record_id}/disable_two_factor", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq("404 User Not Found")
        end
      end

      context "when current user is not an admin" do
        it "returns a 403" do
          expect do
            patch api("/users/#{user_with_2fa.id}/disable_two_factor", user)
          end.not_to change { user_with_2fa.reload.two_factor_enabled? }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq("403 Forbidden")
        end
      end

      context "when unauthenticated" do
        it "returns a 401" do
          patch api("/users/#{user_with_2fa.id}/disable_two_factor")

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    describe 'GET /users/' do
      let(:path) { '/users' }

      context 'when unauthenticated' do
        it "does not contain certain fields" do
          get api(path), params: { username: user.username }

          expect(json_response.first).not_to have_key('note')
          expect(json_response.first).not_to have_key('namespace_id')
          expect(json_response.first).not_to have_key('created_by')
          expect(json_response.first).not_to have_key('email_reset_offered_at')
        end
      end

      context 'when authenticated' do
        context 'as a regular user' do
          it 'does not contain certain fields' do
            get api(path, user), params: { username: user.username }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.first).not_to have_key('note')
            expect(json_response.first).not_to have_key('namespace_id')
            expect(json_response.first).not_to have_key('created_by')
            expect(json_response.first).not_to have_key('email_reset_offered_at')
          end
        end

        context 'as an admin' do
          it 'contains the note of users' do
            get api(path, admin, admin_mode: true), params: { username: user.username }

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response.first).to have_key('note')
            expect(json_response.first).to have_key('email_reset_offered_at')
            expect(json_response.first['note']).to eq '2018-11-05 | 2FA removed | user requested | www.gitlab.com'
          end

          context 'with `created_by` details' do
            it 'has created_by as nil with a self-registered account' do
              get api(path, admin, admin_mode: true), params: { username: user.username }

              expect(response).to have_gitlab_http_status(:success)
              expect(json_response.first).to have_key('created_by')
              expect(json_response.first['created_by']).to eq(nil)
            end

            it 'is created_by a user and has those details' do
              created = create(:user, created_by_id: user.id)

              get api(path, admin, admin_mode: true), params: { username: created.username }

              expect(response).to have_gitlab_http_status(:success)
              expect(json_response.first['created_by'].symbolize_keys)
                .to eq(API::Entities::UserBasic.new(user).as_json)
            end
          end
        end

        context 'with search parameter' do
          let_it_be(:first_user) { create(:user, username: 'a-user') }
          let_it_be(:second_user) { create(:user, username: 'a-user2') }

          it 'prioritizes username match' do
            get api(path, user, admin_mode: true), params: { search: first_user.username }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.first['username']).to eq('a-user')
            expect(json_response.second['username']).to eq('a-user2')
          end

          it 'preserves requested ordering with order_by and sort', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/500623' do
            get api(path, user, admin_mode: true), params: { search: first_user.username, order_by: 'name', sort: 'desc' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.first['username']).to eq('a-user2')
            expect(json_response.second['username']).to eq('a-user')
          end

          it 'preserves requested ordering with sort' do
            get api(path, user, admin_mode: true), params: { search: first_user.username, sort: 'desc' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.first['username']).to eq('a-user2')
            expect(json_response.second['username']).to eq('a-user')
          end
        end

        context 'N+1 queries' do
          before do
            create_list(:user, 2)
          end

          it 'avoids N+1 queries when requested by admin' do
            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              get api(path, admin)
            end

            create_list(:user, 3)

            # There is a still a pending N+1 query related to fetching
            # project count for each user.
            # Refer issue https://gitlab.com/gitlab-org/gitlab/-/issues/367080

            expect do
              get api(path, admin)
            end.not_to exceed_all_query_limit(control).with_threshold(3)
          end

          it 'avoids N+1 queries when requested by a regular user' do
            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              get api(path, user)
            end

            create_list(:user, 3)

            expect do
              get api(path, user)
            end.not_to exceed_all_query_limit(control)
          end
        end

        it_behaves_like 'an endpoint with keyset pagination', invalid_order: nil do
          let(:first_record) { user }
          let(:second_record) { admin }
          let(:api_call) { api(path, user) }
        end

        it 'still supports offset pagination when keyset pagination params are not provided' do
          get api(path, user)

          expect(response).to include_pagination_headers
        end
      end
    end

    describe 'GET /user' do
      let(:path) { '/user' }

      context 'when authenticated' do
        context 'as an admin' do
          context 'accesses their own profile' do
            it 'contains the note of the user' do
              get api(path, admin, admin_mode: true)

              expect(json_response).to have_key('note')
              expect(json_response['note']).to eq(admin.note)
            end
          end

          context 'sudo' do
            let(:admin_personal_access_token) { create(:personal_access_token, :admin_mode, user: admin, scopes: %w[api sudo]).token }

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
            get api(path, user)

            expect(json_response).not_to have_key('note')
            expect(json_response).not_to have_key('namespace_id')
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
    let(:path) { '/users' }

    context "when unauthenticated" do
      it "returns authorization error when the `username` parameter is not passed" do
        get api(path)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it "returns the user when a valid `username` parameter is passed" do
        get api(path), params: { username: user.username }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.size).to eq(1)
        expect(json_response[0]['id']).to eq(user.id)
        expect(json_response[0]['username']).to eq(user.username)
      end

      it "returns the user when a valid `username` parameter is passed (case insensitive)" do
        get api(path), params: { username: user.username.upcase }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.size).to eq(1)
        expect(json_response[0]['id']).to eq(user.id)
        expect(json_response[0]['username']).to eq(user.username)
      end

      it "returns an empty response when an invalid `username` parameter is passed" do
        get api(path), params: { username: 'invalid' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(0)
      end

      it "does not return the highest role" do
        get api(path), params: { username: user.username }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'highest_role'
      end

      it "does not return the current or last sign-in ip addresses" do
        get api(path), params: { username: user.username }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'current_sign_in_ip'
        expect(json_response.first.keys).not_to include 'last_sign_in_ip'
      end

      context "when public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it "returns authorization error when the `username` parameter refers to an inaccessible user" do
          get api(path), params: { username: user.username }

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it "returns authorization error when the `username` parameter is not passed" do
          get api(path)

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
            get api(path, user)

            expect(response).to match_response_schema('public_api/v4/user/basics')
          end
        end

        context 'when authenticate as an admin' do
          it "renders 200" do
            get api(path, admin)

            expect(response).to match_response_schema('public_api/v4/user/basics')
          end
        end
      end

      it "returns an array of users" do
        get api(path, user)

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

      it "returns an array of human users" do
        internal_user

        get api("/users?humans=true", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(2)
        expect(json_response).to contain_exactly(
          hash_including('id' => user.id),
          hash_including('id' => admin.id)
        )
      end

      it "returns an array of non human users" do
        internal_user

        get api("/users?exclude_humans=true", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(1)
        expect(json_response).to contain_exactly(
          hash_including('id' => internal_user.id)
        )
      end

      it "returns active users" do
        blocked_user
        banned_user

        get api("/users?active=true", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(2)
        expect(json_response).to contain_exactly(
          hash_including('id' => user.id),
          hash_including('id' => admin.id)
        )
      end

      it "returns an array of non-active users" do
        deactivated_user

        get api("/users?exclude_active=true", user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(1)
        expect(json_response).to contain_exactly(
          hash_including('id' => deactivated_user.id)
        )
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
        get api(path, user)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.first.keys).not_to include 'is_admin'
      end
    end

    context "when admin" do
      context 'exclude_internal param' do
        let_it_be(:internal_user) { Users::Internal.alert_bot }

        it 'returns all users when it is not set' do
          get api("/users?exclude_internal=false", admin)

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

      context 'without_project_bots param' do
        let_it_be(:project_bot) { create(:user, :project_bot) }

        it 'returns all users when it is not set' do
          get api("/users?without_project_bots=false", user)

          expect(response).to match_response_schema('public_api/v4/user/basics')
          expect(response).to include_pagination_headers
          expect(json_response.map { |u| u['id'] }).to include(project_bot.id)
        end

        it 'returns all non project_bot users when it is set' do
          get api("/users?without_project_bots=true", user)

          expect(response).to match_response_schema('public_api/v4/user/basics')
          expect(response).to include_pagination_headers
          expect(json_response.map { |u| u['id'] }).not_to include(project_bot.id)
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
          admin_personal_access_token = create(:personal_access_token, :admin_mode, user: admin, scopes: [:sudo])
          get api("/users?sudo=#{user.id}", admin, personal_access_token: admin_personal_access_token)

          expect(response).to have_gitlab_http_status(:success)
        end
      end

      it "returns an array of users" do
        get api(path, admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(response).to include_pagination_headers
      end

      it "users contain the `namespace_id` field" do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(2)
        expect(json_response.map { |u| u['namespace_id'] }).to include(user.namespace_id, admin.namespace_id)
      end

      it "returns an array of external users" do
        create(:user, external: true)

        get api("/users?external=true", admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(response).to include_pagination_headers
        expect(json_response).to all(include('external' => true))
      end

      it "returns one user by external UID" do
        get api("/users?extern_uid=#{omniauth_user.identities.first.extern_uid}&provider=#{omniauth_user.identities.first.provider}", admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['username']).to eq(omniauth_user.username)
      end

      it "returns 400 error if provider with no extern_uid" do
        get api("/users?extern_uid=#{omniauth_user.identities.first.extern_uid}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns 400 error if provider with no extern_uid" do
        get api("/users?provider=#{omniauth_user.identities.first.provider}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns a user created before a specific date" do
        user = create(:user, created_at: Date.new(2000, 1, 1))

        get api("/users?created_before=2000-01-02T00:00:00.060Z", admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['username']).to eq(user.username)
      end

      it "returns no users created before a specific date" do
        create(:user, created_at: Date.new(2001, 1, 1))

        get api("/users?created_before=2000-01-02T00:00:00.060Z", admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(0)
      end

      it "returns users created before and after a specific date" do
        user = create(:user, created_at: Date.new(2001, 1, 1))

        get api("/users?created_before=2001-01-02T00:00:00.060Z&created_after=1999-01-02T00:00:00.060", admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['username']).to eq(user.username)
      end

      it 'returns the correct order when sorted by id' do
        # order of let_it_be definitions:
        # - admin
        # - user

        get api(path, admin, admin_mode: true), params: { order_by: 'id', sort: 'asc' }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(2)
        expect(json_response.first['id']).to eq(admin.id)
        expect(json_response.last['id']).to eq(user.id)
      end

      it 'returns users with 2fa enabled' do
        user_with_2fa = create(:user, :two_factor_via_otp)

        get api(path, admin, admin_mode: true), params: { two_factor: 'enabled' }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(user_with_2fa.id)
      end

      it "returns users without projects" do
        user_without_projects = create(:user)
        create(:project, namespace: user.namespace)
        create(:project, namespace: admin.namespace)

        get api(path, admin, admin_mode: true), params: { without_projects: true }

        expect(response).to match_response_schema('public_api/v4/user/admins')
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(user_without_projects.id)
      end

      it 'returns 400 when provided incorrect sort params' do
        get api(path, admin, admin_mode: true), params: { order_by: 'magic', sort: 'asc' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'admins param' do
      it 'returns only admins' do
        get api("/users?admins=true", admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(admin.id)
      end
    end
  end

  describe "GET /users/:id" do
    let_it_be(:user2, reload: true) { create(:user, username: 'another_user') }

    let(:path) { "/users/#{user.id}" }

    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:users_get_by_id, scope: user, users_allowlist: []).and_return(false)
    end

    it "returns a user by id" do
      get api(path, user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response['username']).to eq(user.username)
    end

    it "does not return the user's `is_admin` flag" do
      get api(path, user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'is_admin'
    end

    it "does not return the user's `highest_role`" do
      get api(path, user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'highest_role'
    end

    it "does not return the user's sign in IPs" do
      get api(path, user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'current_sign_in_ip'
      expect(json_response.keys).not_to include 'last_sign_in_ip'
    end

    it "does not contain plan or trial data" do
      get api(path, user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include 'plan'
      expect(json_response.keys).not_to include 'trial'
    end

    it 'returns a 404 if the target user is present but inaccessible' do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_user, user2).and_return(false)

      get api("/users/#{user2.id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns the `created_at` field for public users' do
      get api("/users/#{user2.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).to include('created_at')
    end

    it 'does not return the `created_at` field for private users' do
      get api("/users/#{private_user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include('created_at')
    end

    it 'returns the `followers` field for public users' do
      get api("/users/#{user2.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).to include('followers')
    end

    it 'does not return the `followers` field for private users' do
      get api("/users/#{private_user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include('followers')
    end

    it 'returns the `following` field for public users' do
      get api("/users/#{user2.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).to include('following')
    end

    it 'does not return the `following` field for private users' do
      get api("/users/#{private_user.id}", user)

      expect(response).to match_response_schema('public_api/v4/user/basic')
      expect(json_response.keys).not_to include('following')
    end

    it 'does not contain the note of the user' do
      get api(path, user)

      expect(json_response).not_to have_key('note')
      expect(json_response).not_to have_key('sign_in_count')
    end

    context 'when the rate limit is not exceeded' do
      it 'returns a success status' do
        expect(Gitlab::ApplicationRateLimiter)
          .to receive(:throttled?).with(:users_get_by_id, scope: user, users_allowlist: [])
          .and_return(false)

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the rate limit is exceeded' do
      context 'when feature flag is enabled' do
        it 'returns "too many requests" status' do
          expect(Gitlab::ApplicationRateLimiter)
            .to receive(:throttled?).with(:users_get_by_id, scope: user, users_allowlist: [])
            .and_return(true)

          get api(path, user)

          expect(response).to have_gitlab_http_status(:too_many_requests)
        end

        it 'still allows admin users' do
          expect(Gitlab::ApplicationRateLimiter)
            .not_to receive(:throttled?)

          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'allows users whose username is in the allowlist' do
          allowlist = [user.username]
          current_settings = Gitlab::CurrentSettings.current_application_settings

          # Necessary to ensure the same object is returned on each call
          allow(Gitlab::CurrentSettings).to receive(:current_application_settings).and_return current_settings

          allow(current_settings).to receive(:users_get_by_id_limit_allowlist).and_return(allowlist)

          expect(Gitlab::ApplicationRateLimiter)
            .to receive(:throttled?).with(:users_get_by_id, scope: user, users_allowlist: allowlist)
            .and_call_original

          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when job title is present' do
      let(:job_title) { 'Fullstack Engineer' }

      before do
        user.update!(job_title: job_title)
      end

      it 'returns job title of a user' do
        get api(path, user)

        expect(response).to match_response_schema('public_api/v4/user/basic')
        expect(json_response['job_title']).to eq(job_title)
      end
    end

    context 'when authenticated as admin' do
      it 'contains the note of the user' do
        get api(path, admin, admin_mode: true)

        expect(json_response).to have_key('note')
        expect(json_response['note']).to eq(user.note)
        expect(json_response).to have_key('sign_in_count')
      end

      it 'includes the `is_admin` field' do
        get api(path, admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admin')
        expect(json_response['is_admin']).to be(false)
      end

      it "includes the `created_at` field for private users" do
        get api("/users/#{private_user.id}", admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admin')
        expect(json_response.keys).to include 'created_at'
      end

      it 'includes the `highest_role` field' do
        get api(path, admin, admin_mode: true)

        expect(response).to match_response_schema('public_api/v4/user/admin')
        expect(json_response['highest_role']).to be(0)
      end

      it 'includes the `namespace_id` field' do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('public_api/v4/user/admin')
        expect(json_response['namespace_id']).to eq(user.namespace_id)
      end

      if Gitlab.ee?
        it 'does not include values for plan or trial' do
          get api(path, admin, admin_mode: true)

          expect(response).to match_response_schema('public_api/v4/user/basic')
        end
      else
        it 'does not include plan or trial data' do
          get api(path, admin, admin_mode: true)

          expect(response).to match_response_schema('public_api/v4/user/basic')
          expect(json_response.keys).not_to include 'plan'
          expect(json_response.keys).not_to include 'trial'
        end
      end

      context 'when user has not logged in' do
        it 'does not include the sign in IPs' do
          get api(path, admin, admin_mode: true)

          expect(response).to match_response_schema('public_api/v4/user/admin')
          expect(json_response).to include('current_sign_in_ip' => nil, 'last_sign_in_ip' => nil)
        end
      end

      context 'when user has logged in' do
        let_it_be(:signed_in_user) { create(:user, :with_sign_ins) }

        it 'includes the sign in IPs' do
          get api("/users/#{signed_in_user.id}", admin, admin_mode: true)

          expect(response).to match_response_schema('public_api/v4/user/admin')
          expect(json_response['current_sign_in_ip']).to eq('127.0.0.1')
          expect(json_response['last_sign_in_ip']).to eq('127.0.0.1')
        end
      end
    end

    context 'for an anonymous user' do
      it 'returns 403' do
        get api(path)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it "returns a 404 error if user id not found" do
      get api("/users/#{non_existing_record_id}", user)

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

    context 'when rate limited' do
      let(:current_user) { create(:user) }
      let(:path) { "/users/#{user.username}/status" }
      let(:request) { get api(path, current_user) }

      context 'when the :rate_limiting_user_endpoints feature flag is enabled' do
        before do
          stub_feature_flags(rate_limiting_user_endpoints: true)
        end

        context 'when user is authenticated' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_status do
            def request
              get api(path, current_user)
            end
          end
        end

        context 'when user is unauthenticated' do
          let(:current_user) { nil }

          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_status do
            def request
              get api(path, current_user)
            end
          end
        end
      end
    end
  end

  describe 'POST /users/:id/follow' do
    let(:followee) { create(:user) }
    let(:path) { "/users/#{followee.id}/follow" }

    context 'on an unfollowed user' do
      it 'follows the user' do
        post api(path, user)

        expect(user.followees).to contain_exactly(followee)
        expect(response).to have_gitlab_http_status(:created)
      end

      it 'alerts and not follow when over followee limit' do
        stub_const('Users::UserFollowUser::MAX_FOLLOWEE_LIMIT', 2)
        Users::UserFollowUser::MAX_FOLLOWEE_LIMIT.times { user.follow(create(:user)) }

        post api(path, user)
        expect(response).to have_gitlab_http_status(:bad_request)
        expected_message = format(_("You can't follow more than %{limit} users. To follow more users, unfollow some others."), limit: Users::UserFollowUser::MAX_FOLLOWEE_LIMIT)
        expect(json_response['message']).to eq(expected_message)
        expect(user.following?(followee)).to be_falsey
      end
    end

    context 'on a followed user' do
      before do
        user.follow(followee)
      end

      it 'does not change following' do
        post api(path, user)

        expect(user.followees).to contain_exactly(followee)
        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end

    context 'on a user with disabled following' do
      before do
        user.enabled_following = false
        user.save!
      end

      it 'does not change following' do
        post api("/users/#{followee.id}/follow", user)

        expect(user.followees).to be_empty
        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end
  end

  describe 'POST /users/:id/unfollow' do
    let(:followee) { create(:user) }
    let(:path) { "/users/#{followee.id}/unfollow" }

    context 'on a followed user' do
      before do
        user.follow(followee)
      end

      it 'unfollow the user' do
        post api(path, user)

        expect(user.followees).to be_empty
        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'on an unfollowed user' do
      it 'does not change following' do
        post api(path, user)

        expect(user.followees).to be_empty
        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end
  end

  describe 'GET /users/:id/followers' do
    let(:follower) { create(:user) }
    let(:path) { "/users/#{user.id}/followers" }

    context 'for an anonymous user' do
      it 'returns 403' do
        get api("/users/#{user.id}")

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'user has followers' do
      it 'lists followers' do
        follower.follow(user)

        get api(path, user)

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
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_empty
      end
    end

    context 'when rate limited' do
      let(:current_user) { create(:user) }
      let(:request) { get api(path, current_user) }

      context 'when the :rate_limiting_user_endpoints feature flag is enabled' do
        before do
          stub_feature_flags(rate_limiting_user_endpoints: true)
        end

        context 'when user is authenticated' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_followers do
            def request
              get api(path, current_user)
            end
          end
        end

        context 'when user is unauthenticated' do
          let(:current_user) { nil }

          it 'returns 403' do
            request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end
  end

  describe 'GET /users/:id/following' do
    let(:followee) { create(:user) }
    let(:path) { "/users/#{user.id}/following" }

    context 'for an anonymous user' do
      it 'returns 403' do
        get api("/users/#{user.id}")

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'user has followers' do
      it 'lists following user' do
        user.follow(followee)

        get api(path, user)

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
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_empty
      end
    end

    context 'when rate limited' do
      let(:current_user) { create(:user) }
      let(:request) { get api(path, current_user) }

      context 'when the :rate_limiting_user_endpoints feature flag is enabled' do
        before do
          stub_feature_flags(rate_limiting_user_endpoints: true)
        end

        context 'when user is authenticated' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_following do
            def request
              get api(path, current_user)
            end
          end
        end

        context 'when user is unauthenticated' do
          let(:current_user) { nil }

          it 'returns 403' do
            request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end
  end

  describe "POST /users", :with_current_organization do
    let(:path) { '/users' }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { attributes_for(:user, projects_limit: 3) }
    end

    it "creates user" do
      expect do
        post api(path, admin, admin_mode: true), params: attributes_for(:user, projects_limit: 3)
      end.to change { User.count }.by(1)
    end

    it "creates user with correct attributes" do
      post api(path, admin, admin_mode: true), params: attributes_for(:user, admin: true, can_create_group: true)
      expect(response).to have_gitlab_http_status(:created)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(true)
      expect(new_user.can_create_group).to eq(true)
      expect(new_user.namespace.organization).to eq(current_organization)
    end

    it "creates user with optional attributes" do
      optional_attributes = { confirm: true, theme_id: 2, color_scheme_id: 4 }
      attributes = attributes_for(:user).merge(optional_attributes)

      post api(path, admin, admin_mode: true), params: attributes

      expect(response).to have_gitlab_http_status(:created)
    end

    it "creates non-admin user" do
      post api(path, admin, admin_mode: true), params: attributes_for(:user, admin: false, can_create_group: false)
      expect(response).to have_gitlab_http_status(:created)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(false)
      expect(new_user.can_create_group).to eq(false)
    end

    it "creates non-admin users by default" do
      post api(path, admin, admin_mode: true), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(:created)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.admin).to eq(false)
    end

    it "returns 201 Created on success" do
      post api(path, admin, admin_mode: true), params: attributes_for(:user, projects_limit: 3)
      expect(response).to match_response_schema('public_api/v4/user/admin')
      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates non-external users by default' do
      post api(path, admin, admin_mode: true), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.external).to be_falsy
    end

    it 'allows an external user to be created' do
      post api(path, admin, admin_mode: true), params: attributes_for(:user, external: true)
      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user.external).to be_truthy
    end

    it "creates user with reset password" do
      post api(path, admin, admin_mode: true), params: attributes_for(:user, reset_password: true).except(:password)

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user.recently_sent_password_reset?).to eq(true)
    end

    it "creates user with random password" do
      params = attributes_for(:user, force_random_password: true)
      params.delete(:password)
      post api(path, admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user.encrypted_password).to be_present
    end

    it "creates user with private profile" do
      post api(path, admin, admin_mode: true), params: attributes_for(:user, private_profile: true)

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user).not_to eq(nil)
      expect(new_user.private_profile?).to eq(true)
    end

    it "creates user with view_diffs_file_by_file" do
      post api(path, admin, admin_mode: true), params: attributes_for(:user, view_diffs_file_by_file: true)

      expect(response).to have_gitlab_http_status(:created)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user).not_to eq(nil)
      expect(new_user.user_preference.view_diffs_file_by_file?).to eq(true)
    end

    it "creates user with avatar" do
      workhorse_form_with_file(
        api(path, admin, admin_mode: true),
        method: :post,
        file_key: :avatar,
        params: attributes_for(:user, avatar: fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif'))
      )

      expect(response).to have_gitlab_http_status(:created)

      new_user = User.find_by(id: json_response['id'])

      expect(new_user).not_to eq(nil)
      expect(json_response['avatar_url']).to include(new_user.avatar_path)
    end

    it "does not create user with invalid email" do
      post api(path, admin, admin_mode: true),
        params: {
          email: 'invalid email',
          password: User.random_password,
          name: 'test'
        }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if name not given' do
      post api(path, admin, admin_mode: true), params: attributes_for(:user).except(:name)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if password not given' do
      post api(path, admin, admin_mode: true), params: attributes_for(:user).except(:password)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if email not given' do
      post api(path, admin, admin_mode: true), params: attributes_for(:user).except(:email)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if username not given' do
      post api(path, admin, admin_mode: true), params: attributes_for(:user).except(:username)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "doesn't create user with invalid optional attributes" do
      optional_attributes = { theme_id: 50, color_scheme_id: 50 }
      attributes = attributes_for(:user).merge(optional_attributes)

      post api(path, admin, admin_mode: true), params: attributes

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 error if user does not validate' do
      post api(path, admin, admin_mode: true),
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
        .to match_array([Gitlab::PathRegex.namespace_format_message, Gitlab::Regex.oci_repository_path_regex_message])
    end

    it 'tracks weak password errors' do
      attributes = attributes_for(:user).merge({ password: "password" })
      post api(path, admin, admin_mode: true), params: attributes

      expect(json_response['message']['password'])
        .to eq(['must not contain commonly used combinations of words and letters'])
      expect_snowplow_event(
        category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
        action: 'track_weak_password_error',
        controller: 'API::Users',
        method: 'create'
      )
    end

    it "is not available for non admin users" do
      post api(path, user), params: attributes_for(:user)
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'with existing user' do
      before do
        post api(path, admin, admin_mode: true),
          params: {
            email: 'test@example.com',
            password: User.random_password,
            username: 'test',
            name: 'foo'
          }
      end

      it 'returns 409 conflict error if user with same email exists' do
        expect do
          post api(path, admin, admin_mode: true),
            params: {
              name: 'foo',
              email: 'test@example.com',
              password: User.random_password,
              username: 'foo'
            }
        end.to change { User.count }.by(0)
        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to eq('Email has already been taken')
      end

      it 'returns 409 conflict error if same username exists' do
        expect do
          post api(path, admin, admin_mode: true),
            params: {
              name: 'foo',
              email: 'foo@example.com',
              password: User.random_password,
              username: 'test'
            }
        end.to change { User.count }.by(0)
        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to eq('Username has already been taken')
      end

      it 'returns 409 conflict error if same username exists (case insensitive)' do
        expect do
          post api(path, admin, admin_mode: true),
            params: {
              name: 'foo',
              email: 'foo@example.com',
              password: User.random_password,
              username: 'TEST'
            }
        end.to change { User.count }.by(0)
        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to eq('Username has already been taken')
      end

      it 'creates user with new identity' do
        post api(path, admin, admin_mode: true), params: attributes_for(:user, provider: 'github', extern_uid: '67890')

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['identities'].first['extern_uid']).to eq('67890')
        expect(json_response['identities'].first['provider']).to eq('github')
      end
    end

    context 'with existing pages unique domain' do
      let_it_be(:project) { create(:project) }

      before do
        stub_pages_setting(enabled: true)

        create(
          :project_setting,
          project: project,
          pages_unique_domain_enabled: true,
          pages_unique_domain: 'unique-domain')
      end

      it 'returns 400 bad request error if same username is already used by pages unique domain' do
        expect do
          post api(path, admin, admin_mode: true),
            params: {
              name: 'foo',
              email: 'foo@example.com',
              password: User.random_password,
              username: 'unique-domain'
            }
        end.to change { User.count }.by(0)
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq({ "username" => ["has already been taken"] })
      end
    end

    context 'when user with a primary email exists' do
      context 'when the primary email is confirmed' do
        let!(:confirmed_user) { create(:user, email: 'foo@example.com') }

        it 'returns 409 conflict error' do
          expect do
            post api(path, admin, admin_mode: true),
              params: {
                name: 'foo',
                email: confirmed_user.email,
                password: 'password',
                username: 'TEST'
              }
          end.to change { User.count }.by(0)
          expect(response).to have_gitlab_http_status(:conflict)
          expect(json_response['message']).to eq('Email has already been taken')
        end
      end

      context 'when the primary email is unconfirmed' do
        let!(:unconfirmed_user) { create(:user, :unconfirmed, email: 'foo@example.com') }

        it 'returns 409 conflict error' do
          expect do
            post api(path, admin, admin_mode: true),
              params: {
                name: 'foo',
                email: unconfirmed_user.email,
                password: 'password',
                username: 'TEST'
              }
          end.to change { User.count }.by(0)
          expect(response).to have_gitlab_http_status(:conflict)
          expect(json_response['message']).to eq('Email has already been taken')
        end
      end
    end

    context 'when user with a secondary email exists' do
      context 'when the secondary email is confirmed' do
        let!(:email) { create(:email, :confirmed, email: 'foo@example.com') }

        it 'returns 409 conflict error' do
          expect do
            post api(path, admin, admin_mode: true),
              params: {
                name: 'foo',
                email: email.email,
                password: 'password',
                username: 'TEST'
              }
          end.to change { User.count }.by(0)
          expect(response).to have_gitlab_http_status(:conflict)
          expect(json_response['message']).to eq('Email has already been taken')
        end
      end

      context 'when the secondary email is unconfirmed' do
        let!(:email) { create(:email, email: 'foo@example.com') }

        it 'does not create user' do
          expect do
            post api(path, admin, admin_mode: true),
              params: {
                name: 'foo',
                email: email.email,
                password: 'password',
                username: 'TEST'
              }
          end.to change { User.count }.by(0)
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    context "scopes" do
      let(:user) { admin }
      let(:path) { '/users' }
      let(:api_call) { method(:api) }

      include_examples 'does not allow the "read_user" scope'
    end

    context "`private_profile` attribute" do
      context "based on the application setting" do
        before do
          stub_application_setting(user_defaults_to_private_profile: true)
        end

        let(:params) { attributes_for(:user) }

        shared_examples_for 'creates the user with the value of `private_profile` based on the application setting' do
          specify do
            post api(path, admin, admin_mode: true), params: params

            expect(response).to have_gitlab_http_status(:created)
            user = User.find_by(id: json_response['id'], private_profile: true)
            expect(user).to be_present
          end
        end

        context 'when the attribute is not overridden in params' do
          it_behaves_like 'creates the user with the value of `private_profile` based on the application setting'
        end

        context 'when the attribute is overridden in params' do
          it 'creates the user with the value of `private_profile` same as the value of the overridden param' do
            post api(path, admin, admin_mode: true), params: params.merge(private_profile: false)

            expect(response).to have_gitlab_http_status(:created)
            user = User.find_by(id: json_response['id'], private_profile: false)
            expect(user).to be_present
          end

          context 'overridden as `nil`' do
            let(:params) { attributes_for(:user, private_profile: nil) }

            it_behaves_like 'creates the user with the value of `private_profile` based on the application setting'
          end
        end
      end
    end
  end

  describe "PUT /users/:id" do
    let(:path) { "/users/#{user.id}" }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { bio: 'new test bio' } }
    end

    it "returns 200 OK on success" do
      put api(path, admin, admin_mode: true), params: { bio: 'new test bio' }

      expect(response).to match_response_schema('public_api/v4/user/admin')
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'updating password' do
      def update_password(user, admin, password = User.random_password)
        put api("/users/#{user.id}", admin, admin_mode: true), params: { password: password }
      end

      context 'admin updates their own password' do
        # `Users::ActivityService` should not be allowed to execute
        # as the same fails on update user_details
        # This prevents a failure we saw in
        # https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/issues/6616
        before do
          allow_next_instance_of(Users::ActivityService) do |service|
            allow(service).to receive(:execute).and_return(true)
          end
        end

        it 'does not force reset on next login' do
          update_password(admin, admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(admin.reload.password_expired?).to eq(false)
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

      context 'with a weak password' do
        it 'tracks weak password errors' do
          update_password(user, admin, "password")

          expect(json_response['message']['password'])
            .to eq(['must not contain commonly used combinations of words and letters'])
          expect_snowplow_event(
            category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
            action: 'track_weak_password_error',
            controller: 'API::Users',
            method: 'update'
          )
        end
      end
    end

    it "updates user with new bio" do
      put api(path, admin, admin_mode: true), params: { bio: 'new test bio' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['bio']).to eq('new test bio')
      expect(user.reload.bio).to eq('new test bio')
    end

    it "updates user with empty bio" do
      user.update!(bio: 'previous bio')

      put api(path, admin, admin_mode: true), params: { bio: '' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['bio']).to eq('')
      expect(user.reload.bio).to eq('')
    end

    it 'updates user with nil bio' do
      put api(path, admin, admin_mode: true), params: { bio: nil }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['bio']).to eq('')
      expect(user.reload.bio).to eq('')
    end

    it "updates user with organization" do
      put api(path, admin, admin_mode: true), params: { organization: 'GitLab' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['organization']).to eq('GitLab')
      expect(user.reload.organization).to eq('GitLab')
    end

    it 'updates user with avatar' do
      workhorse_form_with_file(
        api(path, admin, admin_mode: true),
        method: :put,
        file_key: :avatar,
        params: { avatar: fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }
      )

      user.reload

      expect(user.avatar).to be_present
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['avatar_url']).to include(user.avatar_path)
    end

    it 'updates user with a new email' do
      old_email = user.email
      old_notification_email = user.notification_email_or_default
      put api(path, admin, admin_mode: true), params: { email: 'new@email.com' }

      user.reload

      expect(response).to have_gitlab_http_status(:ok)
      expect(user).to be_confirmed
      expect(user.email).to eq(old_email)
      expect(user.notification_email_or_default).to eq(old_notification_email)
      expect(user.unconfirmed_email).to eq('new@email.com')
    end

    it 'skips reconfirmation when requested' do
      put api(path, admin, admin_mode: true), params: { email: 'new@email.com', skip_reconfirmation: true }

      user.reload

      expect(response).to have_gitlab_http_status(:ok)
      expect(user).to be_confirmed
      expect(user.email).to eq('new@email.com')
    end

    it 'updates user with their own username' do
      put api(path, admin, admin_mode: true), params: { username: user.username }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['username']).to eq(user.username)
      expect(user.reload.username).to eq(user.username)
    end

    context 'with existing pages unique domain' do
      let_it_be(:project) { create(:project) }

      before do
        stub_pages_setting(enabled: true)

        create(
          :project_setting,
          project: project,
          pages_unique_domain_enabled: true,
          pages_unique_domain: 'unique-domain')
      end

      it 'returns 400 bad request error if same username is already used by pages unique domain' do
        put api(path, admin, admin_mode: true), params: { username: 'unique-domain' }
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq({ "username" => ["has already been taken"] })
      end
    end

    it "updates user's existing identity" do
      put api("/users/#{ldap_user.id}", admin, admin_mode: true), params: { provider: 'ldapmain', extern_uid: '654321' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(ldap_user.reload.identities.first.extern_uid).to eq('654321')
    end

    it 'updates user with new identity' do
      put api(path, admin, admin_mode: true), params: { provider: 'github', extern_uid: 'john' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.identities.first.extern_uid).to eq('john')
      expect(user.reload.identities.first.provider).to eq('github')
    end

    it "updates admin status" do
      put api(path, admin, admin_mode: true), params: { admin: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.admin).to eq(true)
    end

    it "updates external status" do
      put api(path, admin, admin_mode: true), params: { external: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['external']).to eq(true)
      expect(user.reload.external?).to be_truthy
    end

    it "does have default values for theme and color-scheme ID" do
      put api(path, admin, admin_mode: true), params: {}

      expect(user.reload.theme_id).to eq(Gitlab::Themes.default.id)
      expect(user.reload.color_scheme_id).to eq(Gitlab::ColorSchemes.default.id)
    end

    it "updates viewing diffs file by file" do
      put api(path, admin, admin_mode: true), params: { view_diffs_file_by_file: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.user_preference.view_diffs_file_by_file?).to eq(true)
    end

    context 'updating `private_profile`' do
      it "updates private profile" do
        current_value = user.private_profile
        new_value = !current_value

        put api(path, admin, admin_mode: true), params: { private_profile: new_value }

        expect(response).to have_gitlab_http_status(:ok)
        expect(user.reload.private_profile).to eq(new_value)
      end

      context 'when `private_profile` is set to `nil`' do
        before do
          stub_application_setting(user_defaults_to_private_profile: true)
        end

        it "updates private_profile to value of the application setting" do
          user.update!(private_profile: false)

          put api(path, admin, admin_mode: true), params: { private_profile: nil }

          expect(response).to have_gitlab_http_status(:ok)
          expect(user.reload.private_profile).to eq(true)
        end
      end

      it "does not modify private profile when field is not provided" do
        user.update!(private_profile: true)

        put api(path, admin, admin_mode: true), params: {}

        expect(response).to have_gitlab_http_status(:ok)
        expect(user.reload.private_profile).to eq(true)
      end
    end

    it "does not modify theme or color-scheme ID when field is not provided" do
      theme = Gitlab::Themes.each.find { |t| t.id != Gitlab::Themes.default.id }
      scheme = Gitlab::ColorSchemes.each.find { |t| t.id != Gitlab::ColorSchemes.default.id }

      user.update!(theme_id: theme.id, color_scheme_id: scheme.id)

      put api(path, admin, admin_mode: true), params: {}

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.theme_id).to eq(theme.id)
      expect(user.reload.color_scheme_id).to eq(scheme.id)
    end

    it "does not update admin status" do
      admin_user = create(:admin)

      put api("/users/#{admin_user.id}", admin, admin_mode: true), params: { can_create_group: false }

      expect(response).to have_gitlab_http_status(:ok)
      expect(admin_user.reload.admin).to eq(true)
      expect(admin_user.can_create_group).to eq(false)
    end

    it "does not allow invalid update" do
      put api(path, admin, admin_mode: true), params: { email: 'invalid email' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(user.reload.email).not_to eq('invalid email')
    end

    it "updates theme id" do
      put api(path, admin, admin_mode: true), params: { theme_id: 5 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.theme_id).to eq(5)
    end

    it "does not update invalid theme id" do
      put api(path, admin, admin_mode: true), params: { theme_id: 50 }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(user.reload.theme_id).not_to eq(50)
    end

    it "updates color scheme id" do
      put api(path, admin, admin_mode: true), params: { color_scheme_id: 5 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(user.reload.color_scheme_id).to eq(5)
    end

    it "does not update invalid color scheme id" do
      put api(path, admin, admin_mode: true), params: { color_scheme_id: 50 }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(user.reload.color_scheme_id).not_to eq(50)
    end

    context 'when the current user is not an admin' do
      it "is not available" do
        expect do
          put api(path, user), params: attributes_for(:user)
        end.not_to change { user.reload.attributes }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it "returns 404 for non-existing user" do
      put api("/users/#{non_existing_record_id}", admin, admin_mode: true), params: { bio: 'update should fail' }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 if invalid ID" do
      put api("/users/ASDF", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 400 error if user does not validate' do
      put api(path, admin, admin_mode: true),
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
        .to match_array([Gitlab::PathRegex.namespace_format_message, Gitlab::Regex.oci_repository_path_regex_message])
    end

    it 'returns 400 if provider is missing for identity update' do
      put api("/users/#{omniauth_user.id}", admin, admin_mode: true), params: { extern_uid: '654321' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 if external UID is missing for identity update' do
      put api("/users/#{omniauth_user.id}", admin, admin_mode: true), params: { provider: 'ldap' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context "with existing user" do
      before do
        post api("/users", admin, admin_mode: true), params: { email: 'test@example.com', password: User.random_password, username: 'test', name: 'test' }
        post api("/users", admin, admin_mode: true), params: { email: 'foo@bar.com', password: User.random_password, username: 'john', name: 'john' }
        @user = User.all.last
      end

      it 'returns 409 conflict error if email address exists' do
        put api("/users/#{@user.id}", admin, admin_mode: true), params: { email: 'test@example.com' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(@user.reload.email).to eq(@user.email)
      end

      it 'returns 409 conflict error if username taken' do
        @user_id = User.all.last.id
        put api("/users/#{@user.id}", admin, admin_mode: true), params: { username: 'test' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(@user.reload.username).to eq(@user.username)
      end

      it 'returns 409 conflict error if username taken (case insensitive)' do
        @user_id = User.all.last.id
        put api("/users/#{@user.id}", admin, admin_mode: true), params: { username: 'TEST' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(@user.reload.username).to eq(@user.username)
      end
    end

    context 'when user with a primary email exists' do
      context 'when the primary email is confirmed' do
        let!(:confirmed_user) { create(:user, email: 'foo@example.com') }

        it 'returns 409 conflict error' do
          put api(path, admin, admin_mode: true), params: { email: confirmed_user.email }

          expect(response).to have_gitlab_http_status(:conflict)
          expect(user.reload.email).not_to eq(confirmed_user.email)
        end
      end

      context 'when the primary email is unconfirmed' do
        let!(:unconfirmed_user) { create(:user, :unconfirmed, email: 'foo@example.com') }

        it 'returns 409 conflict error' do
          put api(path, admin, admin_mode: true), params: { email: unconfirmed_user.email }

          expect(response).to have_gitlab_http_status(:conflict)
          expect(user.reload.email).not_to eq(unconfirmed_user.email)
        end
      end
    end

    context 'when user with a secondary email exists' do
      context 'when the secondary email is confirmed' do
        let!(:email) { create(:email, :confirmed, email: 'foo@example.com') }

        it 'returns 409 conflict error' do
          put api(path, admin, admin_mode: true), params: { email: email.email }

          expect(response).to have_gitlab_http_status(:conflict)
          expect(user.reload.email).not_to eq(email.email)
        end
      end

      context 'when the secondary email is unconfirmed' do
        let!(:email) { create(:email, email: 'foo@example.com') }

        it 'does not update email' do
          put api(path, admin, admin_mode: true), params: { email: email.email }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(user.reload.email).not_to eq(email.email)
        end
      end
    end
  end

  describe "PUT /user/:id/credit_card_validation" do
    let(:network) { 'American Express' }
    let(:holder_name) {  'John Smith' }
    let(:last_digits) {  '1111' }
    let(:expiration_year) { Date.today.year + 10 }
    let(:expiration_month) { 1 }
    let(:expiration_date) { Date.new(expiration_year, expiration_month, -1) }
    let(:credit_card_validated_at) { Time.utc(2020, 1, 1) }
    let(:zuora_payment_method_xid) { 'abc123' }
    let(:stripe_setup_intent_xid) { 'seti_abc123' }
    let(:stripe_payment_method_xid) { 'pm_abc123' }
    let(:stripe_card_fingerprint) { 'card123' }

    let(:path) { "/user/#{user.id}/credit_card_validation" }
    let(:params) do
      {
        credit_card_validated_at: credit_card_validated_at,
        credit_card_expiration_year: expiration_year,
        credit_card_expiration_month: expiration_month,
        credit_card_holder_name: holder_name,
        credit_card_type: network,
        credit_card_mask_number: last_digits,
        zuora_payment_method_xid: zuora_payment_method_xid,
        stripe_setup_intent_xid: stripe_setup_intent_xid,
        stripe_payment_method_xid: stripe_payment_method_xid,
        stripe_card_fingerprint: stripe_card_fingerprint
      }
    end

    it_behaves_like 'PUT request permissions for admin mode'

    context 'when unauthenticated' do
      it 'returns authentication error' do
        put api(path), params: {}

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as non-admin' do
      it "does not allow updating user's credit card validation" do
        put api(path, user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      it "updates user's credit card validation" do
        put api(path, admin, admin_mode: true), params: params

        user.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(user.credit_card_validation).to have_attributes(
          credit_card_validated_at: credit_card_validated_at,
          network_hash: sha256(network.downcase),
          holder_name_hash: sha256(holder_name.downcase),
          last_digits_hash: sha256(last_digits),
          expiration_date_hash: sha256(expiration_date.to_s),
          zuora_payment_method_xid: zuora_payment_method_xid,
          stripe_setup_intent_xid: stripe_setup_intent_xid,
          stripe_payment_method_xid: stripe_payment_method_xid,
          stripe_card_fingerprint: stripe_card_fingerprint
        )
      end

      it "returns 400 error if credit_card_validated_at is missing" do
        put api(path, admin, admin_mode: true), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 404 error if user not found' do
        put api("/user/#{non_existing_record_id}/credit_card_validation", admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      context 'when the credit card daily verification limit has been exceeded' do
        before do
          stub_const("Users::CreditCardValidation::DAILY_VERIFICATION_LIMIT", 1)
          create(:credit_card_validation, stripe_card_fingerprint: stripe_card_fingerprint)
        end

        it "returns a 400 error with the reason" do
          put api(path, admin, admin_mode: true), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Credit card verification limit exceeded')
        end
      end

      context 'when UpsertCreditCardValidationService returns an unexpected error' do
        before do
          allow_next_instance_of(::Users::UpsertCreditCardValidationService) do |instance|
            allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'upsert failed'))
          end
        end

        it "returns a generic 400 error" do
          put api(path, admin, admin_mode: true), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('400 Bad request')
        end
      end
    end
  end

  describe "DELETE /users/:id/identities/:provider" do
    let(:test_user) { create(:omniauth_user, provider: 'ldapmain') }
    let(:path) { "/users/#{test_user.id}/identities/ldapmain" }

    it_behaves_like 'DELETE request permissions for admin mode'

    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes identity of given provider' do
        expect do
          delete api(path, admin, admin_mode: true)
        end.to change { test_user.identities.count }.by(-1)
        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like '412 response' do
        let(:request) { api(path, admin, admin_mode: true) }
      end

      it 'returns 404 error if user not found' do
        delete api("/users/#{non_existing_record_id}/identities/ldapmain", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if identity not found' do
        delete api("/users/#{test_user.id}/identities/saml", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Identity Not Found')
      end
    end
  end

  describe "POST /users/:id/keys" do
    let(:path) { "/users/#{user.id}/keys" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { attributes_for(:key, usage_type: :signing) }
    end

    it "does not create invalid ssh key" do
      post api(path, admin, admin_mode: true), params: { title: "invalid key" }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create key without title' do
      post api(path, admin, admin_mode: true), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('title is missing')
    end

    it "creates ssh key" do
      key_attrs = attributes_for(:key, usage_type: :signing)

      expect do
        post api(path, admin, admin_mode: true), params: key_attrs
      end.to change { user.keys.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)

      key = user.keys.last
      expect(key.title).to eq(key_attrs[:title])
      expect(key.key).to eq(key_attrs[:key])
      expect(key.usage_type).to eq(key_attrs[:usage_type].to_s)
    end

    it 'creates SSH key with `expires_at` attribute' do
      optional_attributes = { expires_at: 3.weeks.from_now }
      attributes = attributes_for(:key).merge(optional_attributes)

      post api(path, admin, admin_mode: true), params: attributes

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['expires_at'].to_date).to eq(optional_attributes[:expires_at].to_date)
    end

    it "returns 400 for invalid ID" do
      post api("/users/#{non_existing_record_id}/keys", admin, admin_mode: true)
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'GET /users/:id/project_deploy_keys', feature_category: :continuous_delivery do
    let(:project) { create(:project) }
    let(:path) { "/users/#{user.id}/project_deploy_keys" }

    before do
      project.add_maintainer(user)

      deploy_key = create(:deploy_key, user: user)
      create(:deploy_keys_project, project: project, deploy_key_id: deploy_key.id)
    end

    it 'returns 404 for non-existing user' do
      get api("/users/#{non_existing_record_id}/project_deploy_keys")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of project deploy keys with pagination' do
      get api(path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(user.deploy_keys.first.title)
    end

    it 'forbids when a developer fetches maintainer keys' do
      dev_user = create(:user)
      project.add_developer(dev_user)

      get api(path, dev_user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden - No common authorized project found')
    end

    context 'with multiple projects' do
      let(:second_project) { create(:project) }
      let(:second_user) { create(:user) }

      before do
        second_project.add_maintainer(second_user)

        deploy_key = create(:deploy_key, user: second_user)
        create(:deploy_keys_project, project: second_project, deploy_key_id: deploy_key.id)
      end

      context 'when no common projects for user and current_user' do
        it 'forbids' do
          get api(path, second_user)

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('403 Forbidden - No common authorized project found')
        end
      end

      context 'when there are common projects for user and current_user' do
        before do
          project.add_maintainer(second_user)
        end

        let(:path) { "/users/#{second_user.id}/project_deploy_keys" }

        it 'lists only common project keys' do
          expect(second_user.project_deploy_keys).to contain_exactly(
            project.deploy_keys.first, second_project.deploy_keys.first)

          get api(path, user)

          expect(json_response.count).to eq(1)
          expect(json_response.first['key']).to eq(project.deploy_keys.first.key)
        end

        it 'lists only project_deploy_keys and not user deploy_keys' do
          third_user = create(:user)

          project.add_maintainer(third_user)
          second_project.add_maintainer(third_user)

          create(:deploy_key, user: second_user)
          create(:deploy_key, user: third_user)

          get api(path, third_user)

          expect(json_response.count).to eq(2)
          expect([json_response.first['key'], json_response.second['key']]).to contain_exactly(
            project.deploy_keys.first.key, second_project.deploy_keys.first.key)
        end

        it 'avoids N+1 queries' do
          second_project.add_maintainer(user)

          control = ActiveRecord::QueryRecorder.new do
            get api(path, user)
          end

          deploy_key = create(:deploy_key, user: second_user)
          create(:deploy_keys_project, project: second_project, deploy_key_id: deploy_key.id)

          expect do
            get api(path, user)
          end.not_to exceed_query_limit(control)
        end
      end
    end
  end

  describe 'GET /user/:id/keys' do
    subject(:request) { get api(path) }

    let(:path) { "/users/#{user.id}/keys" }

    it 'returns 404 for non-existing user' do
      get api("/users/#{non_existing_record_id}/keys")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of ssh keys' do
      user.keys << key

      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(key.title)
    end

    it 'returns array of ssh keys with comments replaced with'\
      'a simple identifier of username + hostname' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array

      keys = json_response.map { |key_detail| key_detail['key'] }
      expect(keys).to all(include("#{user.name} (#{Gitlab.config.gitlab.host}"))
    end

    context 'N+1 queries' do
      before do
        request
      end

      it 'avoids N+1 queries', :request_store do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          request
        end

        create_list(:key, 2, user: user)

        expect do
          request
        end.not_to exceed_all_query_limit(control)
      end
    end

    context 'when rate limited' do
      let(:current_user) { create(:user) }
      let(:request) { get api(path, current_user) }

      context 'when the :rate_limiting_user_endpoints feature flag is enabled' do
        before do
          stub_feature_flags(rate_limiting_user_endpoints: true)
        end

        context 'when user is authenticated' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_keys do
            def request
              get api(path, current_user)
            end
          end
        end

        context 'when user is unauthenticated' do
          let(:current_user) { nil }

          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_keys do
            def request
              get api(path, current_user)
            end
          end
        end
      end
    end
  end

  describe 'GET /user/:user_id/keys' do
    let(:path) { "/users/#{user.username}/keys" }

    before do
      allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
    end

    it 'returns 404 for non-existing user' do
      get api("/users/#{non_existing_record_id}/keys")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of ssh keys' do
      user.keys << key

      get api(path)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(key.title)
    end

    context 'when the rate limit has been reached' do
      it 'returns status 429 Too Many Requests', :aggregate_failures do
        ip = '1.2.3.4'
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:user_keys, scope: ip).and_return(true)

        get api(path), env: { REMOTE_ADDR: ip }

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  describe 'GET /user/:id/keys/:key_id' do
    let(:path) { "/users/#{user.id}/keys/#{key.id}" }

    it 'gets existing key' do
      user.keys << key

      get api(path)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['title']).to eq(key.title)
    end

    it 'returns 404 error if user not found' do
      user.keys << key

      get api("/users/#{non_existing_record_id}/keys/#{key.id}")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns 404 error if key not found' do
      get api("/users/#{user.id}/keys/#{non_existing_record_id}")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    context 'when rate limited' do
      let(:current_user) { create(:user) }
      let(:request) { get api(path, current_user) }

      context 'when the :rate_limiting_user_endpoints feature flag is enabled' do
        before do
          stub_feature_flags(rate_limiting_user_endpoints: true)
        end

        context 'when user is authenticated' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_specific_key do
            def request
              get api(path, current_user)
            end
          end
        end

        context 'when user is unauthenticated' do
          let(:current_user) { nil }

          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_specific_key do
            def request
              get api(path, current_user)
            end
          end
        end
      end
    end
  end

  describe 'DELETE /user/:id/keys/:key_id' do
    let(:path) { "/users/#{user.id}/keys/#{key.id}" }

    it_behaves_like 'DELETE request permissions for admin mode'

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
          delete api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { user.keys.count }.by(-1)
      end

      it_behaves_like '412 response' do
        let(:request) { api(path, admin, admin_mode: true) }
      end

      it 'returns 404 error if user not found' do
        user.keys << key

        delete api("/users/#{non_existing_record_id}/keys/#{key.id}", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/keys/#{non_existing_record_id}", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Key Not Found')
      end
    end
  end

  describe 'POST /users/:id/gpg_keys' do
    let(:path) { "/users/#{user.id}/gpg_keys" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { attributes_for :gpg_key, key: GpgHelpers::User2.public_key }
    end

    it 'does not create invalid GPG key' do
      post api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'creates GPG key' do
      key_attrs = attributes_for :gpg_key, key: GpgHelpers::User2.public_key

      expect do
        post api(path, admin, admin_mode: true), params: key_attrs

        expect(response).to have_gitlab_http_status(:created)
      end.to change { user.gpg_keys.count }.by(1)
    end

    it 'returns 400 for invalid ID' do
      post api("/users/#{non_existing_record_id}/gpg_keys", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'GET /user/:id/gpg_keys' do
    let(:path) { "/users/#{user.id}/gpg_keys" }

    it 'returns 404 for non-existing user' do
      get api("/users/#{non_existing_record_id}/gpg_keys")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns array of GPG keys' do
      user.gpg_keys << gpg_key

      get api(path)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['key']).to eq(gpg_key.key)
    end

    context 'when rate limited' do
      let(:current_user) { create(:user) }
      let(:request) { get api(path, current_user) }

      context 'when the :rate_limiting_user_endpoints feature flag is enabled' do
        before do
          stub_feature_flags(rate_limiting_user_endpoints: true)
        end

        context 'when user is authenticated' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_gpg_keys do
            def request
              get api(path, current_user)
            end
          end
        end

        context 'when user is unauthenticated' do
          let(:current_user) { nil }

          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_gpg_keys do
            def request
              get api(path, current_user)
            end
          end
        end
      end
    end
  end

  describe 'GET /user/:id/gpg_keys/:key_id' do
    let(:path) { "/users/#{user.id}/gpg_keys/#{gpg_key.id}" }

    it 'returns 404 for non-existing user' do
      get api("/users/#{non_existing_record_id}/gpg_keys/1")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns 404 for non-existing key' do
      get api("/users/#{user.id}/gpg_keys/#{non_existing_record_id}")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns a single GPG key' do
      user.gpg_keys << gpg_key

      get api(path)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['key']).to eq(gpg_key.key)
    end

    context 'when rate limited' do
      let(:current_user) { create(:user) }
      let(:request) { get api(path, current_user) }

      context 'when the :rate_limiting_user_endpoints feature flag is enabled' do
        before do
          stub_feature_flags(rate_limiting_user_endpoints: true)
        end

        context 'when user is authenticated' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_specific_gpg_key do
            def request
              get api(path, current_user)
            end
          end
        end

        context 'when user is unauthenticated' do
          let(:current_user) { nil }

          it_behaves_like 'rate limited endpoint', rate_limit_key: :user_specific_gpg_key do
            def request
              get api(path, current_user)
            end
          end
        end
      end
    end
  end

  describe 'DELETE /user/:id/gpg_keys/:key_id' do
    let(:path) { "/users/#{user.id}/gpg_keys/#{gpg_key.id}" }

    it_behaves_like 'DELETE request permissions for admin mode'

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
          delete api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { user.gpg_keys.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.keys << key

        delete api("/users/#{non_existing_record_id}/gpg_keys/#{gpg_key.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/gpg_keys/#{non_existing_record_id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 GPG Key Not Found')
      end
    end
  end

  describe 'POST /user/:id/gpg_keys/:key_id/revoke' do
    let(:path) { "/users/#{user.id}/gpg_keys/#{gpg_key.id}/revoke" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { {} }
      let(:success_status_code) { :accepted }
    end

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
          post api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:accepted)
        end.to change { user.gpg_keys.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.gpg_keys << gpg_key

        post api("/users/#{non_existing_record_id}/gpg_keys/#{gpg_key.id}/revoke", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        post api("/users/#{user.id}/gpg_keys/#{non_existing_record_id}/revoke", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 GPG Key Not Found')
      end
    end
  end

  describe "POST /users/:id/emails", :mailer do
    let(:path) { "/users/#{user.id}/emails" }

    it_behaves_like 'POST request permissions for admin mode' do
      before do
        email_attrs[:skip_confirmation] = true
      end

      let(:email_attrs) { attributes_for :email }
      let(:params) { email_attrs }
    end

    it "does not create invalid email" do
      post api(path, admin, admin_mode: true), params: {}

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('email is missing')
    end

    it "creates unverified email" do
      email_attrs = attributes_for :email

      perform_enqueued_jobs do
        expect do
          post api(path, admin, admin_mode: true), params: email_attrs
        end.to change { user.emails.count }.by(1)
      end

      expect(json_response['confirmed_at']).to be_nil
      should_email(user)
    end

    it "returns a 400 for invalid ID" do
      post api("/users/#{non_existing_record_id}/emails", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "creates verified email" do
      email_attrs = attributes_for :email
      email_attrs[:skip_confirmation] = true

      post api(path, admin, admin_mode: true), params: email_attrs

      expect(response).to have_gitlab_http_status(:created)

      expect(json_response['confirmed_at']).not_to be_nil
    end

    context 'when user with a primary email exists' do
      context 'when the primary email is confirmed' do
        let!(:confirmed_user) { create(:user, email: 'foo@example.com') }

        it 'returns 400 error' do
          post api(path, admin, admin_mode: true), params: { email: confirmed_user.email }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the primary email is unconfirmed' do
        let!(:unconfirmed_user) { create(:user, :unconfirmed, email: 'foo@example.com') }

        it 'returns 400 error' do
          post api(path, admin, admin_mode: true), params: { email: unconfirmed_user.email }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    context 'when user with a secondary email exists' do
      context 'when the secondary email is confirmed' do
        let!(:email) { create(:email, :confirmed, email: 'foo@example.com') }

        it 'returns 400 error' do
          post api(path, admin, admin_mode: true), params: { email: email.email }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the secondary email is unconfirmed' do
        let!(:email) { create(:email, email: 'foo@example.com') }

        it 'returns 400 error' do
          post api(path, admin, admin_mode: true), params: { email: email.email }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  describe 'GET /user/:id/emails' do
    let(:path) { "/users/#{user.id}/emails" }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api(path)
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get api("/users/#{non_existing_record_id}/emails", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of emails' do
        user.emails << email

        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['email']).to eq(user.email)
        expect(json_response.second['email']).to eq(email.email)
      end

      it "returns a 404 for invalid ID" do
        get api("/users/ASDF/emails", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /user/:id/emails/:email_id' do
    let(:path) { "/users/#{user.id}/emails/#{email.id}" }

    it_behaves_like 'DELETE request permissions for admin mode'

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
          delete api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { user.emails.count }.by(-1)
      end

      it_behaves_like '412 response' do
        subject(:request) { api(path, admin, admin_mode: true) }
      end

      it 'returns 404 error if user not found' do
        user.emails << email

        delete api("/users/#{non_existing_record_id}/emails/#{email.id}", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if email not foud' do
        delete api("/users/#{user.id}/emails/#{non_existing_record_id}", admin, admin_mode: true)
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
    let(:path) { "/users/#{user.id}" }

    it_behaves_like 'DELETE request permissions for admin mode'

    it "deletes user", :sidekiq_inline do
      perform_enqueued_jobs { delete api(path, admin, admin_mode: true) }

      expect(response).to have_gitlab_http_status(:no_content)
      expect(Users::GhostUserMigration.where(user: user, initiator_user: admin)).to be_exists
    end

    context "sole owner of a group" do
      let!(:group) { create(:group, owners: user) }

      context "hard delete disabled" do
        it "does not delete user" do
          perform_enqueued_jobs { delete api(path, admin, admin_mode: true) }
          expect(response).to have_gitlab_http_status(:conflict)
        end
      end

      context "hard delete enabled" do
        it "delete user and group", :sidekiq_inline do
          perform_enqueued_jobs { delete api("/users/#{user.id}?hard_delete=true", admin, admin_mode: true) }
          expect(response).to have_gitlab_http_status(:no_content)
          expect(Group.exists?(group.id)).to be_falsy
        end

        context "with subgroup owning" do
          let(:parent_group) { create(:group) }
          let(:subgroup) { create(:group, parent: parent_group) }

          before do
            parent_group.add_owner(create(:user))
            subgroup.add_owner(user)
          end

          it "delete only user", :sidekiq_inline do
            perform_enqueued_jobs { delete api("/users/#{user.id}?hard_delete=true", admin, admin_mode: true) }
            expect(response).to have_gitlab_http_status(:no_content)
            expect(Group.exists?(subgroup.id)).to be_truthy
          end
        end
      end
    end

    it_behaves_like '412 response' do
      let(:request) { api(path, admin, admin_mode: true) }
    end

    it "does not delete for unauthenticated user" do
      perform_enqueued_jobs { delete api(path) }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "is not available for non admin users" do
      perform_enqueued_jobs { delete api(path, user) }
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it "returns 404 for non-existing user" do
      perform_enqueued_jobs { delete api("/users/#{non_existing_record_id}", admin, admin_mode: true) }
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      perform_enqueued_jobs { delete api("/users/ASDF", admin, admin_mode: true) }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context "hard delete disabled" do
      it "moves contributions to the ghost user", :sidekiq_might_not_need_inline do
        perform_enqueued_jobs { delete api(path, admin, admin_mode: true) }

        expect(response).to have_gitlab_http_status(:no_content)
        expect(issue.reload).to be_persisted
        expect(Users::GhostUserMigration.where(user: user, initiator_user: admin, hard_delete: false)).to be_exists
      end
    end

    context "hard delete enabled" do
      it "removes contributions", :sidekiq_might_not_need_inline do
        perform_enqueued_jobs { delete api("/users/#{user.id}?hard_delete=true", admin, admin_mode: true) }

        expect(response).to have_gitlab_http_status(:no_content)
        expect(Users::GhostUserMigration.where(user: user, initiator_user: admin, hard_delete: true)).to be_exists
      end
    end
  end

  describe "GET /user" do
    let(:path) { '/user' }

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
          get api(path, user, version: version)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/user/public')
          expect(json_response['id']).to eq(user.id)
        end

        context "scopes" do
          let(:api_call) { method(:api) }

          include_examples 'allows the "read_user" scope', version
        end
      end

      context 'with admin' do
        let(:admin_personal_access_token) { create(:personal_access_token, :admin_mode, user: admin).token }

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
          get api(path, version: version)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    it_behaves_like 'get user info', 'v3'
    it_behaves_like 'get user info', 'v4'
  end

  describe "GET /user/preferences" do
    let(:path) { '/user/preferences' }

    context "when unauthenticated" do
      it "returns authentication error" do
        get api(path)
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns user preferences" do
        user.user_preference.view_diffs_file_by_file = false
        user.user_preference.show_whitespace_in_diffs = true
        user.save!

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["view_diffs_file_by_file"]).to eq(user.user_preference.view_diffs_file_by_file)
        expect(json_response["show_whitespace_in_diffs"]).to eq(user.user_preference.show_whitespace_in_diffs)
      end
    end
  end

  describe "PUT /user/preferences" do
    let(:path) { '/user/preferences' }

    context "when unauthenticated" do
      it "returns authentication error" do
        put api(path)
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "updates user preferences" do
        user.user_preference.view_diffs_file_by_file = false
        user.user_preference.show_whitespace_in_diffs = true
        user.save!

        put api(path, user), params: {
          view_diffs_file_by_file: true,
          show_whitespace_in_diffs: false
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["view_diffs_file_by_file"]).to eq(true)
        expect(json_response["show_whitespace_in_diffs"]).to eq(false)

        user.reload

        expect(json_response["view_diffs_file_by_file"]).to eq(user.view_diffs_file_by_file)
        expect(json_response["show_whitespace_in_diffs"]).to eq(user.show_whitespace_in_diffs)
      end
    end
  end

  describe "GET /user/keys" do
    subject(:request) { get api(path, user) }

    let(:path) { "/user/keys" }

    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/keys")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns array of ssh keys" do
        user.keys << key

        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first["title"]).to eq(key.title)
      end

      it 'returns array of ssh keys with comments replaced with'\
        'a simple identifier of username + hostname' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        keys = json_response.map { |key_detail| key_detail['key'] }
        expect(keys).to all(include("#{user.name} (#{Gitlab.config.gitlab.host}"))
      end

      context 'N+1 queries' do
        before do
          request
        end

        it 'avoids N+1 queries', :request_store do
          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            request
          end

          create_list(:key, 2, user: user)

          expect do
            request
          end.not_to exceed_all_query_limit(control)
        end
      end

      context "scopes" do
        let(:api_call) { method(:api) }

        include_examples 'allows the "read_user" scope'
      end
    end
  end

  describe "GET /user/keys/:key_id" do
    let(:path) { "/user/keys/#{key.id}" }

    it "returns single key" do
      user.keys << key

      get api(path, user)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response["title"]).to eq(key.title)
    end

    it 'exposes SSH key comment as a simple identifier of username + hostname' do
      get api(path, user)

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

      get api(path, admin, admin_mode: true)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/keys/ASDF", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context "scopes" do
      let(:api_call) { method(:api) }

      include_examples 'allows the "read_user" scope'
    end
  end

  describe "POST /user/keys" do
    let(:path) { "/user/keys" }

    it "creates ssh key" do
      key_attrs = attributes_for(:key, usage_type: :signing)

      expect do
        post api(path, user), params: key_attrs
      end.to change { user.keys.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)

      key = user.keys.last
      expect(key.title).to eq(key_attrs[:title])
      expect(key.key).to eq(key_attrs[:key])
      expect(key.usage_type).to eq(key_attrs[:usage_type].to_s)
    end

    it 'creates SSH key with `expires_at` attribute' do
      optional_attributes = { expires_at: 3.weeks.from_now }
      attributes = attributes_for(:key).merge(optional_attributes)

      post api(path, user), params: attributes

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['expires_at'].to_date).to eq(optional_attributes[:expires_at].to_date)
    end

    it "returns a 401 error if unauthorized" do
      post api(path), params: { title: 'some title', key: 'some key' }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "does not create ssh key without key" do
      post api(path, user), params: { title: 'title' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create ssh key without title' do
      post api('/user/keys', user), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('title is missing')
    end

    it "does not create ssh key without title" do
      post api(path, user), params: { key: "somekey" }
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe "DELETE /user/keys/:key_id" do
    let(:path) { "/user/keys/#{key.id}" }

    it "deletes existed key" do
      user.keys << key

      expect do
        delete api(path, user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { user.keys.count }.by(-1)
    end

    it_behaves_like '412 response' do
      let(:request) { api(path, user) }
    end

    it "returns 404 if key ID not found" do
      delete api("/user/keys/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.keys << key

      delete api(path)
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "returns a 404 for invalid ID" do
      delete api("/users/keys/ASDF", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /user/gpg_keys' do
    let(:path) { '/user/gpg_keys' }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns array of GPG keys' do
        user.gpg_keys << gpg_key

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['key']).to eq(gpg_key.key)
      end

      context 'scopes' do
        let(:api_call) { method(:api) }

        include_examples 'allows the "read_user" scope'
      end
    end
  end

  describe 'GET /user/gpg_keys/:key_id' do
    let(:path) { "/user/gpg_keys/#{gpg_key.id}" }

    it 'returns a single key' do
      user.gpg_keys << gpg_key

      get api(path, user)

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

      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 GPG Key Not Found')
    end

    it 'returns 404 for invalid ID' do
      get api('/users/gpg_keys/ASDF', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'scopes' do
      let(:api_call) { method(:api) }

      include_examples 'allows the "read_user" scope'
    end
  end

  describe 'POST /user/gpg_keys' do
    let(:path) { '/user/gpg_keys' }

    it 'creates a GPG key' do
      key_attrs = attributes_for :gpg_key, key: GpgHelpers::User2.public_key

      expect do
        post api(path, user), params: key_attrs

        expect(response).to have_gitlab_http_status(:created)
      end.to change { user.gpg_keys.count }.by(1)
    end

    it 'returns a 401 error if unauthorized' do
      post api(path), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'does not create GPG key without key' do
      post api(path, user)

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
      post api('/users/gpg_keys/ASDF/revoke', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'DELETE /user/gpg_keys/:key_id' do
    let(:path) { "/user/gpg_keys/#{gpg_key.id}" }

    it 'deletes existing GPG key' do
      user.gpg_keys << gpg_key

      expect do
        delete api(path, user)

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

      delete api(path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 404 for invalid ID' do
      delete api('/users/gpg_keys/ASDF', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /user/emails" do
    let(:path) { '/user/emails' }

    context "when unauthenticated" do
      it "returns authentication error" do
        get api(path)
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns array of emails" do
        user.emails << email

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['email']).to eq(user.email)
        expect(json_response.second['email']).to eq(email.email)
      end

      context "scopes" do
        let(:api_call) { method(:api) }

        include_examples 'allows the "read_user" scope'
      end
    end
  end

  describe "GET /user/emails/:email_id" do
    let(:path) { "/user/emails/#{email.id}" }

    it "returns single email" do
      user.emails << email

      get api(path, user)
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

      get api(path, admin, admin_mode: true)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/emails/ASDF", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context "scopes" do
      let(:api_call) { method(:api) }

      include_examples 'allows the "read_user" scope'
    end
  end

  describe "POST /user/emails" do
    let(:path) { '/user/emails' }

    it "creates email" do
      email_attrs = attributes_for :email
      expect do
        post api(path, user), params: email_attrs
      end.to change { user.emails.count }.by(1)
      expect(response).to have_gitlab_http_status(:created)
    end

    it "returns a 401 error if unauthorized" do
      post api(path), params: { email: 'some email' }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "does not create email with invalid email" do
      post api(path, user), params: {}

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('email is missing')
    end
  end

  describe "DELETE /user/emails/:email_id" do
    let(:path) { "/user/emails/#{email.id}" }

    it "deletes existed email" do
      user.emails << email

      expect do
        delete api(path, user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { user.emails.count }.by(-1)
    end

    it_behaves_like '412 response' do
      let(:request) { api(path, user) }
    end

    it "returns 404 if email ID not found" do
      delete api("/user/emails/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.emails << email

      delete api(path)
      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "returns 400 for invalid ID" do
      delete api("/user/emails/ASDF", admin, admin_mode: true)

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
      subject(:activate) { post api(path, api_user, **params) }

      let(:user_id) { user.id }
      let(:path) { "/users/#{user_id}/activate" }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:params) { {} }
      end

      context 'performed by a non-admin user' do
        let(:api_user) { user }
        let(:params) { { admin_mode: false } }

        it 'is not authorized to perform the action' do
          activate

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'performed by an admin user' do
        let(:api_user) { admin }
        let(:params) { { admin_mode: true } }

        context 'for a deactivated user' do
          let(:user_id) { deactivated_user.id }

          it 'activates a deactivated user' do
            activate

            expect(response).to have_gitlab_http_status(:created)
            expect(deactivated_user.reload.state).to eq('active')
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
          let(:user_id) { blocked_user.id }

          it 'returns 403' do
            activate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('Error occurred. A blocked user must be unblocked to be activated')
            expect(blocked_user.reload.state).to eq('blocked')
          end
        end

        context 'for a ldap blocked user' do
          before do
            user.ldap_block
          end

          it 'returns 403' do
            activate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('Error occurred. A blocked user must be unblocked to be activated')
            expect(user.reload.state).to eq('ldap_blocked')
          end
        end

        context 'for a user that does not exist' do
          let(:user_id) { non_existing_record_id }

          before do
            activate
          end

          it_behaves_like '404'
        end
      end
    end

    describe 'POST /users/:id/deactivate' do
      subject(:deactivate) { post api(path, api_user, **params) }

      let(:user_id) { user.id }
      let(:path) { "/users/#{user_id}/deactivate" }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:params) { {} }
      end

      context 'performed by a non-admin user' do
        let(:api_user) { user }
        let(:params) { { admin_mode: false } }

        it 'is not authorized to perform the action' do
          deactivate

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'performed by an admin user' do
        let(:api_user) { admin }
        let(:params) { { admin_mode: true } }

        context 'for an active user' do
          let(:activity) { {} }
          let(:user) { create(:user, **activity) }

          context 'with no recent activity' do
            let(:activity) { { last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.next.days.ago } }

            it 'deactivates an active user' do
              deactivate

              expect(response).to have_gitlab_http_status(:created)
              expect(user.reload.state).to eq('deactivated')
            end
          end

          context 'with recent activity' do
            let(:activity) { { last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.pred.days.ago } }

            it 'does not deactivate an active user' do
              deactivate

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(json_response['message']).to eq("The user you are trying to deactivate has been active in the past #{Gitlab::CurrentSettings.deactivate_dormant_users_period} days and cannot be deactivated")
              expect(user.reload.state).to eq('active')
            end
          end
        end

        context 'for a deactivated user' do
          let(:user_id) { deactivated_user.id }

          it 'returns 201' do
            deactivate

            expect(response).to have_gitlab_http_status(:created)
            expect(deactivated_user.reload.state).to eq('deactivated')
          end
        end

        context 'for a blocked user' do
          let(:user_id) { blocked_user.id }

          it 'returns 403' do
            deactivate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('Error occurred. A blocked user cannot be deactivated')
            expect(blocked_user.reload.state).to eq('blocked')
          end
        end

        context 'for a ldap blocked user' do
          before do
            user.ldap_block
          end

          it 'returns 403' do
            deactivate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('Error occurred. A blocked user cannot be deactivated')
            expect(user.reload.state).to eq('ldap_blocked')
          end
        end

        context 'for an internal user' do
          let(:user) { Users::Internal.alert_bot }

          it 'returns 403' do
            deactivate

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('Internal users cannot be deactivated')
          end
        end

        context 'for a user that does not exist' do
          let(:user_id) { non_existing_record_id }

          before do
            deactivate
          end

          it_behaves_like '404'
        end
      end
    end
  end

  context 'approve and reject pending user' do
    let(:pending_user) { create(:user, :blocked_pending_approval) }

    shared_examples '404' do
      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end

    describe 'POST /users/:id/approve' do
      subject(:approve) { post api(path, api_user, **params) }

      let(:path) { "/users/#{user_id}/approve" }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:user_id) { pending_user.id }
        let(:params) { {} }
      end

      context 'performed by a non-admin user' do
        let(:api_user) { user }
        let(:user_id) { pending_user.id }
        let(:params) { { admin_mode: false } }

        it 'is not authorized to perform the action' do
          expect { approve }.not_to change { pending_user.reload.state }
          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You are not allowed to approve a user')
        end
      end

      context 'performed by an admin user' do
        let(:api_user) { admin }
        let(:params) { { admin_mode: true } }

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

    describe 'POST /users/:id/reject' do
      subject(:reject) { post api(path, api_user, **params) }

      let(:path) { "/users/#{user_id}/reject" }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:user_id) { pending_user.id }
        let(:params) { {} }
        let(:success_status_code) { :success }
      end

      shared_examples 'returns 409' do
        it 'returns 409' do
          reject

          expect(response).to have_gitlab_http_status(:conflict)
          expect(json_response['message']).to eq('User does not have a pending request')
        end
      end

      context 'performed by a non-admin user' do
        let(:api_user) { user }
        let(:user_id) { pending_user.id }
        let(:params) { { admin_mode: false } }

        it 'returns 403' do
          expect { reject }.not_to change { pending_user.reload.state }
          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You are not allowed to reject a user')
        end
      end

      context 'performed by an admin user' do
        let(:api_user) { admin }
        let(:params) { { admin_mode: true } }

        context 'for an pending approval user' do
          let(:user_id) { pending_user.id }

          it 'returns 200' do
            reject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['message']).to eq('Success')
          end
        end

        context 'for a deactivated user' do
          let(:user_id) { deactivated_user.id }

          it 'does not reject a deactivated user' do
            expect { reject }.not_to change { deactivated_user.reload.state }
          end

          it_behaves_like 'returns 409'
        end

        context 'for an active user' do
          let(:user_id) { user.id }

          it 'does not reject an active user' do
            expect { reject }.not_to change { user.reload.state }
          end

          it_behaves_like 'returns 409'
        end

        context 'for a blocked user' do
          let(:user_id) { blocked_user.id }

          it 'does not reject a blocked user' do
            expect { reject }.not_to change { blocked_user.reload.state }
          end

          it_behaves_like 'returns 409'
        end

        context 'for a ldap blocked user' do
          let(:user_id) { ldap_blocked_user.id }

          it 'does not reject a ldap blocked user' do
            expect { reject }.not_to change { ldap_blocked_user.reload.state }
          end

          it_behaves_like 'returns 409'
        end

        context 'for a user that does not exist' do
          let(:user_id) { non_existing_record_id }

          before do
            reject
          end

          it_behaves_like '404'
        end
      end
    end
  end

  describe 'POST /users/:id/block' do
    subject(:block_user) { post api(path, api_user, **params) }

    let(:user_id) { user.id }
    let(:path) { "/users/#{user_id}/block" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { {} }
    end

    context 'when admin' do
      let(:api_user) { admin }
      let(:params) { { admin_mode: true } }

      context 'with an existing user' do
        it 'blocks existing user' do
          block_user

          expect(response).to have_gitlab_http_status(:created)
          expect(response.body).to eq('true')
          expect(user.reload.state).to eq('blocked')
        end

        it 'saves a custom attribute', :freeze_time, feature_category: :insider_threat do
          block_user

          custom_attribute = user.custom_attributes.last

          expect(custom_attribute.key).to eq(UserCustomAttribute::BLOCKED_BY)
          expect(custom_attribute.value).to eq("#{admin.username}/#{admin.id}+#{Time.current}")
        end
      end

      context 'with an ldap blocked user' do
        let(:user_id) { ldap_blocked_user.id }

        it 'does not re-block ldap blocked users' do
          block_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
        end
      end

      context 'with a non existent user' do
        let(:user_id) { non_existing_record_id }

        it 'does not block non existent user, returns 404' do
          block_user

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 User Not Found')
        end
      end

      context 'with an internal user' do
        let(:user_id) { internal_user.id }

        it 'does not block internal user, returns 403' do
          block_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('An internal user cannot be blocked')
        end
      end

      context 'with a blocked user' do
        let(:user_id) { blocked_user.id }

        it 'returns a 201 if user is already blocked' do
          block_user

          expect(response).to have_gitlab_http_status(:created)
          expect(response.body).to eq('null')
        end
      end

      context 'with the API initiating user' do
        let(:user_id) { admin.id }

        it 'does not block the API initiating user, returns 403' do
          block_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('403 Forbidden - The API initiating user cannot be blocked by the API')
          expect(admin.reload.state).to eq('active')
        end
      end
    end

    context 'performed by a non-admin user' do
      let(:api_user) { user }
      let(:params) { { admin_mode: false } }

      it 'returns 403' do
        block_user

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(user.reload.state).to eq('active')
      end
    end
  end

  describe 'POST /users/:id/unblock' do
    subject(:unblock_user) { post api(path, api_user, **params) }

    let(:path) { "/users/#{user_id}/unblock" }
    let(:user_id) { user.id }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { {} }
    end

    context 'when admin' do
      let(:api_user) { admin }
      let(:params) { { admin_mode: true } }

      context 'with an existing user' do
        it 'unblocks existing user' do
          unblock_user

          expect(response).to have_gitlab_http_status(:created)
          expect(user.reload.state).to eq('active')
        end
      end

      context 'with a blocked user' do
        let(:user_id) { blocked_user.id }

        it 'unblocks a blocked user' do
          unblock_user

          expect(response).to have_gitlab_http_status(:created)
          expect(blocked_user.reload.state).to eq('active')
        end

        it 'saves a custom attribute', :freeze_time, feature_category: :insider_threat do
          unblock_user

          custom_attribute = blocked_user.custom_attributes.last

          expect(custom_attribute.key).to eq(UserCustomAttribute::UNBLOCKED_BY)
          expect(custom_attribute.value).to eq("#{admin.username}/#{admin.id}+#{Time.current}")
        end
      end

      context 'with a ldap blocked user' do
        let(:user_id) { ldap_blocked_user.id }

        it 'does not unblock ldap blocked users' do
          unblock_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
        end
      end

      context 'with a deactivated user' do
        let(:user_id) { deactivated_user.id }

        it 'does not unblock deactivated users' do
          unblock_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(deactivated_user.reload.state).to eq('deactivated')
        end
      end

      context 'with a non existent user' do
        let(:user_id) { non_existing_record_id }

        it 'returns a 404 error if user id not found' do
          unblock_user

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 User Not Found')
        end
      end

      context 'with an invalid user id' do
        let(:user_id) { 'ASDF' }

        it 'returns a 404' do
          unblock_user

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'performed by a non-admin user' do
      let(:api_user) { user }
      let(:params) { { admin_mode: false } }

      it 'returns 403' do
        unblock_user

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(user.reload.state).to eq('active')
      end
    end
  end

  describe 'POST /users/:id/ban' do
    subject(:ban_user) { post api(path, api_user, **params) }

    let(:path) { "/users/#{user_id}/ban" }
    let(:user_id) { user.id }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { {} }
    end

    context 'when admin' do
      let(:api_user) { admin }
      let(:params) { { admin_mode: true } }

      context 'with an active user' do
        it 'bans an active user' do
          ban_user

          expect(response).to have_gitlab_http_status(:created)
          expect(response.body).to eq('true')
          expect(user.reload.state).to eq('banned')
        end
      end

      context 'with an ldap blocked user' do
        let(:user_id) { ldap_blocked_user.id }

        it 'does not ban ldap blocked users' do
          ban_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You cannot ban ldap_blocked users.')
          expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
        end
      end

      context 'with a deactivated user' do
        let(:user_id) { deactivated_user.id }

        it 'does not ban deactivated users' do
          ban_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You cannot ban deactivated users.')
          expect(deactivated_user.reload.state).to eq('deactivated')
        end
      end

      context 'with a banned user' do
        let(:user_id) { banned_user.id }

        it 'does not ban banned users' do
          ban_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You cannot ban banned users.')
          expect(banned_user.reload.state).to eq('banned')
        end
      end

      context 'with a non existent user' do
        let(:user_id) { non_existing_record_id }

        it 'does not ban non existent users' do
          ban_user

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 User Not Found')
        end
      end

      context 'with an invalid id' do
        let(:user_id) { 'ASDF' }

        it 'does not ban invalid id users' do
          ban_user

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'performed by a non-admin user' do
      let(:api_user) { user }
      let(:params) { { admin_mode: false } }

      it 'returns 403' do
        ban_user

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(user.reload.state).to eq('active')
      end
    end
  end

  describe 'POST /users/:id/unban' do
    subject(:unban_user) { post api(path, api_user, **params) }

    let(:path) { "/users/#{user_id}/unban" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:user_id) { banned_user.id }
      let(:params) { {} }
    end

    context 'when admin' do
      let(:api_user) { admin }
      let(:params) { { admin_mode: true } }

      context 'with a banned user' do
        let(:user_id) { banned_user.id }

        it 'activates a banned user' do
          unban_user

          expect(response).to have_gitlab_http_status(:created)
          expect(banned_user.reload.state).to eq('active')
        end
      end

      context 'with an ldap_blocked user' do
        let(:user_id) { ldap_blocked_user.id }

        it 'does not unban ldap_blocked users' do
          unban_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You cannot unban ldap_blocked users.')
          expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
        end
      end

      context 'with a deactivated user' do
        let(:user_id) { deactivated_user.id }

        it 'does not unban deactivated users' do
          unban_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You cannot unban deactivated users.')
          expect(deactivated_user.reload.state).to eq('deactivated')
        end
      end

      context 'with an active user' do
        let(:user_id) { user.id }

        it 'does not unban active users' do
          unban_user

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('You cannot unban active users.')
          expect(user.reload.state).to eq('active')
        end
      end

      context 'with a non existent user' do
        let(:user_id) { non_existing_record_id }

        it 'does not unban non existent users' do
          unban_user

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 User Not Found')
        end
      end

      context 'with an invalid id user' do
        let(:user_id) { 'ASDF' }

        it 'does not unban invalid id users' do
          unban_user

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'performed by a non-admin user' do
      let(:api_user) { user }
      let(:params) { { admin_mode: false } }
      let(:user_id) { banned_user.id }

      it 'returns 403' do
        unban_user

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(user.reload.state).to eq('active')
      end
    end
  end

  describe "GET /users/:id/memberships" do
    subject(:request) { get api(path, requesting_user, admin_mode: true) }

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }

    let(:requesting_user) { create(:user) }
    let(:path) { "/users/#{user.id}/memberships" }

    before_all do
      project.add_guest(user)
      group.add_guest(user)
    end

    it_behaves_like 'GET request permissions for admin mode'

    context 'requested by admin user' do
      let(:requesting_user) { create(:user, :admin) }

      it "responses successfully" do
        request

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
        request
        expect(response).to have_gitlab_http_status(:ok)

        control = ActiveRecord::QueryRecorder.new do
          request
        end

        create_list(:project, 5).map { |project| project.add_guest(user) }

        expect do
          request
        end.not_to exceed_query_limit(control)
      end

      context 'with type filter' do
        it "only returns project memberships" do
          get api("/users/#{user.id}/memberships?type=Project", requesting_user, admin_mode: true)

          aggregate_failures do
            expect(json_response).to contain_exactly(a_hash_including('source_type' => 'Project'))
            expect(json_response).not_to include(a_hash_including('source_type' => 'Namespace'))
          end
        end

        it "only returns group memberships" do
          get api("/users/#{user.id}/memberships?type=Namespace", requesting_user, admin_mode: true)

          aggregate_failures do
            expect(json_response).to contain_exactly(a_hash_including('source_type' => 'Namespace'))
            expect(json_response).not_to include(a_hash_including('source_type' => 'Project'))
          end
        end

        it "recognizes unsupported types" do
          get api("/users/#{user.id}/memberships?type=foo", requesting_user, admin_mode: true)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  context "user activities", :clean_gitlab_redis_shared_state do
    let_it_be(:old_active_user) { create(:user, last_activity_on: Time.utc(2000, 1, 1)) }
    let_it_be(:newly_active_user) { create(:user, last_activity_on: 2.days.ago.midday) }
    let_it_be(:newly_active_private_user) { create(:user, last_activity_on: 1.day.ago.midday, private_profile: true) }
    let(:path) { '/user/activities' }

    context 'for an anonymous user' do
      it 'returns 401' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'as a logged in user' do
      it 'returns the activities from the last 6 months' do
        get api(path, user)

        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(1)

        activity = json_response.last

        expect(activity['username']).to eq(newly_active_user.username)
        expect(activity['last_activity_on']).to eq(2.days.ago.to_date.to_s)
        expect(activity['last_activity_at']).to eq(2.days.ago.to_date.to_s)
      end

      context 'passing a :from parameter' do
        it 'returns the activities from the given date' do
          get api("#{path}?from=2000-1-1", user)

          expect(response).to include_pagination_headers
          expect(json_response.size).to eq(2)

          activity = json_response.first

          expect(activity['username']).to eq(old_active_user.username)
          expect(activity['last_activity_on']).to eq(Time.utc(2000, 1, 1).to_date.to_s)
          expect(activity['last_activity_at']).to eq(Time.utc(2000, 1, 1).to_date.to_s)
        end
      end

      it 'does not include users with private profiles' do
        get api(path, user)

        expect(json_response.map { |user| user['username'] })
          .not_to include(newly_active_private_user.username)
      end
    end

    context 'as admin' do
      it 'includes users with private profiles' do
        get api(path, admin, admin_mode: true)

        expect(json_response.map { |user| user['username'] })
          .to include(newly_active_private_user.username)
      end
    end
  end

  describe '/user/status' do
    let(:user_status) { create(:user_status, clear_status_at: 8.hours.from_now) }
    let(:user_with_status) { user_status.user }
    let(:params) { {} }
    let(:request_user) { user }
    let(:path) { '/user/status' }

    shared_examples '/user/status successful response' do
      context 'when request is successful' do
        let(:params) { { emoji: 'smirk', message: 'hello world' } }

        it 'saves the status' do
          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['emoji']).to eq('smirk')
          expect(json_response['message']).to eq('hello world')
        end
      end
    end

    shared_examples '/user/status unsuccessful response' do
      context 'when request is unsuccessful' do
        let(:params) { { emoji: 'does not exist', message: 'hello world' } }

        it 'renders errors' do
          set_user_status

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['emoji']).to be_present
        end
      end
    end

    shared_examples '/user/status passing nil for params' do
      context 'when passing nil for params' do
        let(:params) { { emoji: nil, message: nil, clear_status_after: nil } }
        let(:request_user) { user_with_status }

        it 'deletes the status' do
          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(user_with_status.reset.status).to be_nil
        end
      end
    end

    shared_examples '/user/status clear_status_after field' do
      context 'when clear_status_after is valid', :freeze_time do
        let(:params) { { emoji: 'smirk', message: 'hello world', clear_status_after: '3_hours' } }

        it 'sets the clear_status_at column' do
          expected_clear_status_at = 3.hours.from_now

          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(user.status.clear_status_at).to be_like_time(expected_clear_status_at)
          expect(Time.parse(json_response["clear_status_at"])).to be_like_time(expected_clear_status_at)
        end
      end

      context 'when clear_status_after is nil' do
        let(:params) { { emoji: 'smirk', message: 'hello world', clear_status_after: nil } }
        let(:request_user) { user_with_status }

        it 'unsets the clear_status_at column' do
          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(user_with_status.reset.status.clear_status_at).to be_nil
        end
      end

      context 'when clear_status_after is invalid' do
        let(:params) { { emoji: 'smirk', message: 'hello world', clear_status_after: 'invalid' } }

        it 'raises error when unknown status value is given' do
          set_user_status

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    describe 'GET' do
      it_behaves_like 'rendering user status'
    end

    describe 'PUT' do
      subject(:set_user_status) { put api(path, request_user), params: params }

      include_examples '/user/status successful response'

      include_examples '/user/status unsuccessful response'

      include_examples '/user/status passing nil for params'

      include_examples '/user/status clear_status_after field'

      context 'when passing empty params' do
        let(:request_user) { user_with_status }

        it 'deletes the status' do
          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(user_with_status.reset.status).to be_nil
        end
      end

      context 'when clear_status_after is not given' do
        let(:params) { { emoji: 'smirk', message: 'hello world' } }
        let(:request_user) { user_with_status }

        it 'unsets clear_status_at column' do
          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(user_with_status.reset.status.clear_status_at).to be_nil
        end
      end
    end

    describe 'PATCH' do
      subject(:set_user_status) { patch api(path, request_user), params: params }

      include_examples '/user/status successful response'

      include_examples '/user/status unsuccessful response'

      include_examples '/user/status passing nil for params'

      include_examples '/user/status clear_status_after field'

      context 'when passing empty params' do
        let(:request_user) { user_with_status }

        it 'does not update the status' do
          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(user_with_status.status).to eq(user_status)
        end
      end

      context 'when clear_status_after is not given' do
        let(:params) { { emoji: 'smirk', message: 'hello world' } }
        let(:request_user) { user_with_status }

        it 'does not unset clear_status_at column' do
          set_user_status

          expect(response).to have_gitlab_http_status(:success)
          expect(user_with_status.status.clear_status_at).not_to be_nil
        end
      end
    end
  end

  describe 'PUT /user/avatar' do
    let(:path) { "/user/avatar" }

    it "returns 200 OK on success" do
      workhorse_form_with_file(
        api(path, user),
        method: :put,
        file_key: :avatar,
        params: { avatar: fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }
      )

      user.reload
      expect(user.avatar).to be_present
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['avatar_url']).to include(user.avatar_path)
    end

    it "returns 400 when avatar file size over 200 KiB" do
      workhorse_form_with_file(
        api(path, user),
        method: :put,
        file_key: :avatar,
        params: { avatar: fixture_file_upload('spec/fixtures/big-image.png', 'image/png') }
      )

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to include("Avatar is too big (should be at most 200 KiB)")
    end
  end

  describe 'POST /users/:user_id/personal_access_tokens', :with_current_organization do
    let(:name) { 'new pat' }
    let(:description) { 'new pat description' }
    let(:expires_at) { 3.days.from_now.to_date.to_s }
    let(:scopes) { %w[api read_user] }
    let(:path) { "/users/#{user.id}/personal_access_tokens" }
    let(:params) { { name: name, scopes: scopes, expires_at: expires_at, description: description } }

    it_behaves_like 'POST request permissions for admin mode'

    it 'returns error if required attributes are missing' do
      post api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('name is missing, scopes is missing')
    end

    it 'returns a 404 error if user not found' do
      post api("/users/#{non_existing_record_id}/personal_access_tokens", admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 401 error when not authenticated' do
      post api(path), params: params

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(json_response['message']).to eq('401 Unauthorized')
    end

    it 'returns a 403 error when authenticated as normal user' do
      post api(path, user), params: params

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'creates a personal access token when authenticated as admin' do
      post api(path, admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(name)
      expect(json_response['description']).to eq(description)
      expect(json_response['scopes']).to eq(scopes)
      expect(json_response['expires_at']).to eq(expires_at)
      expect(json_response['id']).to be_present
      expect(json_response['created_at']).to be_present
      expect(json_response['active']).to be_truthy
      expect(json_response['revoked']).to be_falsey
      expect(json_response['token']).to be_present
    end

    context 'when an error is thrown by the model' do
      let!(:admin_personal_access_token) { create(:personal_access_token, :admin_mode, user: admin) }
      let(:error_message) { 'error message' }

      before do
        allow_next_instance_of(PersonalAccessToken) do |personal_access_token|
          allow(personal_access_token).to receive_message_chain(:errors, :full_messages)
                                            .and_return([error_message])

          allow(personal_access_token).to receive(:save).and_return(false)
        end
      end

      it 'returns the error' do
        post api(path, personal_access_token: admin_personal_access_token), params: params

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq(error_message)
      end
    end
  end

  describe 'POST /user/personal_access_tokens', :with_current_organization do
    using RSpec::Parameterized::TableSyntax

    let(:name) { 'new pat' }
    let(:description) { 'new pat description' }
    let(:scopes) { %w[k8s_proxy] }
    let(:path) { "/user/personal_access_tokens" }
    let(:params) { { name: name, scopes: scopes, description: description } }

    let(:all_scopes) do
      ::Gitlab::Auth::API_SCOPES + ::Gitlab::Auth::AI_FEATURES_SCOPES + ::Gitlab::Auth::OPENID_SCOPES +
        ::Gitlab::Auth::PROFILE_SCOPES + ::Gitlab::Auth::REPOSITORY_SCOPES + ::Gitlab::Auth::REGISTRY_SCOPES +
        ::Gitlab::Auth::OBSERVABILITY_SCOPES + ::Gitlab::Auth::ADMIN_SCOPES
    end

    it 'returns error if required attributes are missing' do
      post api(path, user)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('name is missing, scopes is missing')
    end

    context 'when scope is not allowed' do
      where(:disallowed_scopes) do
        all_scopes - [::Gitlab::Auth::K8S_PROXY_SCOPE]
      end

      with_them do
        it 'returns error' do
          post api(path, user), params: params.merge({ scopes: [disallowed_scopes] })

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('scopes does not have a valid value')
        end
      end
    end

    it 'returns error if one of the scopes is not allowed' do
      post api(path, user), params: params.merge({ scopes: [::Gitlab::Auth::K8S_PROXY_SCOPE, ::Gitlab::Auth::API_SCOPE] })

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('scopes does not have a valid value')
    end

    it 'returns a 401 error when not authenticated' do
      post api(path), params: params

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(json_response['message']).to eq('401 Unauthorized')
    end

    it 'returns a 403 error when called with a read_api-scoped PAT' do
      read_only_pat = create(:personal_access_token, scopes: ['read_api'], user: user)
      post api(path, personal_access_token: read_only_pat), params: params

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when scopes are empty' do
      let(:scopes) { [] }

      it 'returns an error when no scopes are given' do
        post api(path, user), params: params

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq("Scopes can't be blank")
      end
    end

    it 'creates a personal access token' do
      post api(path, user), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(name)
      expect(json_response['description']).to eq(description)
      expect(json_response['scopes']).to eq(scopes)
      expect(json_response['expires_at']).to eq(1.day.from_now.to_date.to_s)
      expect(json_response['id']).to be_present
      expect(json_response['created_at']).to be_present
      expect(json_response['active']).to be_truthy
      expect(json_response['revoked']).to be_falsey
      expect(json_response['token']).to be_present
    end

    context 'when expires_at at is given' do
      let(:params) { { name: name, scopes: scopes, expires_at: expires_at, description: description } }

      context 'when expires_at is in the past' do
        let(:expires_at) { 1.day.ago }

        it 'creates an inactive personal access token' do
          post api(path, user), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['active']).to be_falsey
        end
      end

      context 'when expires_at is in the future' do
        let(:expires_at) { 1.month.from_now.to_date }

        it 'creates a personal access token' do
          post api(path, user), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['name']).to eq(name)
          expect(json_response['description']).to eq(description)
          expect(json_response['scopes']).to eq(scopes)
          expect(json_response['expires_at']).to eq(1.month.from_now.to_date.to_s)
          expect(json_response['id']).to be_present
          expect(json_response['created_at']).to be_present
          expect(json_response['active']).to be_truthy
          expect(json_response['revoked']).to be_falsey
          expect(json_response['token']).to be_present
        end
      end
    end

    context 'when an error is thrown by the model' do
      let!(:admin_personal_access_token) { create(:personal_access_token, :admin_mode, user: admin) }
      let(:error_message) { 'error message' }

      before do
        allow_next_instance_of(PersonalAccessToken) do |personal_access_token|
          allow(personal_access_token).to receive_message_chain(:errors, :full_messages)
                                            .and_return([error_message])

          allow(personal_access_token).to receive(:save).and_return(false)
        end
      end

      it 'returns the error' do
        post api(path, personal_access_token: admin_personal_access_token), params: params

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
    let(:path) { "/users/#{user.id}/impersonation_tokens" }

    it_behaves_like 'GET request permissions for admin mode'

    it 'returns a 404 error if user not found' do
      get api("/users/#{non_existing_record_id}/impersonation_tokens", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api("/users/#{non_existing_record_id}/impersonation_tokens", user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns an array of all impersonated tokens' do
      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
    end

    it 'returns an array of active impersonation tokens if state active' do
      get api("#{path}?state=active", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response).to all(include('active' => true))
    end

    it 'returns an array of inactive personal access tokens if active is set to false' do
      get api("#{path}?state=inactive", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response).to all(include('active' => false))
    end
  end

  describe 'POST /users/:user_id/impersonation_tokens', :with_current_organization do
    let(:name) { 'my new pat' }
    let(:description) { 'my new pat description' }
    let(:expires_at) { '2016-12-28' }
    let(:scopes) { %w[api read_user] }
    let(:impersonation) { true }
    let(:path) { "/users/#{user.id}/impersonation_tokens" }
    let(:params) { { name: name, expires_at: expires_at, scopes: scopes, impersonation: impersonation, description: description } }

    it_behaves_like 'POST request permissions for admin mode'

    it 'returns validation error if impersonation token misses some attributes' do
      post api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns a 404 error if user not found' do
      post api("/users/#{non_existing_record_id}/impersonation_tokens", admin, admin_mode: true),
        params: {
          name: name,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      post api(path, user),
        params: {
          name: name,
          expires_at: expires_at
        }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'creates a impersonation token' do
      post api(path, admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(name)
      expect(json_response['description']).to eq(description)
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
    let(:path) { "/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}" }

    it_behaves_like 'GET request permissions for admin mode'

    it 'returns 404 error if user not found' do
      get api("/users/#{non_existing_record_id}/impersonation_tokens/1", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      get api("/users/#{user.id}/impersonation_tokens/#{non_existing_record_id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      get api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api(path, user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns an impersonation token' do
      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['token']).not_to be_present
      expect(json_response['impersonation']).to be_truthy
    end
  end

  describe 'DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id' do
    let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
    let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let(:path) { "/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}" }

    it_behaves_like 'DELETE request permissions for admin mode'

    it 'returns a 404 error if user not found' do
      delete api("/users/#{non_existing_record_id}/impersonation_tokens/1", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      delete api("/users/#{user.id}/impersonation_tokens/#{non_existing_record_id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      delete api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      delete api(path, user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it_behaves_like '412 response' do
      let(:request) { api(path, admin, admin_mode: true) }
    end

    it 'revokes a impersonation token' do
      delete api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(impersonation_token.revoked).to be_falsey
      expect(impersonation_token.reload.revoked).to be_truthy
    end
  end

  describe 'GET /users/:id/associations_count' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let(:path) { "/users/#{user.id}/associations_count" }
    let(:associations) do
      {
        groups_count: 1,
        projects_count: 1,
        issues_count: 2,
        merge_requests_count: 1
      }.as_json
    end

    before_all do
      group.add_member(user, Gitlab::Access::OWNER)
      project.add_member(user, Gitlab::Access::OWNER)
      create(:merge_request, source_project: project, source_branch: "my-personal-branch-1", author: user)
      create_list(:issue, 2, project: project, author: user)
    end

    it_behaves_like 'GET request permissions for admin mode'

    context 'as an unauthorized user' do
      it 'returns 401 unauthorized' do
        get api(path, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'as a non-admin user' do
      context 'with a different user id' do
        it 'returns 403 Forbidden' do
          get api("/users/#{omniauth_user.id}/associations_count", user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with the current user id' do
        it 'returns valid JSON response' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_a Hash
          expect(json_response).to match(associations)
        end
      end
    end

    context 'as an admin user' do
      context 'with invalid user id' do
        it 'returns 404 User Not Found' do
          get api("/users/#{non_existing_record_id}/associations_count", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with valid user id' do
        it 'returns valid JSON response' do
          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_a Hash
          expect(json_response).to match(associations)
        end
      end
    end
  end

  it_behaves_like 'custom attributes endpoints', 'users' do
    let(:attributable) { user }
    let(:other_attributable) { admin }
  end

  describe 'POST /api/v4/user/support_pin' do
    context 'when authenticated' do
      it 'creates a new support PIN' do
        post api('/user/support_pin', user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to include('pin', 'expires_at')
      end

      it "handles errors when creating a support PIN" do
        allow_next_instance_of(Users::SupportPin::UpdateService) do |instance|
          allow(instance).to receive(:execute).and_return({ status: :error, message: "Failed to create support PIN" })
        end
        post api("/user/support_pin", user)
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Failed to create support PIN")
      end
    end

    context 'when not authenticated' do
      it 'returns 401 Unauthorized' do
        post api('/user/support_pin')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v4/user/support_pin' do
    context 'when authenticated' do
      it 'retrieves the current support PIN' do
        get api('/user/support_pin', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('pin', 'expires_at')
      end

      it 'returns 404 Not Found when no PIN exists' do
        get api('/user/support_pin', user_without_pin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v4/users/:id/support_pin' do
    context 'when authenticated as admin' do
      it 'retrieves the support PIN for a user' do
        get api("/users/#{user.id}/support_pin", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('pin', 'expires_at')
      end

      it 'returns 404 Not Found when no PIN exists' do
        get api("/users/#{user_without_pin.id}/support_pin", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "handles errors when retrieving the support PIN" do
        allow_next_instance_of(Users::SupportPin::RetrieveService) do |instance|
          allow(instance).to receive(:execute).and_raise(StandardError)
        end
        get api("/users/#{user.id}/support_pin", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Error retrieving Support PIN for user.")
      end
    end

    context 'when authenticated as non-admin' do
      it 'returns 403 Forbidden' do
        get api("/users/#{user.id}/support_pin", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
