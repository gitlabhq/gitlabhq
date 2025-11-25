# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Level Work Items', feature_category: :team_planning do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  describe 'GET /groups/:group/-/work_items' do
    let(:work_items_path) { url_for(controller: 'groups/work_items', action: :index, group_id: group.full_path) }

    before do
      sign_in(current_user)
    end

    context 'when the user can read the group' do
      let(:current_user) { developer }

      it 'renders index' do
        get work_items_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to have_pushed_frontend_feature_flags(workItemPlanningView: true)
        expect(response.body).to have_pushed_frontend_feature_flags(workItemsSavedViews: true)
      end

      context 'for work_items_client_side_boards feature flag' do
        before do
          stub_feature_flags(work_items_client_side_boards: current_user)
        end

        it 'provides the feature flag set to true' do
          get work_items_path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to have_pushed_frontend_feature_flags(workItemsClientSideBoards: true)
        end

        context 'when disabled' do
          before do
            stub_feature_flags(work_items_client_side_boards: false)
          end

          it 'provides the feature flag set to false' do
            get work_items_path

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to have_pushed_frontend_feature_flags(workItemsClientSideBoards: false)
          end
        end
      end
    end

    context 'when the user cannot read the group' do
      let(:current_user) { create(:user) }

      it 'returns not found' do
        get work_items_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /groups/:group/-/work_items/:iid' do
    let(:iid) { work_item.iid }
    let(:current_user) { developer }
    let_it_be(:work_item) { create(:work_item, :group_level, namespace: group) }
    let(:work_items_path) do
      url_for(controller: 'groups/work_items', action: :show, group_id: group.full_path, iid: iid)
    end

    before do
      sign_in(current_user)
    end

    it 'returns not found' do
      get work_items_path

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'when the new page gets requested' do
      let(:iid) { 'new' }

      context "with signed in user" do
        it 'renders show' do
          get work_items_path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      context "with signed out user" do
        let(:current_user) { create(:user) }

        it 'returns not found' do
          get work_items_path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
