# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'accepting a merge request', :request_store do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let!(:merge_request) { create(:merge_request, source_project: project) }
  let(:input) do
    {
      project_path: project.full_path,
      iid: merge_request.iid.to_s,
      sha: merge_request.diff_head_sha
    }
  end

  let(:mutation) { graphql_mutation(:merge_request_accept, input, 'mergeRequest { state }') }
  let(:mutation_response) { graphql_mutation_response(:merge_request_accept) }

  context 'when the user is not allowed to accept a merge request' do
    before do
      project.add_reporter(current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create a merge request' do
    before do
      project.add_maintainer(current_user)
    end

    it 'merges the merge request' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['mergeRequest']).to include(
        'state' => 'merged'
      )
    end
  end
end
