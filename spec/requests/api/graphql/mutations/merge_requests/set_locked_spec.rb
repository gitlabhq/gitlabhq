# frozen_string_literal: true

require 'spec_helper'

describe 'Setting locked status of a merge request' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:input) { { locked: true } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(:merge_request_set_locked, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       mergeRequest {
                         id
                         discussionLocked
                       }
    QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_locked)['mergeRequest']['discussionLocked']
  end

  before do
    project.add_developer(current_user)
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'marks the merge request as WIP' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response).to eq(true)
  end

  it 'does not do anything if the merge request was already locked' do
    merge_request.update!(discussion_locked: true)

    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response).to eq(true)
  end

  context 'when passing locked false as input' do
    let(:input) { { locked: false } }

    it 'does not do anything if the merge request was not marked locked' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response).to eq(false)
    end

    it 'unmarks the merge request as locked' do
      merge_request.update!(discussion_locked: true)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response).to eq(false)
    end
  end
end
