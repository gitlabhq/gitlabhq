# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating merge request work item relations', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let(:link_type) { 'MENTIONED' }
  let(:work_item_ids) { [global_id_of(work_item).to_s] }
  let(:input) { { work_item_ids: work_item_ids, link_type: link_type } }

  let(:mutation) do
    variables = { project_path: project.full_path, iid: merge_request.iid.to_s }

    graphql_mutation(
      :merge_request_create_work_item_relations,
      variables.merge(input),
      <<-QL.strip_heredoc
        errors
        workItemRelations {
          linkType
          fromMrDescription
          workItem { id }
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_create_work_item_relations)
  end

  it 'creates a user-created relation with the given link type', :aggregate_failures do
    expect { post_graphql_mutation(mutation, current_user: current_user) }
      .to change { merge_request.merge_request_issues.count }.by(1)

    expect(response).to have_gitlab_http_status(:success)
    relation = mutation_response['workItemRelations'].first
    expect(relation['linkType']).to eq('MENTIONED')
    expect(relation['fromMrDescription']).to be(false)
    expect(relation.dig('workItem', 'id')).to eq(global_id_of(work_item, model_name: 'WorkItem').to_s)
  end

  it 'returns an error when the user cannot admin the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_merge_request do
    let(:link_type) { 'RELATED' }
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(explicit_mr_work_item_relations: false)
    end

    it 'does not create a relation and returns a top-level error' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { merge_request.merge_request_issues.count }

      expect(graphql_errors).not_to be_empty
    end
  end
end
