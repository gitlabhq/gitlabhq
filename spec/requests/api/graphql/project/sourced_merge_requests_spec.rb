# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting sourced merge requests of a project', feature_category: :code_review_workflow do
  include GraphqlHelpers
  include ProjectForksHelper

  let_it_be(:current_user, freeze: false) { create(:user) }
  let_it_be(:upstream_project, freeze: false) { create(:project, :repository, :public) }
  let_it_be(:forked_project, freeze: false) { fork_project(upstream_project, current_user, repository: true) }

  let_it_be(:upstream_targeting_mr, freeze: false) do
    create(:merge_request, source_project: forked_project, target_project: upstream_project,
      source_branch: 'feature')
  end

  let_it_be(:fork_local_mr, freeze: false) do
    create(:merge_request, source_project: forked_project, target_project: forked_project,
      source_branch: 'fix')
  end

  let(:args) { { source_branches: %w[feature fix] } }
  let(:fields) { 'nodes { id webPath }' }

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: forked_project.full_path },
      query_graphql_field(:sourced_merge_requests, args, fields)
    )
  end

  let(:results) { graphql_data_at(:project, :sourced_merge_requests, :nodes) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_merge_request] do
    let(:user) { current_user }
    let(:boundary_object) { forked_project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end

  it 'returns merge requests sourced from the project regardless of target project, newest first' do
    post_graphql(query, current_user: current_user)

    expect(results).to match(
      [
        a_graphql_entity_for(fork_local_mr),
        a_graphql_entity_for(
          upstream_targeting_mr,
          web_path: "/#{upstream_project.full_path}/-/merge_requests/#{upstream_targeting_mr.iid}"
        )
      ])
  end

  context 'when sourceBranches is empty' do
    let(:args) { { source_branches: [] } }

    it 'returns an empty connection without querying merge requests' do
      query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

      expect_graphql_errors_to_be_empty
      expect(results).to be_empty
      expect(query_recorder.log).not_to include(a_string_matching(/FROM "merge_requests"/))
    end
  end

  context 'when sourceBranches exceeds the maximum' do
    let(:max) { Resolvers::Projects::SourcedMergeRequestsResolver::MAX_SOURCE_BRANCHES }
    let(:args) { { source_branches: Array.new(max + 1) { |i| "branch-#{i}" } } }

    it 'returns a validation error without querying merge requests' do
      query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

      expect_graphql_errors_to_include(/sourceBranches is too long \(maximum is #{max}\)/)
      expect(query_recorder.log).not_to include(a_string_matching(/FROM "merge_requests"/))
    end
  end

  context 'with a state argument' do
    let_it_be(:closed_feature_mr, freeze: false) do
      create(:merge_request, :closed, source_project: forked_project, target_project: upstream_project,
        source_branch: 'feature')
    end

    let(:args) { { source_branches: ['feature'], state: :opened } }

    it 'returns only merge requests with the given state from the given source branches' do
      post_graphql(query, current_user: current_user)

      expect(results).to contain_exactly(a_graphql_entity_for(upstream_targeting_mr))
    end

    context 'when state is all' do
      let(:args) { { source_branches: ['feature'], state: :all } }

      it 'returns merge requests with any state' do
        post_graphql(query, current_user: current_user)

        expect(results).to contain_exactly(
          a_graphql_entity_for(upstream_targeting_mr),
          a_graphql_entity_for(closed_feature_mr)
        )
      end
    end
  end

  context 'when merge requests target a project the user cannot read' do
    let_it_be(:fork_creator, freeze: false) { create(:user) }
    let_it_be(:private_upstream, freeze: false) do
      create(:project, :repository, :private, developers: [fork_creator])
    end

    let_it_be(:private_fork, freeze: false) { fork_project(private_upstream, fork_creator, repository: true) }

    let_it_be(:mr_to_private_upstream, freeze: false) do
      create(:merge_request, source_project: private_fork, target_project: private_upstream,
        source_branch: 'feature')
    end

    let_it_be(:private_fork_local_mr, freeze: false) do
      create(:merge_request, source_project: private_fork, target_project: private_fork,
        source_branch: 'fix')
    end

    let_it_be(:merged_mr_to_private_upstream, freeze: false) do
      create(:merge_request, :with_merged_metrics, source_project: private_fork, target_project: private_upstream,
        source_branch: 'fix')
    end

    let(:fields) { 'count totalTimeToMerge nodes { id webPath }' }

    let(:query) do
      graphql_query_for(
        :project,
        { full_path: private_fork.full_path },
        query_graphql_field(:sourced_merge_requests, args, fields)
      )
    end

    before_all do
      private_fork.add_developer(current_user)
    end

    it 'filters them out and returns the readable merge requests' do
      post_graphql(query, current_user: current_user)

      expect(results).to contain_exactly(a_graphql_entity_for(private_fork_local_mr))
    end

    it 'does not leak unreadable merge requests through connection aggregates' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:project, :sourced_merge_requests, :count)).to eq(1)
      expect(graphql_data_at(:project, :sourced_merge_requests, :total_time_to_merge)).to be_nil
    end

    it 'returns no project for an anonymous user' do
      post_graphql(query)

      expect(graphql_data_at(:project)).to be_nil
    end
  end

  describe 'query performance' do
    let_it_be(:another_user, freeze: false) { create(:user) }
    let_it_be(:sibling_fork, freeze: false) { fork_project(upstream_project, another_user, repository: true) }

    let_it_be(:private_group, freeze: false) { create(:group, :private) }
    let_it_be(:private_sibling_fork, freeze: false) do
      fork_project(upstream_project, another_user, repository: true, namespace: private_group)
    end

    let_it_be(:second_private_sibling_fork, freeze: false) do
      fork_project(upstream_project, another_user, repository: true, namespace: private_group)
    end

    let_it_be(:mr_to_private_sibling, freeze: false) do
      create(:merge_request, source_project: forked_project, target_project: private_sibling_fork,
        source_branch: 'audio')
    end

    let(:args) { { source_branches: %w[feature fix audio improve/awesome spooky-stuff video] } }

    before_all do
      private_group.add_developer(current_user)
    end

    it 'avoids N+1 queries for additional merge requests' do
      post_graphql(query, current_user: current_user) # warm up

      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

      create(:merge_request, source_project: forked_project, target_project: sibling_fork,
        source_branch: 'improve/awesome')
      create(:merge_request, source_project: forked_project, target_project: forked_project,
        source_branch: 'spooky-stuff')
      create(:merge_request, source_project: forked_project, target_project: second_private_sibling_fork,
        source_branch: 'video')

      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
    end
  end
end
