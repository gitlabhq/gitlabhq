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
    let(:iid) { work_item.iid }
    let(:work_items_path) do
      url_for(controller: 'groups/work_items', action: :show, group_id: group.full_path, iid: iid)
    end

    before do
      sign_in(current_user)
    end

    context 'when the user can read the group' do
      let(:current_user) { developer }

      it 'renders show' do
        get work_items_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end

      context 'when the new page gets requested' do
        let(:iid) { 'new' }

        it 'renders show' do
          get work_items_path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
          expect(response.body).to have_pushed_frontend_feature_flags(namespaceLevelWorkItems: true)
        end
      end

      it 'has correct metadata' do
        get work_items_path

        expect(response.body).to include("#{work_item.title} (#{work_item.to_reference})")
        expect(response.body).to include(work_item.work_item_type.name.pluralize)
      end

      context 'when the namespace_level_work_items feature flag is disabled' do
        before do
          stub_feature_flags(namespace_level_work_items: false)
        end

        it 'returns not found' do
          get work_items_path

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'on new page' do
          let(:iid) { 'new' }

          it 'returns not found' do
            get work_items_path

            expect(response).to have_gitlab_http_status(:not_found)
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

      it 'does not include sensitive metadata' do
        get work_items_path

        expect(response.body).not_to include("#{work_item.title} (#{work_item.to_reference})")
        expect(response.body).not_to include(work_item.work_item_type.name.pluralize)
      end
    end
  end
end
