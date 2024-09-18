# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting current users merge requests from an archived project', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :archived, :public) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:merge_request) do
    create(:merge_request, :unique_branches, source_project: project, assignees: [current_user])
  end

  let(:merge_requests) { graphql_data.dig('currentUser', 'assignedMergeRequests', 'nodes') }

  let(:fields) do
    <<~GRAPHQL
      nodes { id }
    GRAPHQL
  end

  def query(params = {})
    graphql_query_for('currentUser', {}, query_graphql_field('assignedMergeRequests', params, fields))
  end

  before_all do
    project.add_developer(current_user)
  end

  it 'filters out merge requests from archived projects' do
    post_graphql(query({ include_archived: false }), current_user: current_user)

    expect(merge_requests).to be_empty
  end

  it 'includes merge requests from archived projects' do
    post_graphql(query({ include_archived: true }), current_user: current_user)

    expect(merge_requests).to contain_exactly(
      a_hash_including('id' => merge_request.to_global_id.to_s)
    )
  end
end
