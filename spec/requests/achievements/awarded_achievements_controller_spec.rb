# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::AwardedAchievementsController, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }

  describe 'GET #accept' do
    context 'with a valid token' do
      let_it_be(:user_achievement) do
        create(:user_achievement, achievement: achievement, user: user, show_on_profile: false)
      end

      let(:token) { user_achievement.signed_id(purpose: :achievement_action, expires_in: 30.days) }

      it 'renders the confirmation page' do
        get accept_awarded_achievement_path(id: token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('Accept achievement')
      end

      context 'when the recipient user is authenticated' do
        before do
          sign_in(user)
        end

        it 'renders the confirmation page without mutating state' do
          get accept_awarded_achievement_path(id: token)

          expect(user_achievement.reload.show_on_profile).to be(false)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with an invalid token' do
      it 'renders the invalid link page' do
        get accept_awarded_achievement_path(id: 'invalid-token')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #accept' do
    context 'with a valid token' do
      let_it_be(:user_achievement) do
        create(:user_achievement, achievement: achievement, user: user, show_on_profile: false)
      end

      let(:token) { user_achievement.signed_id(purpose: :achievement_action, expires_in: 30.days) }

      context 'when the recipient user is authenticated' do
        before do
          sign_in(user)
        end

        it 'accepts the achievement and redirects to profile' do
          post accept_awarded_achievement_path(id: token)

          expect(user_achievement.reload.show_on_profile).to be(true)
          expect(response).to redirect_to(user_path(user))
          expect(flash[:success]).to include('accepted')
        end
      end

      context 'when a different user is authenticated' do
        let_it_be(:other_user) { create(:user) }

        before do
          sign_in(other_user)
        end

        it 'renders the invalid link page' do
          post accept_awarded_achievement_path(id: token)

          expect(user_achievement.reload.show_on_profile).to be(false)
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when force param is provided' do
        it 'accepts the achievement without authentication' do
          post accept_awarded_achievement_path(id: token, force: true)

          expect(user_achievement.reload.show_on_profile).to be(true)
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:success]).to include('accepted')
        end
      end
    end

    context 'with an invalid token' do
      it 'renders the invalid link page' do
        post accept_awarded_achievement_path(id: 'invalid-token')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
