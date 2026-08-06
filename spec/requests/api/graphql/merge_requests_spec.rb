# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a merge request list at root level', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:non_member) { create(:user) }

  let_it_be(:group1) { create(:group, developers: current_user) }
  let_it_be(:group2) { create(:group, developers: current_user) }
  let_it_be(:other_group) { create(:group, :private) }

  let_it_be(:project_a) { create(:project, :repository, :public, group: group1) }
  let_it_be(:project_b) { create(:project, :repository, :private, group: group1) }
  let_it_be(:project_c) { create(:project, :repository, :public, group: group2) }
  let_it_be(:inaccessible_project) { create(:project, :repository, :private, group: other_group) }

  let_it_be_with_reload(:mr_a) { create(:merge_request, :unique_branches, :unique_author, source_project: project_a) }
  let_it_be_with_reload(:mr_b) { create(:merge_request, :unique_branches, :unique_author, source_project: project_b) }
  let_it_be_with_reload(:mr_c) { create(:merge_request, :unique_branches, :unique_author, source_project: project_c) }
  let_it_be(:inaccessible_mr) { create(:merge_request, source_project: inaccessible_project) }

  let_it_be(:visible_mrs) { [mr_a, mr_b, mr_c] }
  let_it_be(:base_params) { { state: :opened } }

  let(:fields) do
    <<~QUERY
      nodes { id }
    QUERY
  end

  let(:mrs_data) { graphql_data_at(:merge_requests, :nodes) }

  def expected_mrs(mrs)
    mrs.map { |mr| a_graphql_entity_for(mr) }
  end

  def post_query(params = base_params, user: current_user)
    post_graphql(graphql_query_for(:merge_requests, params, fields), current_user: user)
  end

  def post_filtered(**filters)
    post_query(base_params.merge(filters))
  end

  describe 'filter requirement' do
    let(:filter_error) do
      hash_including('message' => _('You must provide at least one filter argument for this query'))
    end

    it 'requires at least one filter to be provided to the query' do
      post_query({})

      expect(graphql_errors).to contain_exactly(filter_error)
    end

    it 'raises the filter error when only an empty array argument is given' do
      post_query({ iids: [] })

      expect(graphql_errors).to contain_exactly(filter_error)
    end

    it 'accepts a boolean filter set to false' do
      post_query({ draft: false })

      expect_graphql_errors_to_be_empty
      expect(mrs_data).to match_array(expected_mrs(visible_mrs))
    end

    it 'returns no results (without leaking all merge requests) when a real filter is combined with an ' \
      'empty array argument' do
      post_query({ author_username: mr_a.author.username, iids: [] })

      expect_graphql_errors_to_be_empty
      expect(mrs_data).to be_empty
    end
  end

  describe 'fetching merge requests across projects' do
    it 'returns merge requests from visible projects, and none from projects it cannot access' do
      post_query

      expect(mrs_data).to match_array(expected_mrs(visible_mrs))
    end

    it 'returns only merge requests from public projects for non-members and anonymous users' do
      post_query(user: non_member)
      expect(mrs_data).to match_array(expected_mrs([mr_a, mr_c]))

      post_query(user: nil)
      expect(mrs_data).to match_array(expected_mrs([mr_a, mr_c]))
    end

    context 'when a public project restricts the merge requests feature to members' do
      let_it_be(:restricted_project) do
        create(:project, :repository, :public, :merge_requests_private, group: group1)
      end

      let_it_be(:restricted_mr) { create(:merge_request, source_project: restricted_project) }

      it 'returns the merge request for a member' do
        post_query

        expect(mrs_data).to match_array(expected_mrs(visible_mrs + [restricted_mr]))
      end

      it 'hides the merge request from non-members and anonymous users' do
        post_query(user: non_member)
        expect(mrs_data).to match_array(expected_mrs([mr_a, mr_c]))

        post_query(user: nil)
        expect(mrs_data).to match_array(expected_mrs([mr_a, mr_c]))
      end
    end
  end

  describe 'filtering' do
    let_it_be(:assignee) { create(:user) }
    let_it_be(:reviewer) { create(:user) }

    before_all do
      mr_c.assignees << assignee
      mr_a.reviewers << reviewer
    end

    it 'filters by state' do
      mr_a.close!
      post_filtered(state: :closed)

      expect(mrs_data).to match_array(expected_mrs([mr_a]))
    end

    it 'filters by author' do
      post_filtered(author_username: mr_b.author.username)

      expect(mrs_data).to match_array(expected_mrs([mr_b]))
    end

    it 'filters by assignee' do
      post_filtered(assignee_username: assignee.username)

      expect(mrs_data).to match_array(expected_mrs([mr_c]))
    end

    it 'filters by reviewer' do
      post_filtered(reviewer_username: reviewer.username)

      expect(mrs_data).to match_array(expected_mrs([mr_a]))
    end
  end

  describe 'includeArchived argument' do
    let_it_be(:archived_project) { create(:project, :repository, :public, :archived, group: group1) }
    let_it_be(:archived_mr) { create(:merge_request, source_project: archived_project) }

    it 'excludes merge requests from archived projects by default' do
      post_query

      expect(mrs_data).to match_array(expected_mrs(visible_mrs))
    end

    it 'includes merge requests from archived projects when includeArchived is true' do
      post_filtered(include_archived: true)

      expect(mrs_data).to match_array(expected_mrs(visible_mrs + [archived_mr]))
    end
  end

  describe 'N+1 queries' do
    let(:fields) do
      <<~QUERY
        nodes { id reference(full: true) author { username } project { fullPath } }
      QUERY
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      post_query # warm-up
      expect_graphql_errors_to_be_empty

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_query }

      3.times do
        project = create(:project, :repository, :public, group: create(:group, developers: current_user))
        create(:merge_request, :unique_branches, source_project: project)
      end

      expect { post_query }.not_to exceed_all_query_limit(control).with_threshold(0)
      expect_graphql_errors_to_be_empty
    end
  end

  describe 'sorting and pagination' do
    let(:data_path) { [:merge_requests] }
    let(:first_param) { 2 }

    before_all do
      mr_a.update!(created_at: 3.days.ago)
      mr_b.update!(created_at: 2.days.ago)
      mr_c.update!(created_at: 1.day.ago)
    end

    def pagination_results_data(nodes)
      nodes
    end

    def pagination_query(params)
      graphql_query_for(:merge_requests, base_params.merge(**params.to_h), "#{page_info} nodes { id }")
    end

    context 'when sorting by created_at ascending' do
      let(:sort_param) { :CREATED_ASC }
      let(:all_records) { expected_mrs([mr_a, mr_b, mr_c]) }

      it_behaves_like 'sorted paginated query'
    end

    context 'when sorting by created_at descending' do
      let(:sort_param) { :CREATED_DESC }
      let(:all_records) { expected_mrs([mr_c, mr_b, mr_a]) }

      it_behaves_like 'sorted paginated query'
    end
  end
end
