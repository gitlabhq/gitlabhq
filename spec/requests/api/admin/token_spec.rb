# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Token, :aggregate_failures, feature_category: :system_access do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:url) { '/admin/token' }
  let(:api_user) { admin }

  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token) }
  let_it_be(:oauth_application) { create(:oauth_application) }
  let_it_be(:cluster_agent_token) { create(:cluster_agent_token, token_encrypted: nil) }
  let_it_be(:runner_authentication_token) { create(:ci_runner, registration_type: :authenticated_user) }
  let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

  let(:plaintext) { nil }
  let(:params) { { token: plaintext } }

  subject(:post_token) { post(api(url, api_user, admin_mode: true), params: params) }

  describe 'POST /admin/token' do
    context 'when the user is an admin' do
      context 'with a valid token' do
        where(:token, :plaintext) do
          [
            [ref(:personal_access_token), lazy { personal_access_token.token }],
            [ref(:deploy_token), lazy { deploy_token.token }],
            [ref(:user), lazy { user.feed_token }],
            [ref(:oauth_application), lazy { oauth_application.plaintext_secret }],
            [ref(:cluster_agent_token), lazy { cluster_agent_token.token }],
            [ref(:runner_authentication_token), lazy { runner_authentication_token.token }],
            [ref(:impersonation_token), lazy { impersonation_token.token }]
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

      context 'with non-existing token' do
        let(:plaintext) { "#{personal_access_token.token}-non-existing" }

        it_behaves_like 'returning response status', :not_found
      end

      context 'with unsupported token type' do
        let(:plaintext) { 'unsupported' }

        it_behaves_like 'returning response status', :unprocessable_entity
      end

      context 'when the feature is disabled' do
        before do
          stub_feature_flags(admin_agnostic_token_finder: false)
        end

        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'when the user is not an admin' do
      let(:api_user) { user }

      it_behaves_like 'returning response status', :forbidden
    end

    context 'without a user' do
      let(:api_user) { nil }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
