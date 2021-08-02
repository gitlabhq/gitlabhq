# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PersonalAccessTokens do
  let_it_be(:path) { '/personal_access_tokens' }
  let_it_be(:token1) { create(:personal_access_token) }
  let_it_be(:token2) { create(:personal_access_token) }
  let_it_be(:token_impersonated) { create(:personal_access_token, impersonation: true, user: token1.user) }
  let_it_be(:current_user) { create(:user) }

  describe 'GET /personal_access_tokens' do
    context 'logged in as an Administrator' do
      let_it_be(:current_user) { create(:admin) }

      it 'returns all PATs by default' do
        get api(path, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(PersonalAccessToken.all.count)
      end

      context 'filtered with user_id parameter' do
        it 'returns only PATs belonging to that user' do
          get api(path, current_user), params: { user_id: token1.user.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(2)
          expect(json_response.first['user_id']).to eq(token1.user.id)
          expect(json_response.last['id']).to eq(token_impersonated.id)
        end
      end

      context 'logged in as a non-Administrator' do
        let_it_be(:current_user) { create(:user) }
        let_it_be(:user) { create(:user) }
        let_it_be(:token) { create(:personal_access_token, user: current_user)}
        let_it_be(:other_token) { create(:personal_access_token, user: user) }
        let_it_be(:token_impersonated) { create(:personal_access_token, impersonation: true, user: current_user) }

        it 'returns all PATs belonging to the signed-in user' do
          get api(path, current_user, personal_access_token: token)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(1)
          expect(json_response.map { |r| r['user_id'] }.uniq).to contain_exactly(current_user.id)
        end

        context 'filtered with user_id parameter' do
          it 'returns PATs belonging to the specific user' do
            get api(path, current_user, personal_access_token: token), params: { user_id: current_user.id }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.count).to eq(1)
            expect(json_response.map { |r| r['user_id'] }.uniq).to contain_exactly(current_user.id)
          end

          it 'is unauthorized if filtered by a user other than current_user' do
            get api(path, current_user, personal_access_token: token), params: { user_id: user.id }

            expect(response).to have_gitlab_http_status(:unauthorized)
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
  end

  describe 'DELETE /personal_access_tokens/:id' do
    let(:path) { "/personal_access_tokens/#{token1.id}" }

    context 'when current_user is an administrator', :enable_admin_mode do
      let_it_be(:admin_user) { create(:admin) }
      let_it_be(:admin_token) { create(:personal_access_token, user: admin_user) }
      let_it_be(:admin_path) { "/personal_access_tokens/#{admin_token.id}" }

      it 'revokes a different users token' do
        delete api(path, admin_user)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(token1.reload.revoked?).to be true
      end

      it 'revokes their own token' do
        delete api(admin_path, admin_user)

        expect(response).to have_gitlab_http_status(:no_content)
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
