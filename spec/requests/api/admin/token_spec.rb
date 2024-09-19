# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Token, :aggregate_failures, feature_category: :system_access do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:url) { '/admin/token' }
  let(:api_user) { admin }

  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token) }
  let(:token) { nil }
  let(:params) { { token: token } }

  subject(:post_token) { post(api(url, api_user, admin_mode: true), params: params) }

  describe 'POST /admin/token' do
    context 'when the user is an admin' do
      context 'with personal access token' do
        let(:token) { personal_access_token.token }

        it 'returns info about the token' do
          post_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(personal_access_token.id)
        end
      end

      context 'with deploy token' do
        let(:token) { deploy_token.token }

        it 'returns info about the token' do
          post_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(deploy_token.id)
        end
      end

      context 'with non-existing token' do
        let(:token) { "#{personal_access_token.token}-non-existing" }

        it_behaves_like 'returning response status', :not_found
      end

      context 'with unsupported token type' do
        let(:token) { 'unsupported' }

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
