# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AchievementsController, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  shared_examples 'response with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'response for each role' do |permission|
    where(:role, :allowed) do
      :guest      | false
      :planner    | false
      :reporter   | false
      :developer  | false
      :maintainer | true
      :owner      | true
    end

    with_them do
      before do
        group.add_member(user, role)
        sign_in(user)
      end

      it "returns ok only for roles with #{permission}" do
        subject

        expect(response).to have_gitlab_http_status(allowed ? :ok : :not_found)
      end
    end
  end

  shared_examples 'ok response with index template' do
    it 'renders the index template' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #index' do
    let(:group) { create(:group, :private) }

    subject { get group_achievements_path(group) }

    context 'with a guest member (can read_achievement)' do
      before do
        group.add_guest(user)
        sign_in(user)
      end

      it_behaves_like 'ok response with index template'
    end

    context 'with permissions passed to the app' do
      where(:role, :allowed) do
        :developer  | false
        :maintainer | true
      end

      with_them do
        before do
          group.add_member(user, role)
          sign_in(user)
        end

        it 'passes the create, update and delete permissions' do
          get group_achievements_path(group)

          view_model = Gitlab::Json::SafeParser.parse(
            Nokogiri::HTML(response.body).at_css('#js-achievements-app')['data-view-model']
          )

          expect(view_model).to include(
            'can_create_achievement' => allowed,
            'can_update_achievement' => allowed,
            'can_delete_achievement' => allowed
          )
        end
      end
    end

    context 'with anonymous user' do
      it 'redirects to sign_in page' do
        get group_achievements_path(group)

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #new' do
    let(:group) { create(:group, :private) }

    subject { get new_group_achievement_path(group) }

    context 'with a private group' do
      it_behaves_like 'response for each role', :create_achievement

      context 'with a maintainer' do
        before do
          group.add_maintainer(user)
          sign_in(user)
        end

        it_behaves_like 'ok response with index template'
      end

      context 'with anonymous user' do
        it 'redirects to sign_in page' do
          get new_group_achievement_path(group)

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'with a public group' do
      let(:group) { create(:group, :public) }

      context 'with a maintainer' do
        before do
          group.add_maintainer(user)
          sign_in(user)
        end

        it_behaves_like 'ok response with index template'
      end

      context 'with anonymous user' do
        it_behaves_like 'response with 404 status'
      end
    end
  end

  describe 'GET #edit' do
    let(:group) { create(:group, :private) }
    let(:achievement) { create(:achievement, namespace: group) }

    subject { get edit_group_achievement_path(group, achievement) }

    context 'with a private group' do
      it_behaves_like 'response for each role', :update_achievement

      context 'with a maintainer' do
        before do
          group.add_maintainer(user)
          sign_in(user)
        end

        it_behaves_like 'ok response with index template'
      end

      context 'with anonymous user' do
        it 'redirects to sign_in page' do
          get new_group_achievement_path(group)

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'with a public group' do
      let(:group) { create(:group, :public) }

      context 'with a maintainer' do
        before do
          group.add_maintainer(user)
          sign_in(user)
        end

        it_behaves_like 'ok response with index template'
      end

      context 'with anonymous user' do
        it_behaves_like 'response with 404 status'
      end
    end
  end
end
