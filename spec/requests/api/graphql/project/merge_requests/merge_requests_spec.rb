# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge_requests information', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:common_attrs) { { author: user, source_project: project, target_project: project } }

  let(:node_path) { %w[project mergeRequests nodes] }

  before_all do
    project.add_developer(user)
  end

  describe 'query for merge_requests by subscribed' do
    let_it_be(:regular_merge_request) { create(:merge_request, :unique_branches, project: project, **common_attrs) }
    let_it_be(:subscribed_merge_request) { create(:merge_request, :unique_branches, project: project, **common_attrs) }
    let_it_be(:unsubscribed_merge_request) do
      create(:merge_request, :unique_branches, project: project, **common_attrs)
    end

    before_all do
      create(:subscription, subscribable: subscribed_merge_request, user: user, subscribed: true)
      create(:subscription, subscribable: unsubscribed_merge_request, user: user, subscribed: false)
    end

    it 'filters to subscribed merge_requests' do
      post_graphql(mr_query(project, subscribed: :EXPLICITLY_SUBSCRIBED), current_user: user)

      expect_mr_response([subscribed_merge_request], node_path: node_path)
    end

    it 'filters to unsubscribed merge_requests' do
      post_graphql(mr_query(project, subscribed: :EXPLICITLY_UNSUBSCRIBED), current_user: user)

      expect_mr_response([unsubscribed_merge_request], node_path: node_path)
    end

    it 'does not filter out subscribed merge_requests' do
      post_graphql(mr_query(project), current_user: user)

      expect_mr_response([subscribed_merge_request, unsubscribed_merge_request, regular_merge_request],
        node_path: node_path)
    end
  end

  def mr_query(project, args = {})
    fields = <<~QUERY
      nodes {
        id
      }
    QUERY

    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('merge_requests', args, fields)
    )
  end

  def expect_mr_response(merge_requests, node_path:)
    merge_requests ||= []
    nodes = graphql_data.dig(*node_path)
    actual_merge_requests = nodes.pluck('id')
    expected_merge_requests = merge_requests.map { |merge_request| merge_request.to_global_id.to_s }

    expect(actual_merge_requests).to contain_exactly(*expected_merge_requests)
    expect(graphql_errors).to be_nil
  end
end
