# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PersonalAccessTokens, :aggregate_failures, feature_category: :system_access do
  let_it_be(:path) { '/personal_access_tokens' }

  describe 'GET /personal_access_tokens' do
    using RSpec::Parameterized::TableSyntax

    def map_id(json_resonse)
      json_response.map { |pat| pat['id'] }
    end

    shared_examples 'response as expected' do |params|
      subject { get api(path, personal_access_token: current_users_token), params: params }

      it "status, count and result as expected" do
        subject

        case status
        when :bad_request
          expect(json_response).to eq(result)
        when :ok
          expect(map_id(json_response)).to a_collection_containing_exactly(*result)
        end

        expect(response).to have_gitlab_http_status(status)
        expect(json_response.count).to eq(result_count)
      end
    end

    # Since all user types pass the same test successfully, we can avoid using
    # shared examples and test each user type separately for its expected
    # returned value.

    context 'logged in as an Administrator' do
      let_it_be(:current_user) { create(:admin) }
      let_it_be(:current_users_token) { create(:personal_access_token, :admin_mode, user: current_user) }

      it 'returns all PATs by default' do
        get api(path, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(PersonalAccessToken.all.count)
      end

      context 'filtered with user_id parameter' do
        let_it_be(:token) { create(:personal_access_token) }
        let_it_be(:token_impersonated) { create(:personal_access_token, impersonation: true, user: token.user) }

        it 'returns only PATs belonging to that user' do
          get api(path, current_user, admin_mode: true), params: { user_id: token.user.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(2)
          expect(json_response.first['user_id']).to eq(token.user.id)
          expect(json_response.last['id']).to eq(token_impersonated.id)
        end

        context 'validations for user_id parameter' do
          let_it_be(:user) { create(:user) }
          let_it_be(:admin_token) { create(:personal_access_token, :admin_mode, user: current_user) }
          let_it_be(:user_token) { create(:personal_access_token, user: user) }

          it 'returns 404 if user_id is provided but does not exist' do
            get api(path, current_user, admin_mode: true), params: { user_id: non_existing_record_id }

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq("404 Not Found")
          end

          it 'returns 404 if user_id is explicitly blank' do
            get api(path, current_user, admin_mode: true), params: { user_id: '' }

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq("404 Not Found")
          end
        end
      end

      context 'filter with revoked parameter' do
        let_it_be(:revoked_token) { create(:personal_access_token, revoked: true) }
        let_it_be(:not_revoked_token1) { create(:personal_access_token, revoked: false) }
        let_it_be(:not_revoked_token2) { create(:personal_access_token, revoked: false) }

        where(:revoked, :status, :result_count, :result) do
          true   | :ok          | 1 | lazy { [revoked_token.id] }
          false  | :ok          | 3 | lazy { [not_revoked_token1.id, not_revoked_token2.id, current_users_token.id] }
          'asdf' | :bad_request | 1 | { "error" => "revoked is invalid" }
        end

        with_them do
          it_behaves_like 'response as expected', revoked: params[:revoked]
        end
      end

      context 'filter with active parameter' do
        let_it_be(:inactive_token1) { create(:personal_access_token, revoked: true) }
        let_it_be(:inactive_token2) { create(:personal_access_token, expires_at: Time.new(2022, 01, 01, 00, 00, 00)) }
        let_it_be(:active_token) { create(:personal_access_token) }

        where(:state, :status, :result_count, :result) do
          'inactive' | :ok          | 2 | lazy { [inactive_token1.id, inactive_token2.id] }
          'active'   | :ok          | 2 | lazy { [active_token.id, current_users_token.id] }
          'asdf'     | :bad_request | 1 | { "error" => "state does not have a valid value" }
        end

        with_them do
          it_behaves_like 'response as expected', state: params[:state]
        end
      end

      context 'filter with created parameter' do
        let_it_be(:token1) { create(:personal_access_token, created_at: DateTime.new(2022, 01, 01, 12, 30, 25)) }

        context 'test created_before' do
          where(:created_at, :status, :result_count, :result) do
            '2022-01-02'           | :ok          | 1 | lazy { [token1.id] }
            '2022-01-01'           | :ok          | 0 | lazy { [] }
            '2022-01-01T12:30:24'  | :ok          | 0 | lazy { [] }
            '2022-01-01T12:30:25'  | :ok          | 1 | lazy { [token1.id] }
            '2022-01-01T:12:30:26' | :ok          | 1 | lazy { [token1.id] }
            'asdf'                 | :bad_request | 1 | { "error" => "created_before is invalid" }
          end

          with_them do
            it_behaves_like 'response as expected', created_before: params[:created_at]
          end
        end

        context 'test created_after' do
          where(:created_at, :status, :result_count, :result) do
            '2022-01-03'            | :ok          | 1 | lazy { [current_users_token.id] }
            '2022-01-01'            | :ok          | 2 | lazy { [token1.id, current_users_token.id] }
            '2022-01-01T12:30:25'   | :ok          | 2 | lazy { [token1.id, current_users_token.id] }
            '2022-01-01T12:30:26'   | :ok          | 1 | lazy { [current_users_token.id] }
            (DateTime.now + 1).to_s | :ok          | 0 | lazy { [] }
            'asdf'                  | :bad_request | 1 | { "error" => "created_after is invalid" }
          end

          with_them do
            it_behaves_like 'response as expected', created_after: params[:created_at]
          end
        end
      end

      context 'filter with last_used parameter' do
        let_it_be(:token1) { create(:personal_access_token, last_used_at: DateTime.new(2022, 01, 01, 12, 30, 25)) }
        let_it_be(:never_used_token) { create(:personal_access_token) }

        context 'test last_used_before' do
          where(:last_used_at, :status, :result_count, :result) do
            '2022-01-02'          | :ok          | 1 | lazy { [token1.id] }
            '2022-01-01'          | :ok          | 0 | lazy { [] }
            '2022-01-01T12:30:24' | :ok          | 0 | lazy { [] }
            '2022-01-01T12:30:25' | :ok          | 1 | lazy { [token1.id] }
            '2022-01-01T12:30:26' | :ok          | 1 | lazy { [token1.id] }
            'asdf'                | :bad_request | 1 | { "error" => "last_used_before is invalid" }
          end

          with_them do
            it_behaves_like 'response as expected', last_used_before: params[:last_used_at]
          end
        end

        context 'test last_used_after' do
          where(:last_used_at, :status, :result_count, :result) do
            '2022-01-03'            | :ok          | 1 | lazy { [current_users_token.id] }
            '2022-01-01'            | :ok          | 2 | lazy { [token1.id, current_users_token.id] }
            '2022-01-01T12:30:26'   | :ok          | 1 | lazy { [current_users_token.id] }
            '2022-01-01T12:30:25'   | :ok          | 2 | lazy { [token1.id, current_users_token.id] }
            (DateTime.now + 1).to_s | :ok          | 0 | lazy { [] }
            'asdf'                  | :bad_request | 1 | { "error" => "last_used_after is invalid" }
          end

          with_them do
            it_behaves_like 'response as expected', last_used_after: params[:last_used_at]
          end
        end
      end

      context 'filter with search parameter' do
        let_it_be(:token1) { create(:personal_access_token, name: 'test_1') }
        let_it_be(:token2) { create(:personal_access_token, name: 'test_2') }

        where(:pattern, :status, :result_count, :result) do
          'test'   | :ok | 2 | lazy { [token1.id, token2.id] }
          ''       | :ok | 3 | lazy { [token1.id, token2.id, current_users_token.id] }
          'test_1' | :ok | 1 | lazy { [token1.id] }
          'asdf'   | :ok | 0 | lazy { [] }
        end

        with_them do
          it_behaves_like 'response as expected', search: params[:pattern]
        end
      end

      context 'filter created_before/created_after combined with last_used_before/last_used_after' do
        let_it_be(:date) { DateTime.new(2022, 01, 02) }
        let_it_be(:token1) { create(:personal_access_token, created_at: date, last_used_at: date) }

        where(:date_before, :date_after, :status, :result_count, :result) do
          '2022-01-03' | '2022-01-01' | :ok | 1 | lazy { [token1.id] }
          '2022-01-01' | '2022-01-03' | :ok | 0 | lazy { [] }
          '2022-01-03' | nil          | :ok | 1 | lazy { [token1.id] }
          nil          | '2022-01-01' | :ok | 2 | lazy { [token1.id, current_users_token.id] }
        end

        with_them do
          it_behaves_like 'response as expected', { created_before: params[:date_before],
                                                    created_after: params[:date_after] }
          it_behaves_like 'response as expected', { last_used_before: params[:date_before],
                                                    last_used_after: params[:date_after] }
        end
      end

      context 'filter created_before and created_after combined is valid' do
        let_it_be(:token1) { create(:personal_access_token, created_at: DateTime.new(2022, 01, 02)) }

        where(:created_before, :created_after, :status, :result) do
          '2022-01-02' | '2022-01-02' | :ok | lazy { [token1.id] }
          '2022-01-03' | '2022-01-01' | :ok | lazy { [token1.id] }
          '2022-01-01' | '2022-01-03' | :ok | lazy { [] }
          '2022-01-03' | nil          | :ok | lazy { [token1.id] }
          nil          | '2022-01-01' | :ok | lazy { [token1.id] }
        end

        with_them do
          it "returns all valid tokens" do
            get api(path, personal_access_token: current_users_token),
              params: { created_before: created_before, created_after: created_after }

            expect(response).to have_gitlab_http_status(status)

            expect(json_response.map { |pat| pat['id'] }).to include(*result) if status == :ok && !result.empty?
          end
        end
      end

      context 'filter last_used_before and last_used_after combined is valid' do
        let_it_be(:token1) { create(:personal_access_token, last_used_at: DateTime.new(2022, 01, 02)) }

        where(:last_used_before, :last_used_after, :status, :result) do
          '2022-01-02' | '2022-01-02' | :ok | lazy { [token1.id] }
          '2022-01-03' | '2022-01-01' | :ok | lazy { [token1.id] }
          '2022-01-01' | '2022-01-03' | :ok | lazy { [] }
          '2022-01-03' | nil          | :ok | lazy { [token1.id] }
          nil          | '2022-01-01' | :ok | lazy { [token1.id] }
        end

        with_them do
          it "returns all valid tokens" do
            get api(path, personal_access_token: current_users_token),
              params: { last_used_before: last_used_before, last_used_after: last_used_after }

            expect(response).to have_gitlab_http_status(status)

            expect(json_response.map { |pat| pat['id'] }).to include(*result) if status == :ok && !result.empty?
          end
        end
      end
    end

    context 'logged in as a non-Administrator' do
      let_it_be(:current_user) { create(:user) }
      let_it_be(:current_users_token) { create(:personal_access_token, user: current_user) }

      it 'returns all PATs belonging to the signed-in user' do
        get api(path, personal_access_token: current_users_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(1)
        expect(json_response.map { |r| r['id'] }.uniq).to contain_exactly(current_users_token.id)
        expect(json_response.map { |r| r['user_id'] }.uniq).to contain_exactly(current_user.id)
      end

      context 'filtered with user_id parameter' do
        let_it_be(:user) { create(:user) }

        it 'returns PATs belonging to the specific user' do
          get api(path, current_user, personal_access_token: current_users_token), params: { user_id: current_user.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(1)
          expect(json_response.map { |r| r['id'] }.uniq).to contain_exactly(current_users_token.id)
          expect(json_response.map { |r| r['user_id'] }.uniq).to contain_exactly(current_user.id)
        end

        it 'is unauthorized if filtered by a user other than current_user' do
          get api(path, current_user, personal_access_token: current_users_token), params: { user_id: user.id }

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'filter with revoked parameter' do
        let_it_be(:users_revoked_token) { create(:personal_access_token, revoked: true, user: current_user) }
        let_it_be(:not_revoked_token) { create(:personal_access_token, revoked: false) }
        let_it_be(:oter_revoked_token) { create(:personal_access_token, revoked: true) }

        where(:revoked, :status, :result_count, :result) do
          true   | :ok          | 1 | lazy { [users_revoked_token.id] }
          false  | :ok          | 1 | lazy { [current_users_token.id] }
        end

        with_them do
          it_behaves_like 'response as expected', revoked: params[:revoked]
        end
      end

      context 'filter with active parameter' do
        let_it_be(:users_inactive_token) { create(:personal_access_token, revoked: true, user: current_user) }
        let_it_be(:inactive_token) { create(:personal_access_token, expires_at: Time.new(2022, 01, 01, 00, 00, 00)) }
        let_it_be(:other_active_token) { create(:personal_access_token) }

        where(:state, :status, :result_count, :result) do
          'inactive' | :ok          | 1 | lazy { [users_inactive_token.id] }
          'active'   | :ok          | 1 | lazy { [current_users_token.id] }
        end

        with_them do
          it_behaves_like 'response as expected', state: params[:state]
        end
      end

      # The created_before filter has been extensively tested in the 'logged in as administrator' section.
      # Here it is only tested whether PATs to which the user has no access right are excluded from the filter function.
      context 'filter with created parameter' do
        let_it_be(:token1) do
          create(:personal_access_token, created_at: DateTime.new(2022, 01, 02, 12, 30, 25), user: current_user)
        end

        let_it_be(:token2) { create(:personal_access_token, created_at: DateTime.new(2022, 01, 02, 12, 30, 25)) }
        let_it_be(:status) { :ok }

        context 'created_before' do
          let_it_be(:result_count) { 1 }
          let_it_be(:result) { [token1.id] }

          it_behaves_like 'response as expected', created_before: '2022-01-03'
        end

        context 'created_after' do
          let_it_be(:result_count) { 2 }
          let_it_be(:result) { [token1.id, current_users_token.id] }

          it_behaves_like 'response as expected', created_after: '2022-01-01'
        end
      end

      # The last_used_before filter has been extensively tested in the 'logged in as administrator' section.
      # Here it is only tested whether PATs to which the user has no access right are excluded from the filter function.
      context 'filter with last_used' do
        let_it_be(:token1) do
          create(:personal_access_token, last_used_at: DateTime.new(2022, 01, 01, 12, 30, 25), user: current_user)
        end

        let_it_be(:token2) { create(:personal_access_token, last_used_at: DateTime.new(2022, 01, 01, 12, 30, 25)) }
        let_it_be(:never_used_token) { create(:personal_access_token) }
        let_it_be(:status) { :ok }

        context 'last_used_before' do
          let_it_be(:result_count) { 1 }
          let_it_be(:result) { [token1.id] }

          it_behaves_like 'response as expected', last_used_before: '2022-01-02'
        end

        context 'last_used_after' do
          let_it_be(:result_count) { 2 }
          let_it_be(:result) { [token1.id, current_users_token.id] }

          it_behaves_like 'response as expected', last_used_after: '2022-01-01'
        end
      end

      # The search filter has been extensively tested in the 'logged in as administrator' section.
      # Here it is only tested whether PATs to which the user has no access right are excluded from the filter function.
      context 'filter with search parameter' do
        let_it_be(:token1) { create(:personal_access_token, name: 'test_1', user: current_user) }
        let_it_be(:token2) { create(:personal_access_token, name: 'test_1') }

        where(:pattern, :status, :result_count, :result) do
          'test'   | :ok | 1 | lazy { [token1.id] }
          ''       | :ok | 2 | lazy { [token1.id, current_users_token.id] }
          'test_1' | :ok | 1 | lazy { [token1.id] }
        end

        with_them do
          it_behaves_like 'response as expected', search: params[:pattern]
        end
      end
    end

    context 'not authenticated' do
      it 'is forbidden' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /personal_access_tokens/:id' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user_token) { create(:personal_access_token, user: current_user) }
    let_it_be(:token1) { create(:personal_access_token) }
    let_it_be(:user_read_only_token) { create(:personal_access_token, scopes: ['read_repository'], user: current_user) }
    let_it_be(:user_token_path) { "/personal_access_tokens/#{user_token.id}" }
    let_it_be(:invalid_path) { "/personal_access_tokens/#{non_existing_record_id}" }

    context 'when current_user is an administrator', :enable_admin_mode do
      let_it_be(:admin_user) { create(:admin) }
      let_it_be(:admin_token) { create(:personal_access_token, user: admin_user) }
      let_it_be(:admin_path) { "/personal_access_tokens/#{admin_token.id}" }

      it 'returns admins own PAT by id' do
        get api(admin_path, admin_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(admin_token.id)
      end

      it 'returns a different users PAT by id' do
        get api(user_token_path, admin_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user_token.id)
      end

      it 'fails to return PAT because no PAT exists with this id' do
        get api(invalid_path, admin_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when current_user is not an administrator' do
      let_it_be(:other_users_path) { "/personal_access_tokens/#{token1.id}" }

      it 'returns users own PAT by id' do
        get api(user_token_path, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user_token.id)
      end

      context 'when an ip is recently used' do
        let(:current_ip_address) { '127.0.0.1' }

        it 'returns ips used' do
          get api(user_token_path, current_user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['last_used_ips']).to match_array(user_token.last_used_ips)
        end
      end

      context 'when there is not an ip recently used' do
        it 'does not return an ip' do
          get api(user_token_path, current_user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['last_used_ip']).to be_nil
        end
      end

      it 'fails to return other users PAT by id' do
        get api(other_users_path, current_user)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'fails to return PAT because no PAT exists with this id' do
        get api(invalid_path, current_user)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'fails to return own PAT by id with read_repository token' do
        get api(user_token_path, current_user, personal_access_token: user_read_only_token)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /personal_access_tokens/:id/rotate' do
    let_it_be(:token) { create(:personal_access_token) }

    let(:path) { "/personal_access_tokens/#{token.id}/rotate" }

    it "rotates user's own token", :freeze_time do
      post api(path, token.user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['token']).not_to eq(token.token)
      expect(json_response['expires_at']).to eq((Date.today + 1.week).to_s)
    end

    context 'when expiry is defined' do
      it "rotates user's own token", :freeze_time do
        expiry_date = Date.today + 1.month

        post(api(path, token.user), params: { expires_at: expiry_date })

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['token']).not_to eq(token.token)
        expect(json_response['expires_at']).to eq(expiry_date.to_s)
      end
    end

    context 'when require_token_expiry is false' do
      before do
        stub_application_setting(require_personal_access_token_expiry: false)
      end

      context 'when expiry is not defined' do
        it "rotates user's own token with no expiration", :freeze_time do
          post(api(path, token.user))

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['token']).not_to eq(token.token)
          expect(json_response['expires_at']).to be_nil
        end
      end
    end

    context 'without permission' do
      it 'returns an error message' do
        another_user = create(:user)
        post api(path, another_user)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when service raises an error' do
      let(:error_message) { 'boom!' }

      before do
        allow_next_instance_of(PersonalAccessTokens::RotateService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
        end
      end

      it 'returns the same error message' do
        post api(path, token.user)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq("400 Bad request - #{error_message}")
      end
    end

    context 'when token does not exist' do
      let(:invalid_path) { "/personal_access_tokens/#{non_existing_record_id}/rotate" }

      context 'for non-admin user' do
        it 'returns unauthorized' do
          user = create(:user)
          post api(invalid_path, user)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'for admin user', :enable_admin_mode do
        it 'returns not found' do
          admin = create(:admin)
          post api(invalid_path, admin)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE /personal_access_tokens/:id' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:token1) { create(:personal_access_token) }

    let(:path) { "/personal_access_tokens/#{token1.id}" }

    context 'when current_user is an administrator', :enable_admin_mode do
      let_it_be(:admin_user) { create(:admin) }
      let_it_be(:admin_token) { create(:personal_access_token, user: admin_user) }
      let_it_be(:admin_path) { "/personal_access_tokens/#{admin_token.id}" }
      let_it_be(:admin_read_only_token) do
        create(:personal_access_token, scopes: ['read_repository'], user: admin_user)
      end

      it 'revokes a different users token' do
        delete api(path, admin_user)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(token1.reload.revoked?).to be true
      end

      it 'revokes their own token' do
        delete api(admin_path, admin_user)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'fails to revoke a different user token using a readonly scope' do
        delete api(path, personal_access_token: admin_read_only_token)

        expect(token1.reload.revoked?).to be false
      end
    end

    context 'when current_user is not an administrator' do
      let_it_be(:user_token) { create(:personal_access_token, user: current_user) }
      let_it_be(:user_token_path) { "/personal_access_tokens/#{user_token.id}" }
      let_it_be(:token_impersonated) { create(:personal_access_token, impersonation: true, user: current_user) }

      it 'fails revokes a different users token' do
        delete api(path, current_user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'revokes their own token' do
        delete api(user_token_path, current_user)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'cannot revoke impersonation token' do
        delete api("/personal_access_tokens/#{token_impersonated.id}", current_user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
