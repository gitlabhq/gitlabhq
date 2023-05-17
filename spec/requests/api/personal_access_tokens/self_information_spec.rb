# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PersonalAccessTokens::SelfInformation, feature_category: :system_access do
  let(:path) { '/personal_access_tokens/self' }
  let(:token) { create(:personal_access_token, user: current_user) }

  let_it_be(:current_user) { create(:user) }

  describe 'DELETE /personal_access_tokens/self' do
    subject(:delete_token) { delete api(path, personal_access_token: token) }

    shared_examples 'revoking token succeeds' do
      it 'revokes token', :aggregate_failures do
        delete_token

        expect(response).to have_gitlab_http_status(:no_content)
        expect(token.reload).to be_revoked
      end
    end

    shared_examples 'revoking token denied' do |status|
      it 'cannot revoke token' do
        delete_token

        expect(response).to have_gitlab_http_status(status)
      end
    end

    context 'when current_user is an administrator', :enable_admin_mode do
      let(:current_user) { create(:admin) }

      it_behaves_like 'revoking token succeeds'

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'revoking token succeeds'
      end
    end

    context 'when current_user is not an administrator' do
      let(:current_user) { create(:user) }

      it_behaves_like 'revoking token succeeds'

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'revoking token denied', :bad_request
      end

      context 'with already revoked token' do
        let(:token) { create(:personal_access_token, :revoked, user: current_user) }

        it_behaves_like 'revoking token denied', :unauthorized
      end
    end

    Gitlab::Auth.all_available_scopes.each do |scope|
      context "with a '#{scope}' scoped token" do
        let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

        it_behaves_like 'revoking token succeeds'
      end
    end
  end

  describe 'GET /personal_access_tokens/self' do
    Gitlab::Auth.all_available_scopes.each do |scope|
      context "with a '#{scope}' scoped token" do
        let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

        it 'shows token info', :aggregate_failures do
          get api(path, personal_access_token: token)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['scopes']).to match_array([scope.to_s])
        end
      end
    end

    context 'when token is invalid' do
      it 'returns 401' do
        get api(path, personal_access_token: instance_double(PersonalAccessToken, token: 'invalidtoken'))

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when token is expired' do
      it 'returns 401' do
        token = create(:personal_access_token, expires_at: 1.day.ago, user: current_user)

        get api(path, personal_access_token: token)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
