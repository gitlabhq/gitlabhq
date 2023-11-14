# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting Draft status of a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:input) { { draft: true } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(
      :merge_request_set_draft,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
        mergeRequest {
          id
          title
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_draft)
  end

  before do
    project.add_developer(current_user)
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'marks the merge request as Draft' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['mergeRequest']['title']).to start_with('Draft:')
  end

  it 'does not do anything if the merge request was already marked `Draft`' do
    merge_request.update!(title: 'draft: hello world')

    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['mergeRequest']['title']).to start_with('draft:')
  end

  context 'when passing Draft false as input' do
    let(:input) { { draft: false } }

    it 'does not do anything if the merge reqeust was not marked draft' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['mergeRequest']['title']).not_to start_with(/draft:/)
    end

    it 'unmarks the merge request as `Draft`' do
      merge_request.update!(title: 'draft: hello world')

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['mergeRequest']['title']).not_to start_with('/draft\:/')
    end
  end
end
