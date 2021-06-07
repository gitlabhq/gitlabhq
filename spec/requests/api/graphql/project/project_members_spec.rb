# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project members information' do
  include GraphqlHelpers

  let_it_be(:parent_group) { create(:group, :public) }
  let_it_be(:parent_project) { create(:project, :public, group: parent_group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_1) { create(:user, username: 'user') }
  let_it_be(:user_2) { create(:user, username: 'test') }

  before_all do
    [user_1, user_2].each { |user| parent_group.add_guest(user) }
  end

  context 'when the request is correct' do
    it_behaves_like 'a working graphql query' do
      before do
        fetch_members(project: parent_project)
      end
    end

    it 'returns project members successfully' do
      fetch_members(project: parent_project)

      expect(graphql_errors).to be_nil
      expect_array_response(user_1, user_2)
    end

    it 'returns members that match the search query' do
      fetch_members(project: parent_project, args: { search: 'test' })

      expect(graphql_errors).to be_nil
      expect_array_response(user_2)
    end
  end

  context 'member relations' do
    let_it_be(:child_group) { create(:group, :public, parent: parent_group) }
    let_it_be(:child_project) { create(:project, :public, group: child_group) }
    let_it_be(:invited_group) { create(:group, :public) }
    let_it_be(:child_user) { create(:user) }
    let_it_be(:invited_user) { create(:user) }
    let_it_be(:group_link) { create(:project_group_link, project: child_project, group: invited_group) }

    before_all do
      child_project.add_guest(child_user)
      invited_group.add_guest(invited_user)
    end

    context 'when a member is invited only via email and current_user is a maintainer' do
      before do
        parent_project.add_maintainer(user)
        create(:project_member, :invited, source: parent_project)
      end

      it 'returns null in the user field' do
        fetch_members(project: parent_project, args: { relations: [:DIRECT] })

        expect(graphql_errors).to be_nil
        expect(graphql_data_at(:project, :project_members, :edges, :node)).to contain_exactly({ 'user' => { 'id' => global_id_of(user) } }, 'user' => nil)
      end
    end

    it 'returns direct members' do
      fetch_members(project: child_project, args: { relations: [:DIRECT] })

      expect(graphql_errors).to be_nil
      expect_array_response(child_user)
    end

    it 'returns invited members plus inherited members' do
      fetch_members(project: child_project, args: { relations: [:INVITED_GROUPS] })

      expect(graphql_errors).to be_nil
      expect_array_response(invited_user, user_1, user_2)
    end

    it 'returns direct, inherited, descendant, and invited members' do
      fetch_members(project: child_project, args: { relations: [:DIRECT, :INHERITED, :DESCENDANTS, :INVITED_GROUPS] })

      expect(graphql_errors).to be_nil
      expect_array_response(child_user, user_1, user_2, invited_user)
    end

    it 'returns an error for an invalid member relation' do
      fetch_members(project: child_project, args: { relations: [:OBLIQUE] })

      expect(graphql_errors.first)
        .to include('path' => %w[query project projectMembers relations],
                    'message' => a_string_including('invalid value ([OBLIQUE])'))
    end

    context 'when project is owned by a member' do
      let_it_be(:project) { create(:project, namespace: user.namespace) }

      before_all do
        project.add_guest(child_user)
        project.add_guest(invited_user)
      end

      it 'returns the owner in the response' do
        fetch_members(project: project)

        expect(graphql_errors).to be_nil
        expect_array_response(user, child_user, invited_user)
      end
    end
  end

  context 'when unauthenticated' do
    it 'returns members' do
      fetch_members(current_user: nil, project: parent_project)

      expect(graphql_errors).to be_nil
      expect_array_response(user_1, user_2)
    end
  end

  def fetch_members(project:, current_user: user, args: {})
    post_graphql(members_query(project.full_path, args), current_user: current_user)
  end

  def members_query(group_path, args = {})
    members_node = <<~NODE
    edges {
      node {
        user {
          id
        }
      }
    }
    NODE

    graphql_query_for('project',
      { full_path: group_path },
      [query_graphql_field('projectMembers', args, members_node)]
    )
  end

  def expect_array_response(*items)
    expect(response).to have_gitlab_http_status(:success)
    member_gids = graphql_data_at(:project, :project_members, :edges, :node, :user, :id)
    expect(member_gids).to match_array(items.map { |u| global_id_of(u) })
  end
end
