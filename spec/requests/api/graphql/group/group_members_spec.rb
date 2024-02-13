# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting group members information', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:parent_group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_1) { create(:user, username: 'user', name: 'Same Name') }
  let_it_be(:user_2) { create(:user, username: 'test', name: 'Same Name') }

  before_all do
    [user_1, user_2].each { |user| parent_group.add_guest(user) }
  end

  context 'when a member is invited only via email' do
    before do
      create(:group_member, :invited, source: parent_group)
    end

    it 'returns null in the user field' do
      fetch_members(group: parent_group, args: { relations: [:DIRECT] })

      expect(graphql_errors).to be_nil
      expect(graphql_data_at(:group, :group_members, :edges, :node)).to contain_exactly(
        { 'user' => a_graphql_entity_for(user_1) },
        { 'user' => a_graphql_entity_for(user_2) },
        'user' => nil
      )
    end
  end

  context 'when the request is correct' do
    it_behaves_like 'a working graphql query' do
      before do
        fetch_members
      end
    end

    it 'returns group members successfully' do
      fetch_members

      expect(graphql_errors).to be_nil
      expect_array_response(user_1, user_2)
    end

    describe 'search argument' do
      it 'returns members that match the search query' do
        fetch_members(args: { search: 'test' })

        expect(graphql_errors).to be_nil
        expect_array_response(user_2)
      end

      context 'when paginating' do
        it 'returns correct results' do
          fetch_members(args: { search: 'Same Name', first: 1 })

          expect_array_response(user_1)

          next_cursor = graphql_data_at(:group, :groupMembers, :pageInfo, :endCursor)
          fetch_members(args: { search: 'Same Name', first: 1, after: next_cursor })

          expect_array_response(user_2)
        end
      end
    end
  end

  context "when requesting member's notification email" do
    context 'when current_user is admin' do
      let_it_be(:admin_user) { create(:user, :admin) }

      it 'returns notification email' do
        fetch_members_notification_email(current_user: admin_user)
        notification_emails = graphql_data_at(:group, :group_members, :edges, :node, :notification_email)

        expect(notification_emails).to all be_present
        expect(graphql_errors).to be_nil
      end
    end

    context 'when current_user is not admin' do
      it 'returns an error' do
        fetch_members_notification_email

        expect(graphql_errors.first).to include(
          'path' => ['group', 'groupMembers', 'edges', 0, 'node', 'notificationEmail'],
          'message' => a_string_including("you don't have permission to perform this action")
        )
      end
    end
  end

  context 'by access levels' do
    before do
      parent_group.add_owner(user_1)
      parent_group.add_maintainer(user_2)
    end

    subject(:by_access_levels) { fetch_members(group: parent_group, args: { access_levels: access_levels }) }

    context 'by owner' do
      let(:access_levels) { :OWNER }

      it 'returns owner' do
        by_access_levels

        expect(graphql_errors).to be_nil
        expect_array_response(user_1)
      end
    end

    context 'by maintainer' do
      let(:access_levels) { :MAINTAINER }

      it 'returns maintainer' do
        by_access_levels

        expect(graphql_errors).to be_nil
        expect_array_response(user_2)
      end
    end

    context 'by owner and maintainer' do
      let(:access_levels) { [:OWNER, :MAINTAINER] }

      it 'returns owner and maintainer' do
        by_access_levels

        expect(graphql_errors).to be_nil
        expect_array_response(user_1, user_2)
      end
    end
  end

  context 'member relations' do
    let_it_be(:child_group) { create(:group, :public, parent: parent_group) }
    let_it_be(:grandchild_group) { create(:group, :public, parent: child_group) }
    let_it_be(:invited_group) { create(:group, :public) }
    let_it_be(:child_user) { create(:user) }
    let_it_be(:grandchild_user) { create(:user) }
    let_it_be(:invited_user) { create(:user) }
    let_it_be(:group_link) { create(:group_group_link, shared_group: child_group, shared_with_group: invited_group) }

    before_all do
      child_group.add_guest(child_user)
      grandchild_group.add_guest(grandchild_user)
      invited_group.add_guest(invited_user)
    end

    it 'returns direct members' do
      fetch_members(group: child_group, args: { relations: [:DIRECT] })

      expect(graphql_errors).to be_nil
      expect_array_response(child_user)
    end

    it 'returns invited members and inherited members of a shared group' do
      fetch_members(group: child_group, args: { relations: [:DIRECT, :INHERITED, :SHARED_FROM_GROUPS] })

      expect(graphql_errors).to be_nil
      expect_array_response(invited_user, user_1, user_2, child_user)
    end

    it 'returns invited members and inherited members of an ancestor of a shared group' do
      fetch_members(group: grandchild_group, args: { relations: [:DIRECT, :INHERITED, :SHARED_FROM_GROUPS] })

      expect(graphql_errors).to be_nil
      expect_array_response(grandchild_user, invited_user, user_1, user_2, child_user)
    end

    it 'returns direct and inherited members' do
      fetch_members(group: child_group, args: { relations: [:DIRECT, :INHERITED] })

      expect(graphql_errors).to be_nil
      expect_array_response(child_user, user_1, user_2)
    end

    it 'returns direct, inherited, and descendant members' do
      fetch_members(group: child_group, args: { relations: [:DIRECT, :INHERITED, :DESCENDANTS] })

      expect(graphql_errors).to be_nil
      expect_array_response(child_user, user_1, user_2, grandchild_user)
    end

    it 'returns an error for an invalid member relation' do
      fetch_members(group: child_group, args: { relations: [:OBLIQUE] })

      expect(graphql_errors.first).to include(
        'path' => %w[query group groupMembers relations],
        'message' => a_string_including('invalid value ([OBLIQUE])')
      )
    end
  end

  context 'when unauthenticated' do
    it 'returns visible members' do
      fetch_members(current_user: nil)

      expect_array_response(user_1, user_2)
    end
  end

  def fetch_members(group: parent_group, current_user: user, args: {})
    post_graphql(members_query(group.full_path, args), current_user: current_user)
  end

  def fetch_members_notification_email(group: parent_group, current_user: user)
    post_graphql(member_notification_email_query(group.full_path), current_user: current_user)
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
    pageInfo {
      endCursor
    }
    NODE

    graphql_query_for("group",
      { full_path: group_path },
      [query_graphql_field("groupMembers", args, members_node)]
    )
  end

  def member_notification_email_query(group_path)
    members_node = <<~NODE
    edges {
      node {
        user {
          id
        }
        notificationEmail
      }
    }
    NODE

    graphql_query_for("group",
      { full_path: group_path },
      [query_graphql_field("groupMembers", {}, members_node)]
    )
  end

  def expect_array_response(*items)
    expect(response).to have_gitlab_http_status(:success)
    members = graphql_data_at(:group, :group_members, :edges, :node, :user)

    expect(members).to match_array(items.map { |u| a_graphql_entity_for(u) })
  end
end
