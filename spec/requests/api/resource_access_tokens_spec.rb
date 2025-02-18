# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::ResourceAccessTokens, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:user_non_priviledged) { create(:user) }

  shared_examples 'resource access token API' do |source_type|
    context "GET #{source_type}s/:id/access_tokens" do
      subject(:get_tokens) { get api("/#{source_type}s/#{resource_id}/access_tokens", user) }

      context "when the user has valid permissions" do
        let_it_be(:project_bot) { create(:user, :project_bot) }
        let_it_be(:active_access_tokens) { create_list(:personal_access_token, 5, user: project_bot) }
        let_it_be(:expired_token) { create(:personal_access_token, :expired, user: project_bot) }
        let_it_be(:revoked_token) { create(:personal_access_token, :revoked, user: project_bot) }
        let_it_be(:inactive_access_tokens) { [expired_token, revoked_token] }
        let_it_be(:all_access_tokens) { active_access_tokens + inactive_access_tokens }
        let_it_be(:resource_id) { resource.id }

        before do
          if source_type == 'project'
            resource.add_maintainer(project_bot)
          else
            resource.add_owner(project_bot)
          end
        end

        it "gets a list of all access tokens for the specified #{source_type}" do
          get_tokens

          token_ids = json_response.map { |token| token['id'] }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(response).to match_response_schema('public_api/v4/resource_access_tokens')
          expect(token_ids).to match_array(all_access_tokens.pluck(:id))
        end

        it "exposes the correct token information", :aggregate_failures do
          get_tokens

          token = all_access_tokens.last
          api_get_token = json_response.last

          expect(api_get_token["name"]).to eq(token.name)
          expect(api_get_token["scopes"]).to eq(token.scopes)

          if source_type == 'project'
            expect(api_get_token["access_level"]).to eq(resource.team.max_member_access(token.user.id))
          else
            expect(api_get_token["access_level"]).to eq(resource.max_member_access_for_user(token.user))
          end

          expect(api_get_token["expires_at"]).to eq(token.expires_at.to_date.iso8601)
          expect(api_get_token).not_to have_key('token')
        end

        context "when using a #{source_type} access token to GET other #{source_type} access tokens" do
          let_it_be(:token) { active_access_tokens.first }

          it "gets a list of access tokens for the specified #{source_type}" do
            get api("/#{source_type}s/#{resource_id}/access_tokens", personal_access_token: token)

            token_ids = json_response.map { |token| token['id'] }

            expect(response).to have_gitlab_http_status(:ok)
            expect(token_ids).to match_array(all_access_tokens.pluck(:id))
          end
        end

        context "when tokens belong to a different #{source_type}" do
          let_it_be(:bot) { create(:user, :project_bot) }
          let_it_be(:token) { create(:personal_access_token, user: bot) }

          before do
            other_resource.add_maintainer(bot)
          end

          it "does not return tokens from a different #{source_type}" do
            get_tokens

            token_ids = json_response.map { |token| token['id'] }

            expect(token_ids).not_to include(token.id)
          end
        end

        context "when the #{source_type} has no access tokens" do
          let(:resource_id) { other_resource.id }

          it 'returns an empty array' do
            get_tokens

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq([])
          end
        end

        context "when trying to get the tokens of a different #{source_type}" do
          let_it_be(:resource_id) { unknown_resource.id }

          it "returns 404" do
            get_tokens

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context "when the #{source_type} does not exist" do
          let(:resource_id) { non_existing_record_id }

          it "returns 404" do
            get_tokens

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when state param is set to inactive' do
          let(:params) { { state: 'inactive' } }

          it 'returns only inactive tokens' do
            get api("/#{source_type}s/#{resource_id}/access_tokens", user), params: params

            token_ids = json_response.map { |token| token['id'] }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(response).to match_response_schema('public_api/v4/resource_access_tokens')
            expect(token_ids).to match_array(inactive_access_tokens.pluck(:id))
          end
        end

        context 'when state param is set to active' do
          let(:params) { { state: 'active' } }

          it 'returns only active tokens' do
            get api("/#{source_type}s/#{resource_id}/access_tokens", user), params: params

            token_ids = json_response.map { |token| token['id'] }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(response).to match_response_schema('public_api/v4/resource_access_tokens')
            expect(token_ids).to match_array(active_access_tokens.pluck(:id))
          end
        end
      end

      context "when the user does not have valid permissions" do
        let_it_be(:user) { user_non_priviledged }
        let_it_be(:project_bot) { create(:user, :project_bot) }
        let_it_be(:access_tokens) { create_list(:personal_access_token, 3, user: project_bot) }
        let_it_be(:resource_id) { resource.id }

        before do
          resource.add_maintainer(project_bot)
        end

        it "returns 401" do
          get_tokens

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context "GET #{source_type}s/:id/access_tokens/:token_id" do
      subject(:get_token) { get api("/#{source_type}s/#{resource_id}/access_tokens/#{token_id}", user) }

      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:token) { create(:personal_access_token, user: project_bot) }
      let_it_be(:resource_id) { resource.id }
      let_it_be(:token_id) { token.id }

      before do
        if source_type == 'project'
          resource.add_maintainer(project_bot)
        else
          resource.add_owner(project_bot)
        end
      end

      context "when the user has valid permissions" do
        it "gets the #{source_type} access token from the #{source_type}" do
          get_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/resource_access_token')

          expect(json_response["name"]).to eq(token.name)
          expect(json_response["scopes"]).to eq(token.scopes)

          if source_type == 'project'
            expect(json_response["access_level"]).to eq(resource.team.max_member_access(token.user.id))
          else
            expect(json_response["access_level"]).to eq(resource.max_member_access_for_user(token.user))
          end

          expect(json_response["expires_at"]).to eq(token.expires_at.to_date.iso8601)
        end

        context "when using #{source_type} access token to GET other #{source_type} access token" do
          let_it_be(:other_project_bot) { create(:user, :project_bot) }
          let_it_be(:other_token) { create(:personal_access_token, user: other_project_bot) }
          let_it_be(:token_id) { other_token.id }

          before do
            resource.add_maintainer(other_project_bot)
          end

          it "gets the #{source_type} access token from the #{source_type}" do
            get_token

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/resource_access_token')

            expect(json_response["name"]).to eq(other_token.name)
            expect(json_response["scopes"]).to eq(other_token.scopes)

            if source_type == 'project'
              expect(json_response["access_level"]).to eq(resource.team.max_member_access(other_token.user.id))
            else
              expect(json_response["access_level"]).to eq(resource.max_member_access_for_user(other_token.user))
            end

            expect(json_response["expires_at"]).to eq(other_token.expires_at.to_date.iso8601)
          end
        end

        context "when attempting to get a non-existent #{source_type} access token" do
          let_it_be(:token_id) { non_existing_record_id }

          it "does not get the token, and returns 404" do
            get_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("Could not find #{source_type} access token with token_id: #{token_id}")
          end
        end

        context "when attempting to get a token that does not belong to the specified #{source_type}" do
          let_it_be(:resource_id) { other_resource.id }

          it "does not get the token, and returns 404" do
            get_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("Could not find #{source_type} access token with token_id: #{token_id}")
          end
        end
      end

      context "when the user does not have valid permissions" do
        let_it_be(:user) { user_non_priviledged }

        it "returns 401" do
          get_token

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context "DELETE #{source_type}s/:id/access_tokens/:token_id", :sidekiq_inline do
      subject(:delete_token) { delete api("/#{source_type}s/#{resource_id}/access_tokens/#{token_id}", user) }

      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:token) { create(:personal_access_token, user: project_bot) }
      let_it_be(:resource_id) { resource.id }
      let_it_be(:token_id) { token.id }

      before do
        resource.add_maintainer(project_bot)
      end

      context "when the user has valid permissions" do
        it "deletes the #{source_type} access token from the #{source_type}" do
          delete_token

          expect(response).to have_gitlab_http_status(:no_content)
          expect(token.reload).to be_revoked
          expect(User.exists?(project_bot.id)).to be_truthy
        end

        context "when using #{source_type} access token to DELETE other #{source_type} access token" do
          let_it_be(:other_project_bot) { create(:user, :project_bot) }
          let_it_be(:other_token) { create(:personal_access_token, user: other_project_bot) }
          let_it_be(:token_id) { other_token.id }

          before do
            resource.add_maintainer(other_project_bot)
          end

          it "deletes the #{source_type} access token from the #{source_type}" do
            delete_token

            expect(response).to have_gitlab_http_status(:no_content)
            expect(token.reload).not_to be_revoked
            expect(other_token.reload).to be_revoked
            expect(User.exists?(other_project_bot.id)).to be_truthy
          end
        end

        context "when attempting to delete a non-existent #{source_type} access token" do
          let_it_be(:token_id) { non_existing_record_id }

          it "does not delete the token, and returns 404" do
            delete_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("Could not find #{source_type} access token with token_id: #{token_id}")
          end
        end

        context "when attempting to delete a token that does not belong to the specified #{source_type}" do
          let_it_be(:resource_id) { other_resource.id }

          it "does not delete the token, and returns 404" do
            delete_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("Could not find #{source_type} access token with token_id: #{token_id}")
          end
        end
      end

      context "when the user does not have valid permissions" do
        let_it_be(:user) { user_non_priviledged }

        it "does not delete the token, and returns 400", :aggregate_failures do
          delete_token

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(User.exists?(project_bot.id)).to be_truthy
          expect(response.body).to include("#{user.name} cannot delete #{token.user.name}")
        end
      end
    end

    context "POST #{source_type}s/:id/access_tokens" do
      let(:params) { { name: "test", scopes: ["api"], expires_at: expires_at, access_level: access_level } }
      let(:expires_at) { 1.month.from_now }
      let(:access_level) { 20 }

      subject(:create_token) { post api("/#{source_type}s/#{resource_id}/access_tokens", user), params: params }

      context "when the user has valid permissions" do
        let_it_be(:resource_id) { resource.id }

        context "with valid params" do
          context "with full params" do
            it "creates a #{source_type} access token with the params", :aggregate_failures do
              create_token

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response["name"]).to eq("test")
              expect(json_response["scopes"]).to eq(["api"])
              expect(json_response["access_level"]).to eq(20)
              expect(json_response["expires_at"]).to eq(expires_at.to_date.iso8601)
              expect(json_response["token"]).to be_present
            end
          end

          context "when 'expires_at' is not set" do
            let(:expires_at) { nil }

            it "creates a #{source_type} access token with the default expires_at value", :aggregate_failures do
              freeze_time do
                create_token
                expires_at = PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response["name"]).to eq("test")
                expect(json_response["scopes"]).to eq(["api"])
                expect(json_response["expires_at"]).to eq(expires_at.to_date.iso8601)
              end
            end
          end

          context "when 'access_level' is not set" do
            let(:access_level) { nil }

            it "creates a #{source_type} access token with the default access level", :aggregate_failures do
              create_token

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response["name"]).to eq("test")
              expect(json_response["scopes"]).to eq(["api"])
              expect(json_response["access_level"]).to eq(40)
              expect(json_response["expires_at"]).to eq(expires_at.to_date.iso8601)
              expect(json_response["token"]).to be_present
            end
          end
        end

        context "with invalid params" do
          context "when missing the 'name' param" do
            let_it_be(:params) { { scopes: ["api"], expires_at: 5.days.from_now } }

            it "does not create a #{source_type} access token without 'name'" do
              create_token

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include("name is missing")
            end
          end

          context "when missing the 'scopes' param" do
            let_it_be(:params) { { name: "test", expires_at: 5.days.from_now } }

            it "does not create a #{source_type} access token without 'scopes'" do
              create_token

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include("scopes is missing")
            end
          end

          context "when using invalid 'scopes'" do
            let_it_be(:params) do
              {
                name: "test",
                scopes: ["test"],
                expires_at: 5.days.from_now
              }
            end

            it "does not create a #{source_type} access token with invalid 'scopes'", :aggregate_failures do
              create_token

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include("scopes does not have a valid value")
            end
          end

          context "when using invalid 'access_level'" do
            let_it_be(:params) do
              {
                name: "test",
                scopes: ["api"],
                expires_at: 5.days.from_now,
                access_level: Gitlab::Access::NO_ACCESS
              }
            end

            it "does not create a #{source_type} access token with invalid 'access_level'", :aggregate_failures do
              create_token

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include("access_level does not have a valid value")
            end
          end
        end

        context "when trying to create a token in a different #{source_type}" do
          let_it_be(:resource_id) { unknown_resource.id }

          it "does not create the token, and returns the #{source_type} not found error" do
            create_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("#{source_type.capitalize} Not Found")
          end
        end
      end

      context "when the user does not have valid permissions" do
        let_it_be(:resource_id) { resource.id }

        context "when the user role is too low" do
          let_it_be(:user) { user_non_priviledged }

          it "does not create the token, and returns the permission error" do
            create_token

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to include("User does not have permission to create #{source_type} access token")
          end
        end

        context "when a #{source_type} access token tries to create another #{source_type} access token" do
          let_it_be(:project_bot) { create(:user, :project_bot) }
          let_it_be(:user) { project_bot }

          before do
            if source_type == 'project'
              resource.add_maintainer(project_bot)
            else
              resource.add_owner(project_bot)
            end
          end

          it "does not allow a #{source_type} access token to create another #{source_type} access token" do
            create_token

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to include("User does not have permission to create #{source_type} access token")
          end
        end
      end
    end

    context "POST #{source_type}s/:id/access_tokens/:token_id/rotate" do
      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:token) { create(:personal_access_token, user: project_bot) }
      let_it_be(:resource_id) { resource.id }
      let_it_be(:token_id) { token.id }
      let(:params) { {} }

      let(:path) { "/#{source_type}s/#{resource_id}/access_tokens/#{token_id}/rotate" }

      subject(:rotate_token) { post(api(path, user), params: params) }

      context 'when user is owner' do
        before do
          resource.add_maintainer(project_bot)
          resource.add_owner(user)
        end

        it "allows owner to rotate token", :freeze_time do
          rotate_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['token']).not_to eq(token.token)
          expect(json_response['expires_at']).to eq((Date.today + 1.week).to_s)
        end
      end

      context 'when user is maintainer' do
        before do
          resource.add_maintainer(user)
        end

        context "when token has owner access level" do
          let(:error_message) { 'Not eligible to rotate token with access level higher than the user' }

          before do
            resource.add_owner(project_bot)
          end

          it "raises error" do
            rotate_token

            if source_type == 'project'
              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to eq("400 Bad request - #{error_message}")
            else
              expect(response).to have_gitlab_http_status(:unauthorized)
            end
          end
        end

        context 'when token has maintainer access level' do
          before do
            resource.add_maintainer(project_bot)
          end

          it "rotates token", :freeze_time do
            rotate_token

            if source_type == 'project'
              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['token']).not_to eq(token.token)
              expect(json_response['expires_at']).to eq((Date.today + 1.week).to_s)
            else
              expect(response).to have_gitlab_http_status(:unauthorized)
            end
          end
        end
      end

      context 'when expiry is defined' do
        let(:expiry_date) { Date.today + 1.month }
        let(:params) { { expires_at: expiry_date } }

        before do
          resource.add_maintainer(project_bot)
          resource.add_owner(user)
        end

        it "allows owner to rotate token", :freeze_time do
          rotate_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['token']).not_to eq(token.token)
          expect(json_response['expires_at']).to eq(expiry_date.to_s)
        end
      end

      context 'without permission' do
        before do
          resource.add_maintainer(project_bot)
          resource.add_owner(user)
        end

        it 'returns an error message' do
          another_user = create(:user)
          resource.add_developer(another_user)

          post api(path, another_user)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when service raises an error' do
        let(:error_message) { 'boom!' }
        let(:personal_token_service) { PersonalAccessTokens::RotateService }
        let(:project_token_service) { ProjectAccessTokens::RotateService }
        let(:group_token_service) { GroupAccessTokens::RotateService }

        before do
          resource.add_maintainer(project_bot)
          resource.add_owner(user)

          if source_type == 'project'
            allow_next_instance_of(project_token_service) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
            end
          elsif source_type == 'group'
            allow_next_instance_of(group_token_service) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
            end
          else
            allow_next_instance_of(personal_token_service) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
            end
          end
        end

        it 'returns the same error message' do
          rotate_token

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("400 Bad request - #{error_message}")
        end
      end

      context 'when token does not exist' do
        let(:invalid_path) { "/#{source_type}s/#{resource_id}/access_tokens/#{non_existing_record_id}/rotate" }

        context 'for non-admin user' do
          it 'returns unauthorized' do
            user = create(:user)
            resource.add_developer(user)

            post api(invalid_path, user)

            expect(response).to have_gitlab_http_status(:unauthorized)
          end
        end

        context 'for admin user', :enable_admin_mode do
          it 'returns not found', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448693' do
            admin = create(:admin)
            post api(invalid_path, admin)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  context 'when the resource is a project' do
    let_it_be(:resource) { create(:project, group: create(:group)) }
    let_it_be(:other_resource) { create(:project) }
    let_it_be(:unknown_resource) { create(:project) }

    before_all do
      resource.add_maintainer(user)
      other_resource.add_maintainer(user)
      resource.add_developer(user_non_priviledged)
    end

    it_behaves_like 'resource access token API', 'project'
  end

  context 'when the resource is a group' do
    let_it_be(:resource) { create(:group) }
    let_it_be(:other_resource) { create(:group) }
    let_it_be(:unknown_resource) { create(:project) }

    before_all do
      resource.add_owner(user)
      other_resource.add_owner(user)
      resource.add_maintainer(user_non_priviledged)
    end

    it_behaves_like 'resource access token API', 'group'
  end
end
