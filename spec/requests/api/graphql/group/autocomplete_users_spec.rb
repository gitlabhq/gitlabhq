# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'autocomplete users for a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent_group) }

  let_it_be(:parent_group_member) { create(:user, guest_of: parent_group) }
  let_it_be(:group_member) { create(:user, guest_of: group) }

  let_it_be(:other_group) { create(:group) }
  let_it_be(:other_group_member) { create(:user, guest_of: other_group) }

  let(:params) { {} }
  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      query_graphql_field('autocompleteUsers', params, 'id')
    )
  end

  let(:response_user_ids) { graphql_data.dig('group', 'autocompleteUsers').pluck('id') }

  it 'returns members of the group and its ancestors' do
    post_graphql(query, current_user: group_member)

    expected_user_ids = [
      parent_group_member,
      group_member
    ].map { |u| u.to_global_id.to_s }

    expect(response_user_ids).to match_array(expected_user_ids)
  end

  context 'with search param' do
    let(:params) { { search: group_member.username } }

    it 'only returns users matching the search query' do
      post_graphql(query, current_user: group_member)

      expect(response_user_ids).to contain_exactly(group_member.to_global_id.to_s)
    end
  end

  describe 'granular PAT authorization' do
    # A public group lets the token pass the parent GroupType authorization via
    # the public-access bypass, so the test gates on AutocompletedUser's
    # `read_user` permission at the user boundary.
    let_it_be(:public_group) { create(:group, :public, guests: group_member) }

    let(:query) do
      graphql_query_for(
        'group',
        { 'fullPath' => public_group.full_path },
        query_graphql_field('autocompleteUsers', {}, 'id')
      )
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :read_user do
      let(:user) { group_member }
      let(:boundary_object) { :user }
      let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
    end
  end
end
