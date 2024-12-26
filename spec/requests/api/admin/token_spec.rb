# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Token, :aggregate_failures, feature_category: :system_access do
  shared_examples 'rejecting invalid requests with admin' do
    context 'with non-existing token' do
      let(:plaintext) { "#{personal_access_token.token}-non-existing" }

      it_behaves_like 'returning response status', :not_found
    end

    context 'with unsupported token type' do
      let(:plaintext) { 'unsupported' }

      it_behaves_like 'returning response status', :unprocessable_entity
    end
  end

  shared_examples 'rejecting requests with invalid or missing authorization' do
    context 'when the user is not an admin' do
      let(:api_user) { user }

      it_behaves_like 'returning response status', :forbidden
    end

    context 'without a user' do
      let(:api_user) { nil }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:url) { '/admin/token' }
  let(:api_user) { admin }
  let(:user) { create(:user) }

  let_it_be(:project_bot) { create(:user, :project_bot) }
  let_it_be(:group_bot) { create(:user, :project_bot) }
  let_it_be(:project_member) { create(:project_member, source: project, user: project_bot) }
  let_it_be(:group_member) { create(:group_member, source: group, user: group_bot) }

  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:project_access_token) { create(:personal_access_token, user: project_bot) }
  let(:group_access_token) { create(:personal_access_token, user: group_bot) }
  let(:group_deploy_token) { create(:deploy_token, :group, groups: [group]) }
  let(:project_deploy_token) { create(:deploy_token, :project, projects: [create(:project)]) }
  let(:oauth_application) { create(:oauth_application) }
  let(:cluster_agent_token) { create(:cluster_agent_token, token_encrypted: nil) }
  let(:runner_authentication_token) { create(:ci_runner, registration_type: :authenticated_user) }
  let(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
  let(:ci_trigger) { create(:ci_trigger) }

  let(:plaintext) { nil }
  let(:params) { { token: plaintext } }

  describe 'POST /admin/token' do
    subject(:post_token) { post(api(url, api_user, admin_mode: true), params: params) }

    context 'when the user is an admin' do
      context 'with a valid token' do
        where(:token, :plaintext) do
          [
            [ref(:personal_access_token), lazy { personal_access_token.token }],
            [ref(:group_deploy_token), lazy { group_deploy_token.token }],
            [ref(:project_deploy_token), lazy { project_deploy_token.token }],
            [ref(:user), lazy { user.feed_token }],
            [ref(:oauth_application), lazy { oauth_application.plaintext_secret }],
            [ref(:cluster_agent_token), lazy { cluster_agent_token.token }],
            [ref(:runner_authentication_token), lazy { runner_authentication_token.token }],
            [ref(:impersonation_token), lazy { impersonation_token.token }],
            [ref(:ci_trigger), lazy { ci_trigger.token }]
          ]
        end

        with_them do
          it 'returns info about the token' do
            post_token

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['id']).to eq(token.id)
          end
        end
      end

      it_behaves_like 'rejecting invalid requests with admin'
    end

    it_behaves_like 'rejecting requests with invalid or missing authorization'
  end

  describe 'DELETE /admin/token' do
    subject(:delete_token) { delete(api(url, api_user, admin_mode: true), params: params) }

    context 'when the user is an admin' do
      context 'when the token is valid' do
        where(:token, :plaintext) do
          [
            [ref(:personal_access_token), lazy { personal_access_token.token }],
            [ref(:project_access_token), lazy { project_access_token.token }],
            [ref(:group_access_token), lazy { group_access_token.token }],
            [ref(:group_deploy_token), lazy { group_deploy_token.token }],
            [ref(:project_deploy_token), lazy { project_deploy_token.token }]
          ]
        end

        with_them do
          it 'revokes the token' do
            delete_token

            expect(response).to have_gitlab_http_status(:no_content)
            expect(token.reload.revoked?).to be_truthy
          end
        end
      end

      context 'when the token is a feed token' do
        let(:plaintext) { user.feed_token }

        it 'resets the token' do
          delete_token

          expect(response).to have_gitlab_http_status(:no_content)
          expect(user.reload.feed_token).not_to eq(plaintext)
        end
      end

      context 'when the revocation feature is disabled' do
        before do
          stub_feature_flags(api_admin_token_revoke: false)
        end

        it_behaves_like 'returning response status', :not_found
      end

      it_behaves_like 'rejecting invalid requests with admin'
    end

    it_behaves_like 'rejecting requests with invalid or missing authorization'
  end
end
