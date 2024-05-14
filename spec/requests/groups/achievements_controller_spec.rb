# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AchievementsController, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  shared_examples 'response with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'ok response with index template' do
    it 'renders the index template' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  shared_examples 'ok response with index template if authorized' do
    context 'with a private group' do
      let(:group) { create(:group, :private) }

      context 'with authorized user' do
        before do
          group.add_guest(user)
          sign_in(user)
        end

        it_behaves_like 'ok response with index template'

        context 'when achievements ff is disabled' do
          before do
            stub_feature_flags(achievements: false)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with unauthorized user' do
        before do
          sign_in(user)
        end

        it_behaves_like 'response with 404 status'
      end

      context 'with anonymous user' do
        it 'redirects to sign_in page' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'with a public group' do
      let(:group) { create(:group, :public) }

      context 'with anonymous user' do
        it_behaves_like 'ok response with index template'
      end
    end
  end

  describe 'GET #index' do
    subject { get group_achievements_path(group) }

    it_behaves_like 'ok response with index template if authorized'
  end

  describe 'GET #new' do
    subject { get new_group_achievement_path(group) }

    it_behaves_like 'ok response with index template if authorized'
  end
end
