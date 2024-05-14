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
      end

      context 'when the namespace_level_work_items feature flag is disabled' do
        before do
          stub_feature_flags(namespace_level_work_items: false)
        end

        it 'returns not found' do
          get work_items_path

          expect(response).to have_gitlab_http_status(:not_found)
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
    let_it_be(:work_item) { create(:work_item, :group_level, namespace: group) }
    let(:work_items_path) do
      url_for(controller: 'groups/work_items', action: :show, group_id: group.full_path, iid: work_item.iid)
    end

    before do
      sign_in(current_user)
    end

    context 'when the user can read the group' do
      let(:current_user) { developer }

      it 'renders index' do
        get work_items_path

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when the namespace_level_work_items feature flag is disabled' do
        before do
          stub_feature_flags(namespace_level_work_items: false)
        end

        it 'returns not found' do
          get work_items_path

          expect(response).to have_gitlab_http_status(:not_found)
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
end
