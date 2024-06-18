# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupBoards, :with_license, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:board_parent) { create(:group, :public, owners: user) }

  let_it_be(:project) { create(:project, :public, namespace: board_parent) }

  let_it_be(:dev_label) do
    create(:group_label, title: 'Development', color: '#FFAABB', group: board_parent)
  end

  let_it_be(:test_label) do
    create(:group_label, title: 'Testing', color: '#FFAACC', group: board_parent)
  end

  let_it_be(:ux_label) do
    create(:group_label, title: 'UX', color: '#FF0000', group: board_parent)
  end

  let_it_be(:dev_list) do
    create(:list, label: dev_label, position: 1)
  end

  let_it_be(:test_list) do
    create(:list, label: test_label, position: 2)
  end

  let_it_be(:milestone) { create(:milestone, group: board_parent) }
  let_it_be(:board_label) { create(:group_label, group: board_parent) }

  let_it_be(:board) { create(:board, group: board_parent, lists: [dev_list, test_list]) }

  it_behaves_like 'group and project boards', "/groups/:id/boards", false

  describe 'POST /groups/:id/boards/lists' do
    let(:url) { "/groups/#{board_parent.id}/boards/#{board.id}/lists" }

    it 'does not create lists for child project labels' do
      project_label = create(:label, project: project)

      post api(url, user), params: { label_id: project_label.id }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end
