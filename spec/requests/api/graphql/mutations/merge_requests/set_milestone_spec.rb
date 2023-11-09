# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting milestone of a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:milestone) { create(:milestone, project: project) }
  let(:input) { { milestone_id: GitlabSchema.id_from_object(milestone).to_s } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(
      :merge_request_set_milestone,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
        mergeRequest {
          id
          milestone {
            id
          }
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_milestone)
  end

  before do
    project.add_developer(current_user)
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'sets the merge request milestone' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['mergeRequest']['milestone']['id']).to eq(milestone.to_global_id.to_s)
  end

  context 'when passing milestone_id nil as input' do
    let(:input) { { milestone_id: nil } }

    it 'removes the merge request milestone' do
      merge_request.update!(milestone: milestone)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['mergeRequest']['milestone']).to be_nil
    end
  end

  context 'when passing an invalid milestone_id' do
    let(:input) { { milestone_id: GitlabSchema.id_from_object(create(:milestone)).to_s } }

    it 'does not set the milestone' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to include(
        a_hash_including(
          'message' => "The resource that you are attempting to access does not exist " \
                       "or you don't have permission to perform this action"
        )
      )
    end
  end
end
