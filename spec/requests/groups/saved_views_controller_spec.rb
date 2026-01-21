# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups::SavedViews', feature_category: :portfolio_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, developer_of: group) }
  let_it_be(:saved_view) { create(:saved_view) }

  before do
    sign_in(user)
  end

  describe 'GET /groups/:group/-/saved_views/:id/subscribe' do
    it 'renders the work items index page' do
      get group_saved_view_path(group_id: group.full_path, id: saved_view.id)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('id="js-work-items"')
    end
  end
end
