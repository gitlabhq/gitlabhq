# frozen_string_literal: true

require 'spec_helper'

# Regression coverage (!240762): a mentioned-but-not-closing issue must appear under both
# the derived `linkedWorkItems` and the persisted `workItemRelations`.
RSpec.describe 'Query.mergeRequest mentioned-relation parity', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:mentioned_issue) { create(:issue, project: project) }

  let_it_be(:merge_request) do
    create(:merge_request,
      source_project: project,
      source_branch: 'feature',
      target_branch: project.default_branch,
      description: "Relates to #{mentioned_issue.to_reference}")
  end

  let(:fields) do
    <<~GRAPHQL
      linkedWorkItems(types: [MENTIONED]) { linkType workItem { id } }
      workItemRelations(types: [MENTIONED]) { nodes { linkType workItem { id } } }
    GRAPHQL
  end

  let(:query) { graphql_query_for('mergeRequest', { 'id' => global_id_of(merge_request) }, fields) }

  before do
    merge_request.persist_merge_request_issues!(developer)
    post_graphql(query, current_user: developer)
  end

  it 'returns the mentioned work item under both linkedWorkItems and workItemRelations', :aggregate_failures do
    expected_gid = global_id_of(mentioned_issue, model_name: 'WorkItem').to_s

    linked_ids = graphql_data_at(:merge_request, :linked_work_items).pluck('workItem').pluck('id')
    relations_ids = graphql_data_at(:merge_request, :work_item_relations, :nodes).pluck('workItem').pluck('id')

    expect(linked_ids).to contain_exactly(expected_gid)
    expect(relations_ids).to contain_exactly(expected_gid)
  end
end
