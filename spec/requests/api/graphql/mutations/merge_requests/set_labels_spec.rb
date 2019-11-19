# frozen_string_literal: true

require 'spec_helper'

describe 'Setting labels of a merge request' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label, project: project) }
  let(:input) { { label_ids: [GitlabSchema.id_from_object(label).to_s] } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(:merge_request_set_labels, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       mergeRequest {
                         id
                         labels {
                           nodes {
                             id
                           }
                         }
                       }
    QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_labels)
  end

  def mutation_label_nodes
    mutation_response['mergeRequest']['labels']['nodes']
  end

  before do
    project.add_developer(current_user)
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'sets the merge request labels, removing existing ones' do
    merge_request.update(labels: [label2])

    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_label_nodes.count).to eq(1)
    expect(mutation_label_nodes[0]['id']).to eq(label.to_global_id.to_s)
  end

  context 'when passing label_ids empty array as input' do
    let(:input) { { label_ids: [] } }

    it 'removes the merge request labels' do
      merge_request.update!(labels: [label])

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_label_nodes.count).to eq(0)
    end
  end

  context 'when passing operation_mode as APPEND' do
    let(:input) { { operation_mode: Types::MutationOperationModeEnum.enum[:append], label_ids: [GitlabSchema.id_from_object(label).to_s] } }

    before do
      merge_request.update!(labels: [label2])
    end

    it 'sets the labels, without removing others' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_label_nodes.count).to eq(2)
      expect(mutation_label_nodes).to contain_exactly({ 'id' => label.to_global_id.to_s }, { 'id' => label2.to_global_id.to_s })
    end
  end

  context 'when passing operation_mode as REMOVE' do
    let(:input) { { operation_mode: Types::MutationOperationModeEnum.enum[:remove], label_ids: [GitlabSchema.id_from_object(label).to_s] } }

    before do
      merge_request.update!(labels: [label, label2])
    end

    it 'removes the labels, without removing others' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_label_nodes.count).to eq(1)
      expect(mutation_label_nodes[0]['id']).to eq(label2.to_global_id.to_s)
    end
  end
end
