# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying merge request work item relations', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be_with_refind(:relation) do
    create(:merge_requests_closing_issues,
      merge_request: merge_request, issue: create(:issue, project: project),
      link_type: :mentioned, from_mr_description: false)
  end

  let(:ids) { [global_id_of(relation).to_s] }
  let(:input) { { ids: ids } }

  let(:mutation) do
    variables = { project_path: project.full_path, iid: merge_request.iid.to_s }

    graphql_mutation(
      :merge_request_destroy_work_item_relations,
      variables.merge(input),
      <<-QL.strip_heredoc
        errors
        removedRelationIds
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_destroy_work_item_relations)
  end

  it 'removes the relation and returns its global id', :aggregate_failures do
    expect { post_graphql_mutation(mutation, current_user: current_user) }
      .to change { merge_request.merge_request_issues.count }.by(-1)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['removedRelationIds']).to contain_exactly(global_id_of(relation).to_s)
  end

  it 'returns an error when the user cannot admin the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  context 'when the user can update but not admin the merge request' do
    let_it_be(:author) { create(:user, guest_of: project) }
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, author: author, source_branch: 'authored-branch')
    end

    it 'returns the authorization error instead of failing with an internal error', :aggregate_failures do
      expect { post_graphql_mutation(mutation, current_user: author) }
        .not_to change { merge_request.merge_request_issues.count }

      expect(graphql_errors).to be_nil
      expect(mutation_response['errors']).to be_present
      expect(mutation_response['removedRelationIds']).to be_nil
    end
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_merge_request do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(explicit_mr_work_item_relations: false)
    end

    it 'does not remove the relation and returns a top-level error' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { merge_request.merge_request_issues.count }

      expect(graphql_errors).not_to be_empty
    end
  end
end
