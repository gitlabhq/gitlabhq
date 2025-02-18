# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ResourceAccessTokens::SelfRotation, feature_category: :system_access do
  let(:token) { create(:personal_access_token, user: current_user) }
  let(:expiry_date) { Time.zone.today + 1.week }
  let(:params) { {} }

  let_it_be(:current_user) { create(:user, :project_bot) }
  let_it_be(:other_user) { create(:user, :project_bot) }

  subject(:rotate_token) { post(api(path, personal_access_token: token), params: params) }

  shared_examples 'rotating token succeeds' do
    it 'rotate token', :aggregate_failures do
      rotate_token

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['token']).not_to eq(token.token)
      expect(json_response['expires_at']).to eq(expiry_date.to_s)
      expect(token.reload).to be_revoked
    end
  end

  shared_examples 'rotating token denied' do |status|
    it 'cannot rotate token' do
      rotate_token

      expect(response).to have_gitlab_http_status(status)
    end
  end

  shared_examples 'rotating resource access token' do |source_type|
    let(:resource_id) { resource.id }
    let(:path) { "/#{source_type}s/#{resource_id}/access_tokens/self/rotate" }

    describe "POST #{source_type}s/:id/access_tokens/self/rotate" do
      context 'when token is not a valid resource token' do
        context 'when token is a personal access token' do
          before do
            resource.add_guest(current_user)
          end

          context 'when current_user is an administrator', :enable_admin_mode do
            let_it_be(:current_user) { create(:admin) }

            it_behaves_like 'rotating token denied', :method_not_allowed
          end

          context 'when current_user is not an administrator' do
            let_it_be(:current_user) { create(:user) }

            it_behaves_like 'rotating token denied', :method_not_allowed
          end
        end

        context 'when token is invalid' do
          let(:token) { instance_double(PersonalAccessToken, token: 'invalidtoken') }

          it_behaves_like 'rotating token denied', :unauthorized
        end

        context 'with a revoked token' do
          let(:token) { create(:personal_access_token, :revoked, user: current_user) }

          it_behaves_like 'rotating token denied', :unauthorized
        end

        context 'with an expired token' do
          let(:token) { create(:personal_access_token, expires_at: 1.day.ago, user: current_user) }

          it_behaves_like 'rotating token denied', :unauthorized
        end

        context 'with a rotated token' do
          let(:token) { create(:personal_access_token, :revoked, user: current_user) }
          let!(:child_token) { create(:personal_access_token, previous_personal_access_token_id: token.id) }

          it_behaves_like 'rotating token denied', :unauthorized

          it 'revokes token family' do
            rotate_token

            expect(child_token.reload).to be_revoked
          end
        end

        context 'with an OAuth token' do
          subject(:rotate_token) { post(api(path, oauth_access_token: token), params: params) }

          context 'with default scope' do
            let(:token) { create(:oauth_access_token) }

            it_behaves_like 'rotating token denied', :forbidden
          end

          context 'with api or self_rotate scope' do
            let(:token) do
              create(:oauth_access_token, scopes: [Gitlab::Auth::API_SCOPE, Gitlab::Auth::SELF_ROTATE_SCOPE])
            end

            it_behaves_like 'rotating token denied', :method_not_allowed
          end
        end

        context 'with a deploy token' do
          let(:token) { create(:deploy_token) }
          let(:headers) { { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => token.token } }

          subject(:rotate_token) { post(api(path), params: params, headers: headers) }

          it_behaves_like 'rotating token denied', :unauthorized
        end

        context 'with a job token' do
          let(:job) { create(:ci_build, :running, user: current_user) }

          subject(:rotate_token) { post(api(path, job_token: job.token), params: params) }

          it_behaves_like 'rotating token denied', :unauthorized
        end
      end

      context "when token is a valid #{source_type} token" do
        it_behaves_like 'rotating token succeeds'

        context 'when expiry is defined' do
          let(:expiry_date) { Time.zone.today + 1.month }
          let(:params) { { expires_at: expiry_date } }

          it_behaves_like 'rotating token succeeds'
        end

        Gitlab::Auth.resource_bot_scopes.each do |scope|
          context "with a '#{scope}' scoped token" do
            let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

            if [Gitlab::Auth::API_SCOPE, Gitlab::Auth::SELF_ROTATE_SCOPE].include? scope
              it_behaves_like 'rotating token succeeds'
            else
              it_behaves_like 'rotating token denied', :forbidden
            end
          end

          context "with '#{scope}' and 'self_rotate' scoped token" do
            let(:token) do
              create(:personal_access_token, scopes: [scope, Gitlab::Auth::SELF_ROTATE_SCOPE], user: current_user)
            end

            it_behaves_like 'rotating token succeeds'
          end
        end
      end

      context "when token does not belong to the resource" do
        Gitlab::VisibilityLevel.string_values.each do |visibility|
          context "when resource visibility is '#{visibility}'" do
            let_it_be(:resource) { create(source_type, visibility) }

            let(:token) { create(:personal_access_token, user: other_user) }

            if Gitlab::VisibilityLevel.level_value(visibility) != Gitlab::VisibilityLevel::PRIVATE
              it_behaves_like 'rotating token denied', :unauthorized
            else
              it_behaves_like 'rotating token denied', :not_found
            end
          end
        end
      end
    end
  end

  context 'when the resource is a project' do
    let_it_be(:resource) { create(:project) }

    before_all { resource.add_guest(current_user) }

    it_behaves_like 'rotating resource access token', 'project'
  end

  context 'when the resource is a group' do
    let_it_be(:resource) { create(:group) }

    before_all { resource.add_guest(current_user) }

    it_behaves_like 'rotating resource access token', 'group'
  end
end
