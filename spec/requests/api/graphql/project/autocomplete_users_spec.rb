# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'autocomplete users for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:direct_member) { create(:user, guest_of: project) }
  let_it_be(:indirect_member) { create(:user, guest_of: group) }

  let_it_be(:group_invited_to_project) do
    create(:group).tap { |g| create(:project_group_link, project: project, group: g) }
  end

  let_it_be(:member_from_project_share) { create(:user, guest_of: group_invited_to_project) }

  let_it_be(:group_invited_to_parent_group) do
    create(:group).tap { |g| create(:group_group_link, shared_group: group, shared_with_group: g) }
  end

  let_it_be(:member_from_parent_group_share) { create(:user, guest_of: group_invited_to_parent_group) }

  let_it_be(:sibling_project) { create(:project, :public, group: group) }
  let_it_be(:sibling_member) { create(:user, guest_of: sibling_project) }

  let(:params) { {} }
  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('autocompleteUsers', params, 'id')
    )
  end

  let(:response_user_ids) { graphql_data.dig('project', 'autocompleteUsers').pluck('id') }

  it 'returns members of the project' do
    post_graphql(query, current_user: direct_member)

    expected_user_ids = [
      direct_member,
      indirect_member,
      member_from_project_share,
      member_from_parent_group_share
    ].map { |u| u.to_global_id.to_s }

    expect(response_user_ids).to match_array(expected_user_ids)
  end

  context 'with search param' do
    let(:params) { { search: indirect_member.username } }

    it 'only returns users matching the search query' do
      post_graphql(query, current_user: direct_member)

      expect(response_user_ids).to contain_exactly(indirect_member.to_global_id.to_s)
    end
  end

  context 'with merge request interaction' do
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:fields) do
      <<~FIELDS
      id
      mergeRequestInteraction(id: "#{merge_request.to_global_id}") {
        canMerge
      }
      FIELDS
    end

    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_graphql_field('autocompleteUsers', params, fields)
      )
    end

    it 'returns MR state related to the users' do
      project.add_maintainer(direct_member)

      post_graphql(query, current_user: direct_member)

      expect(graphql_data.dig('project', 'autocompleteUsers')).to include(
        a_hash_including(
          'id' => direct_member.to_global_id.to_s,
          'mergeRequestInteraction' => { 'canMerge' => true }
        ),
        a_hash_including(
          'id' => indirect_member.to_global_id.to_s,
          'mergeRequestInteraction' => { 'canMerge' => false }
        )
      )
    end

    # The field takes any merge request ID, so the granular boundary must come from
    # that merge request rather than from the project the query is rooted at.
    it 'does not return the interaction for a merge request outside the token boundary' do
      other_project = create(:project, :private, :repository)
      other_merge_request = create(:merge_request, source_project: other_project)
      other_project.add_maintainer(direct_member)
      assignable = ->(permission) { ::Authz::PermissionGroups::Assignable.for_permission(permission).first.name }
      pat = create(:granular_pat, user: direct_member, boundary: ::Authz::Boundary.for(project),
        permissions: [assignable.call(:read_project), assignable.call(:read_merge_request)],
        additional_scopes: [{ boundary: ::Authz::Boundary.for(:user),
                              permissions: [assignable.call(:read_user)] }])
      query = graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_graphql_field('autocompleteUsers', params, <<~FIELDS)
          id
          mergeRequestInteraction(id: "#{other_merge_request.to_global_id}") {
            canMerge
          }
        FIELDS
      )

      post_graphql(query, token: { personal_access_token: pat })

      users = graphql_data.dig('project', 'autocompleteUsers')

      expect(users).to be_present
      expect(users).to all(a_hash_including('mergeRequestInteraction' => nil))
    end
  end
end
