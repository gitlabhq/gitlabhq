# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SavedViewsController, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:saved_view) { create(:saved_view) }

  before do
    sign_in(user)
  end

  describe '#subscribe' do
    it 'returns a 404' do
      get subscribe_group_saved_view_path(group_id: group.full_path, id: saved_view.id)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
