# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project members information', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:parent_group) { create(:group, :public) }
  let_it_be(:parent_project) { create(:project, :public, group: parent_group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_1) { create(:user, username: 'user', name: 'Same Name') }
  let_it_be(:user_2) { create(:user, username: 'test', name: 'Same Name') }

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

    describe 'search argument' do
      it 'returns members that match the search query' do
        fetch_members(project: parent_project, args: { search: 'test' })

        expect(graphql_errors).to be_nil
        expect_array_response(user_2)
      end

      context 'when paginating' do
        it 'returns correct results' do
          fetch_members(project: parent_project, args: { search: 'Same Name', first: 1 })

          expect_array_response(user_1)

          next_cursor = graphql_data_at(:project, :projectMembers, :pageInfo, :endCursor)
          fetch_members(project: parent_project, args: { search: 'Same Name', first: 1, after: next_cursor })

          expect_array_response(user_2)
        end
      end
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
        expect(graphql_data_at(:project, :project_members, :edges, :node)).to contain_exactly(
          a_graphql_entity_for(user: a_graphql_entity_for(user)),
          { 'user' => nil }
        )
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

      expect(graphql_errors.first).to include(
        'path' => %w[query project projectMembers relations],
        'message' => a_string_including('invalid value ([OBLIQUE])')
      )
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

  context 'merge request interactions' do
    let(:project_path) { var('ID!').with(parent_project.full_path) }
    let(:mr_a) do
      var('MergeRequestID!')
        .with(global_id_of(create(:merge_request, source_project: parent_project, source_branch: 'branch-1')))
    end

    let(:mr_b) do
      var('MergeRequestID!')
        .with(global_id_of(create(:merge_request, source_project: parent_project, source_branch: 'branch-2')))
    end

    let(:interaction_query) do
      <<~HEREDOC
      edges {
        node {
          user {
            id
          }
          mrA: #{query_graphql_field(:merge_request_interaction, { id: mr_a }, 'canMerge')}
        }
      }
      HEREDOC
    end

    let(:interaction_b_query) do
      <<~HEREDOC
      edges {
        node {
          user {
            id
          }
          mrA: #{query_graphql_field(:merge_request_interaction, { id: mr_a }, 'canMerge')}
          mrB: #{query_graphql_field(:merge_request_interaction, { id: mr_b }, 'canMerge')}
        }
      }
      HEREDOC
    end

    it 'avoids N+1 queries, when requesting multiple MRs' do
      control_query = with_signature(
        [project_path, mr_a],
        graphql_query_for(
          :project,
          { full_path: project_path },
          query_graphql_field(:project_members, nil, interaction_query)
        )
      )
      query_two = with_signature(
        [project_path, mr_a, mr_b],
        graphql_query_for(
          :project,
          { full_path: project_path },
          query_graphql_field(:project_members, nil, interaction_b_query)
        )
      )

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(control_query, current_user: user, variables: [project_path, mr_a])
      end

      # two project members, neither of whom can merge
      expect(can_merge(:mrA)).to eq [false, false]

      expect do
        post_graphql(query_two, current_user: user, variables: [project_path, mr_a, mr_b])

        expect(can_merge(:mrA)).to eq [false, false]
        expect(can_merge(:mrB)).to eq [false, false]
      end.not_to exceed_query_limit(control_count)
    end

    it 'avoids N+1 queries, when more users are involved' do
      new_user = create(:user)

      query = with_signature(
        [project_path, mr_a],
        graphql_query_for(
          :project,
          { full_path: project_path },
          query_graphql_field(:project_members, nil, interaction_query)
        )
      )

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: user, variables: [project_path, mr_a])
      end

      # two project members, neither of whom can merge
      expect(can_merge(:mrA)).to eq [false, false]

      parent_project.add_guest(new_user)

      expect do
        post_graphql(query, current_user: user, variables: [project_path, mr_a])

        expect(can_merge(:mrA)).to eq [false, false, false]
      end.not_to exceed_query_limit(control_count)
    end

    def can_merge(name)
      graphql_data_at(:project, :project_members, :edges, :node, name, :can_merge)
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
    pageInfo {
      endCursor
    }
    NODE

    graphql_query_for('project',
      { full_path: group_path },
      [query_graphql_field('projectMembers', args, members_node)]
    )
  end

  def expect_array_response(*items)
    expect(response).to have_gitlab_http_status(:success)
    members = graphql_data_at(:project, :project_members, :edges, :node, :user)
    expect(members).to match_array(items.map { |u| a_graphql_entity_for(u) })
  end
end
