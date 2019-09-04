require 'spec_helper'

describe 'Setting WIP status of a merge request' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:input) { { wip: true } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(:merge_request_set_wip, variables.merge(input), "clientMutationId\nerrors\nmergeRequest { id\ntitle }")
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_wip)
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
    expect(mutation_response['mergeRequest']['title']).to start_with('WIP:')
  end

  it 'does not do anything if the merge request was already marked `WIP`' do
    merge_request.update!(title: 'wip: hello world')

    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['mergeRequest']['title']).to start_with('wip:')
  end

  context 'when passing WIP false as input' do
    let(:input) { { wip: false } }

    it 'does not do anything if the merge reqeust was not marked wip' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['mergeRequest']['title']).not_to start_with(/wip\:/)
    end

    it 'unmarks the merge request as `WIP`' do
      merge_request.update!(title: 'wip: hello world')

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['mergeRequest']['title']).not_to start_with('/wip\:/')
    end
  end
end
