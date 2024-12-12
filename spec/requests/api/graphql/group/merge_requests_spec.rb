# frozen_string_literal: true

require 'spec_helper'

# Based on ee/spec/requests/api/epics_spec.rb
# Should follow closely in order to ensure all situations are covered
RSpec.describe 'Query.group.mergeRequests', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:group)     { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }

  let_it_be(:project_a) { create(:project, :repository, group: group) }
  let_it_be(:project_b) { create(:project, :repository, group: group) }
  let_it_be(:project_c) { create(:project, :repository, group: sub_group) }
  let_it_be(:project_x) { create(:project, :repository) }
  let_it_be(:user)      { create(:user, developer_of: [project_x, group]) }

  let_it_be(:archived_project) { create(:project, :archived, :repository, group: group) }
  let_it_be(:archived_mr) { create(:merge_request, source_project: archived_project) }

  let_it_be(:mr_attrs) do
    { target_branch: 'master' }
  end

  let_it_be(:mr_traits) do
    [:unique_branches, :unique_author]
  end

  let_it_be(:mrs_a, reload: true) { create_list(:merge_request, 2, *mr_traits, **mr_attrs, source_project: project_a) }
  let_it_be(:mrs_b, reload: true) { create_list(:merge_request, 2, *mr_traits, **mr_attrs, source_project: project_b) }
  let_it_be(:mrs_c, reload: true) { create_list(:merge_request, 2, *mr_traits, **mr_attrs, source_project: project_c) }
  let_it_be(:other_mr) { create(:merge_request, source_project: project_x) }

  let(:mrs_data) { graphql_data_at(:group, :merge_requests, :nodes) }

  def expected_mrs(mrs)
    mrs.map { |mr| a_graphql_entity_for(mr) }
  end

  describe 'not passing any arguments' do
    let(:query) do
      <<~GQL
      query($path: ID!) {
        group(fullPath: $path) {
          mergeRequests { nodes { id } }
        }
      }
      GQL
    end

    it 'can find all merge requests in the group, excluding sub-groups' do
      post_graphql(query, current_user: user, variables: { path: group.full_path })

      expect(mrs_data).to match_array(expected_mrs(mrs_a + mrs_b))
    end
  end

  describe 'restricting by author' do
    let(:query) do
      <<~GQL
      query($path: ID!, $user: String) {
        group(fullPath: $path) {
          mergeRequests(authorUsername: $user) { nodes { id author { username } } }
        }
      }
      GQL
    end

    let(:author) { mrs_b.first.author }

    it 'can find all merge requests with user as author' do
      post_graphql(query, current_user: user, variables: { user: author.username, path: group.full_path })

      expect(mrs_data).to match_array(expected_mrs([mrs_b.first]))
    end
  end

  describe 'restricting by assignee' do
    let(:query) do
      <<~GQL
      query($path: ID!, $user: String) {
        group(fullPath: $path) {
          mergeRequests(assigneeUsername: $user) { nodes { id } }
        }
      }
      GQL
    end

    let_it_be(:assignee) { create(:user) }

    before_all do
      mrs_b.second.assignees << assignee
      mrs_a.first.assignees << assignee
    end

    it 'can find all merge requests assigned to user' do
      post_graphql(query, current_user: user, variables: { user: assignee.username, path: group.full_path })

      expect(mrs_data).to match_array(expected_mrs([mrs_a.first, mrs_b.second]))
    end
  end

  context 'when filtering by reviewer' do
    let(:query) do
      <<~GQL
      query($path: ID!, $user: String) {
        group(fullPath: $path) {
          mergeRequests(reviewerUsername: $user) { nodes { id } }
        }
      }
      GQL
    end

    let_it_be(:reviewer) { create(:user) }

    before do
      mrs_a.first.reviewers << reviewer
    end

    it 'returns all merge requests assigned to reviewer' do
      post_graphql(query, current_user: user, variables: { user: reviewer.username, path: group.full_path })

      expect(mrs_data).to match_array(expected_mrs([mrs_a.first]))
    end
  end

  describe 'passing include_subgroups: true' do
    let(:query) do
      <<~GQL
      query($path: ID!) {
        group(fullPath: $path) {
          mergeRequests(includeSubgroups: true) { nodes { id } }
        }
      }
      GQL
    end

    it 'can find all merge requests in the group, including sub-groups' do
      post_graphql(query, current_user: user, variables: { path: group.full_path })

      expect(mrs_data).to match_array(expected_mrs(mrs_a + mrs_b + mrs_c))
    end
  end

  describe 'passing include_archived: true' do
    let(:query) do
      <<~GQL
      query($path: ID!) {
        group(fullPath: $path) {
          mergeRequests(includeArchived: true) { nodes { id } }
        }
      }
      GQL
    end

    it 'can find all merge requests in the group, including from archived projects' do
      post_graphql(query, current_user: user, variables: { path: group.full_path })

      expect(mrs_data).to match_array(expected_mrs(mrs_a + mrs_b + [archived_mr]))
    end
  end
end
