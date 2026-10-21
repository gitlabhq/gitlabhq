# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.mergeRequest.mergeSource', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, :merged, source_project: project) }

  let(:boundary_object) { project }
  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:merge_request, { iid: merge_request.iid.to_s }, 'mergeSource { commitSha }')
    )
  end

  let(:request) { post_graphql(query, token: { personal_access_token: pat }) }

  before_all do
    create(:resource_state_event, merge_request: merge_request, state: :merged, source_commit: 'abcd1234')
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type',
    [:read_project, :read_merge_request] do
    let(:skipped_data_path) { %i[project merge_request merge_source] }
  end
end
