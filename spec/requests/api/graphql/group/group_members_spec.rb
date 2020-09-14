# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting group members information' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_1) { create(:user, username: 'user') }
  let_it_be(:user_2) { create(:user, username: 'test') }

  let(:member_data) { graphql_data['group']['groupMembers']['edges'] }

  before do
    [user_1, user_2].each { |user| group.add_guest(user) }
  end

  context 'when the request is correct' do
    it_behaves_like 'a working graphql query' do
      before do
        fetch_members(user)
      end
    end

    it 'returns group members successfully' do
      fetch_members(user)

      expect(graphql_errors).to be_nil
      expect_array_response(user_1.to_global_id.to_s, user_2.to_global_id.to_s)
    end

    it 'returns members that match the search query' do
      fetch_members(user, { search: 'test' })

      expect(graphql_errors).to be_nil
      expect_array_response(user_2.to_global_id.to_s)
    end
  end

  def fetch_members(user = nil, args = {})
    post_graphql(members_query(args), current_user: user)
  end

  def members_query(args = {})
    members_node = <<~NODE
    edges {
      node {
        user {
          id
        }
      }
    }
    NODE

    graphql_query_for("group",
      { full_path: group.full_path },
      [query_graphql_field("groupMembers", args, members_node)]
    )
  end

  def expect_array_response(*items)
    expect(response).to have_gitlab_http_status(:success)
    expect(member_data).to be_an Array
    expect(member_data.map { |node| node["node"]["user"]["id"] }).to match_array(items)
  end
end
