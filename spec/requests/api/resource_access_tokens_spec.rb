# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::ResourceAccessTokens do
  context "when the resource is a project" do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:user) { create(:user) }

    describe "GET projects/:id/access_tokens" do
      subject(:get_tokens) { get api("/projects/#{project_id}/access_tokens", user) }

      context "when the user has maintainer permissions" do
        let_it_be(:project_bot) { create(:user, :project_bot) }
        let_it_be(:access_tokens) { create_list(:personal_access_token, 3, user: project_bot) }
        let_it_be(:project_id) { project.id }

        before do
          project.add_maintainer(user)
          project.add_maintainer(project_bot)
        end

        it "gets a list of access tokens for the specified project" do
          get_tokens

          token_ids = json_response.map { |token| token['id'] }

          expect(response).to have_gitlab_http_status(:ok)
          expect(token_ids).to match_array(access_tokens.pluck(:id))
        end

        it "exposes the correct token information", :aggregate_failures do
          get_tokens

          token = access_tokens.last
          api_get_token = json_response.last

          expect(api_get_token["name"]).to eq(token.name)
          expect(api_get_token["scopes"]).to eq(token.scopes)
          expect(api_get_token["access_level"]).to eq(project.team.max_member_access(token.user.id))
          expect(api_get_token["expires_at"]).to eq(token.expires_at.to_date.iso8601)
          expect(api_get_token).not_to have_key('token')
        end

        context "when using a project access token to GET other project access tokens" do
          let_it_be(:token) { access_tokens.first }

          it "gets a list of access tokens for the specified project" do
            get api("/projects/#{project_id}/access_tokens", personal_access_token: token)

            token_ids = json_response.map { |token| token['id'] }

            expect(response).to have_gitlab_http_status(:ok)
            expect(token_ids).to match_array(access_tokens.pluck(:id))
          end
        end

        context "when tokens belong to a different project" do
          let_it_be(:bot) { create(:user, :project_bot) }
          let_it_be(:token) { create(:personal_access_token, user: bot) }

          before do
            other_project.add_maintainer(bot)
            other_project.add_maintainer(user)
          end

          it "does not return tokens from a different project" do
            get_tokens

            token_ids = json_response.map { |token| token['id'] }

            expect(token_ids).not_to include(token.id)
          end
        end

        context "when the project has no access tokens" do
          let(:project_id) { other_project.id }

          before do
            other_project.add_maintainer(user)
          end

          it 'returns an empty array' do
            get_tokens

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq([])
          end
        end

        context "when trying to get the tokens of a different project" do
          let_it_be(:project_id) { other_project.id }

          it "returns 404" do
            get_tokens

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context "when the project does not exist" do
          let(:project_id) { non_existing_record_id }

          it "returns 404" do
            get_tokens

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context "when the user does not have valid permissions" do
        let_it_be(:project_bot) { create(:user, :project_bot) }
        let_it_be(:access_tokens) { create_list(:personal_access_token, 3, user: project_bot) }
        let_it_be(:project_id) { project.id }

        before do
          project.add_developer(user)
          project.add_maintainer(project_bot)
        end

        it "returns 401" do
          get_tokens

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    describe "DELETE projects/:id/access_tokens/:token_id", :sidekiq_inline do
      subject(:delete_token) { delete api("/projects/#{project_id}/access_tokens/#{token_id}", user) }

      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:token) { create(:personal_access_token, user: project_bot) }
      let_it_be(:project_id) { project.id }
      let_it_be(:token_id) { token.id }

      before do
        project.add_maintainer(project_bot)
      end

      context "when the user has maintainer permissions" do
        before do
          project.add_maintainer(user)
        end

        it "deletes the project access token from the project" do
          delete_token

          expect(response).to have_gitlab_http_status(:no_content)
          expect(User.exists?(project_bot.id)).to be_falsy
        end

        context "when using project access token to DELETE other project access token" do
          let_it_be(:other_project_bot) { create(:user, :project_bot) }
          let_it_be(:other_token) { create(:personal_access_token, user: other_project_bot) }
          let_it_be(:token_id) { other_token.id }

          before do
            project.add_maintainer(other_project_bot)
          end

          it "deletes the project access token from the project" do
            delete_token

            expect(response).to have_gitlab_http_status(:no_content)
            expect(User.exists?(other_project_bot.id)).to be_falsy
          end
        end

        context "when attempting to delete a non-existent project access token" do
          let_it_be(:token_id) { non_existing_record_id }

          it "does not delete the token, and returns 404" do
            delete_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("Could not find project access token with token_id: #{token_id}")
          end
        end

        context "when attempting to delete a token that does not belong to the specified project" do
          let_it_be(:project_id) { other_project.id }

          before do
            other_project.add_maintainer(user)
          end

          it "does not delete the token, and returns 404" do
            delete_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("Could not find project access token with token_id: #{token_id}")
          end
        end
      end

      context "when the user does not have valid permissions" do
        before do
          project.add_developer(user)
        end

        it "does not delete the token, and returns 400", :aggregate_failures do
          delete_token

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(User.exists?(project_bot.id)).to be_truthy
          expect(response.body).to include("#{user.name} cannot delete #{token.user.name}")
        end
      end
    end

    describe "POST projects/:id/access_tokens" do
      let(:params) { { name: "test", scopes: ["api"], expires_at: expires_at, access_level: access_level } }
      let(:expires_at) { 1.month.from_now }
      let(:access_level) { 20 }

      subject(:create_token) { post api("/projects/#{project_id}/access_tokens", user), params: params }

      context "when the user has maintainer permissions" do
        let_it_be(:project_id) { project.id }

        before do
          project.add_maintainer(user)
        end

        context "with valid params" do
          context "with full params" do
            it "creates a project access token with the params", :aggregate_failures do
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

            it "creates a project access token with the params", :aggregate_failures do
              create_token

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response["name"]).to eq("test")
              expect(json_response["scopes"]).to eq(["api"])
              expect(json_response["expires_at"]).to eq(nil)
            end
          end

          context "when 'access_level' is not set" do
            let(:access_level) { nil }

            it 'creates a project access token with the default access level', :aggregate_failures do
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

            it "does not create a project access token without 'name'" do
              create_token

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include("name is missing")
            end
          end

          context "when missing the 'scopes' param" do
            let_it_be(:params) { { name: "test", expires_at: 5.days.from_now } }

            it "does not create a project access token without 'scopes'" do
              create_token

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include("scopes is missing")
            end
          end
        end

        context "when trying to create a token in a different project" do
          let_it_be(:project_id) { other_project.id }

          it "does not create the token, and returns the project not found error" do
            create_token

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include("Project Not Found")
          end
        end
      end

      context "when the user does not have valid permissions" do
        let_it_be(:project_id) { project.id }

        context "when the user is a developer" do
          before do
            project.add_developer(user)
          end

          it "does not create the token, and returns the permission error" do
            create_token

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to include("User does not have permission to create project access token")
          end
        end

        context "when a project access token tries to create another project access token" do
          let_it_be(:project_bot) { create(:user, :project_bot) }
          let_it_be(:user) { project_bot }

          before do
            project.add_maintainer(user)
          end

          it "does not allow a project access token to create another project access token" do
            create_token

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to include("User does not have permission to create project access token")
          end
        end
      end
    end
  end
end
