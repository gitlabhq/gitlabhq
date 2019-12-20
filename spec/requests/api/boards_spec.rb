# frozen_string_literal: true

require 'spec_helper'

describe API::Boards do
  set(:user)        { create(:user) }
  set(:non_member)  { create(:user) }
  set(:guest)       { create(:user) }
  set(:admin)       { create(:user, :admin) }
  set(:board_parent) { create(:project, :public, creator_id: user.id, namespace: user.namespace ) }

  set(:dev_label) do
    create(:label, title: 'Development', color: '#FFAABB', project: board_parent)
  end

  set(:test_label) do
    create(:label, title: 'Testing', color: '#FFAACC', project: board_parent)
  end

  set(:ux_label) do
    create(:label, title: 'UX', color: '#FF0000', project: board_parent)
  end

  set(:dev_list) do
    create(:list, label: dev_label, position: 1)
  end

  set(:test_list) do
    create(:list, label: test_label, position: 2)
  end

  set(:milestone) { create(:milestone, project: board_parent) }
  set(:board_label) { create(:label, project: board_parent) }
  set(:board) { create(:board, project: board_parent, lists: [dev_list, test_list]) }

  it_behaves_like 'group and project boards', "/projects/:id/boards"

  describe "POST /projects/:id/boards/lists" do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}/lists" }

    it 'creates a new issue board list for group labels' do
      group = create(:group)
      group_label = create(:group_label, group: group)
      board_parent.update(group: group)

      post api(url, user), params: { label_id: group_label.id }

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['label']['name']).to eq(group_label.title)
      expect(json_response['position']).to eq(3)
    end

    it 'creates a new board list for ancestor group labels' do
      group = create(:group)
      sub_group = create(:group, parent: group)
      group_label = create(:group_label, group: group)
      board_parent.update(group: sub_group)
      group.add_developer(user)
      sub_group.add_developer(user)

      post api(url, user), params: { label_id: group_label.id }

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['label']['name']).to eq(group_label.title)
    end
  end

  describe "POST /groups/:id/boards/lists" do
    set(:group) { create(:group) }
    set(:board_parent) { create(:group, parent: group ) }
    let(:url) { "/groups/#{board_parent.id}/boards/#{board.id}/lists" }

    set(:board) { create(:board, group: board_parent) }

    it 'creates a new board list for ancestor group labels' do
      group.add_developer(user)
      group_label = create(:group_label, group: group)

      post api(url, user), params: { label_id: group_label.id }

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['label']['name']).to eq(group_label.title)
    end
  end
end
