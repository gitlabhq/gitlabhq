require 'spec_helper'

describe API::GroupBoards do
  set(:user) { create(:user) }
  set(:non_member) { create(:user) }
  set(:guest) { create(:user) }
  set(:admin) { create(:user, :admin) }
  set(:board_parent) { create(:group, :public) }

  before do
    board_parent.add_owner(user)
  end

  set(:project) { create(:project, :public, namespace: board_parent ) }

  set(:dev_label) do
    create(:group_label, title: 'Development', color: '#FFAABB', group: board_parent)
  end

  set(:test_label) do
    create(:group_label, title: 'Testing', color: '#FFAACC', group: board_parent)
  end

  set(:ux_label) do
    create(:group_label, title: 'UX', color: '#FF0000', group: board_parent)
  end

  set(:dev_list) do
    create(:list, label: dev_label, position: 1)
  end

  set(:test_list) do
    create(:list, label: test_label, position: 2)
  end

  set(:milestone) { create(:milestone, group: board_parent) }
  set(:board_label) { create(:group_label, group: board_parent) }

  set(:board) { create(:board, group: board_parent, lists: [dev_list, test_list]) }

  it_behaves_like 'group and project boards', "/groups/:id/boards", false

  describe 'POST /groups/:id/boards/lists' do
    let(:url) { "/groups/#{board_parent.id}/boards/#{board.id}/lists" }

    it 'does not create lists for child project labels' do
      project_label = create(:label, project: project)

      post api(url, user), label_id: project_label.id

      expect(response).to have_gitlab_http_status(400)
    end
  end
end
