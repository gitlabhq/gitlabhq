# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting current users assigned or review requested merge requests', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:merge_request_1) do
    create(:merge_request, :unique_branches, source_project: project, reviewers: [current_user])
  end

  let_it_be(:reviewer_change_requested) do
    create(:merge_request, :unique_branches, source_project: project, assignees: [current_user],
      reviewers: create_list(:user, 2))
  end

  let_it_be(:merge_request_3) do
    create(:merge_request, :unique_branches, source_project: project, assignees: [current_user])
  end

  let(:merge_requests) { graphql_data.dig('currentUser', 'assigneeOrReviewerMergeRequests', 'nodes') }

  let(:fields) do
    <<~GRAPHQL
      nodes { id }
    GRAPHQL
  end

  def query(params = {})
    graphql_query_for('currentUser', {}, query_graphql_field('assigneeOrReviewerMergeRequests', params, fields))
  end

  before_all do
    project.add_developer(current_user)

    reviewer_change_requested.merge_request_reviewers[0].update!(state: :requested_changes)
  end

  context 'when merge_request_dashboard feature flag is disabled' do
    before do
      stub_feature_flags(merge_request_dashboard: false)
    end

    it do
      post_graphql(query, current_user: current_user)

      expect(merge_requests).to be_nil
    end
  end

  context 'when merge_request_dashboard feature flag is enabled' do
    before do
      stub_feature_flags(merge_request_dashboard: true)
    end

    it do
      post_graphql(query, current_user: current_user)

      expect(merge_requests).to contain_exactly(
        a_hash_including('id' => merge_request_1.to_global_id.to_s),
        a_hash_including('id' => reviewer_change_requested.to_global_id.to_s),
        a_hash_including('id' => merge_request_3.to_global_id.to_s)
      )
    end

    context 'when assigned_review_states argument is sent' do
      it do
        post_graphql(query({ assigned_review_states: [:REVIEWED] }), current_user: current_user)

        expect(merge_requests).to contain_exactly(
          a_hash_including('id' => merge_request_1.to_global_id.to_s)
        )
      end
    end

    context 'when reviewer_review_states argument is sent' do
      it do
        post_graphql(query({ reviewer_review_states: [:REQUESTED_CHANGES] }), current_user: current_user)

        expect(merge_requests).to contain_exactly(
          a_hash_including('id' => reviewer_change_requested.to_global_id.to_s),
          a_hash_including('id' => merge_request_3.to_global_id.to_s)
        )
      end
    end

    context 'when reviewer_review_states and assigned_review_states arguments are sent' do
      it do
        post_graphql(query({ reviewer_review_states: [:UNREVIEWED], assigned_review_states: [:REQUESTED_CHANGES] }),
          current_user: current_user)

        expect(merge_requests).to contain_exactly(
          a_hash_including('id' => merge_request_1.to_global_id.to_s),
          a_hash_including('id' => reviewer_change_requested.to_global_id.to_s)
        )
      end
    end
  end
end
