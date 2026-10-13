# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups::SavedViews', feature_category: :planning_views do
  let_it_be(:group) { create(:group) }
  let_it_be(:user, freeze: false) { create(:user, developer_of: group) }

  before do
    sign_in(user)
  end

  describe 'GET /groups/:group/-/views/:id' do
    context 'when feature is enabled' do
      context 'when saved view exists' do
        let(:saved_view) { create(:saved_view, namespace: group) }

        subject(:show_saved_view) { get group_saved_view_path(group_id: group.full_path, id: saved_view.id) }

        it 'renders the work items index' do
          show_saved_view

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('id="js-work-items"')
        end
      end

      context 'when saved view does not exist' do
        subject(:show_saved_view) { get group_saved_view_path(group_id: group.full_path, id: 'non-existent-id') }

        it 'renders the work items index' do
          show_saved_view

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('id="js-work-items"')
        end
      end
    end

    context 'for planning_view_boards feature flags' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let(:saved_view) { create(:saved_view, namespace: subgroup) }

      subject(:show_saved_view) { get group_saved_view_path(group_id: subgroup.full_path, id: saved_view.id) }

      before do
        stub_feature_flags(planning_view_boards: false, planning_view_boards_group: false)
      end

      it 'pushes the flag as false when both flags are disabled' do
        show_saved_view

        expect(response.body).to have_pushed_frontend_feature_flags(
          planningViewBoards: false, planningViewBoardsGroup: false
        )
      end

      it 'pushes the flag as true when enabled for the user' do
        stub_feature_flags(planning_view_boards: user)

        show_saved_view

        expect(response.body).to have_pushed_frontend_feature_flags(
          planningViewBoards: true, planningViewBoardsGroup: false
        )
      end

      it 'pushes the flag as true when enabled for the root group' do
        stub_feature_flags(planning_view_boards_group: group)

        show_saved_view

        expect(response.body).to have_pushed_frontend_feature_flags(
          planningViewBoards: true, planningViewBoardsGroup: true
        )
      end

      it 'pushes the flag as false when enabled for a different root group' do
        stub_feature_flags(planning_view_boards_group: create(:group))

        show_saved_view

        expect(response.body).to have_pushed_frontend_feature_flags(
          planningViewBoards: false, planningViewBoardsGroup: false
        )
      end
    end

    context 'when user is not authenticated' do
      let(:saved_view) { create(:saved_view, namespace: group) }

      subject(:show_saved_view) { get group_saved_view_path(group_id: group.full_path, id: saved_view.id) }

      before do
        sign_out(user)
      end

      it 'redirects to sign in' do
        show_saved_view

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
