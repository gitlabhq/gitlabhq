# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new branch' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :empty_repo) }

  let(:input) { { project_path: project.full_path, name: new_branch, ref: ref } }
  let(:new_branch) { 'new_branch' }
  let(:ref) { 'master' }

  let(:mutation) { graphql_mutation(:create_branch, input) }
  let(:mutation_response) { graphql_mutation_response(:create_branch) }

  context 'the user is not allowed to create a branch' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create a branch' do
    before do
      project.add_developer(current_user)
    end

    it 'creates a new branch' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['branch']).to include(
        'name' => new_branch,
        'commit' => a_hash_including('id')
      )
    end

    context 'when ref is not correct' do
      let(:new_branch) { 'another_branch' }
      let(:ref) { 'unknown' }

      it_behaves_like 'a mutation that returns errors in the response',
                      errors: ['Invalid reference name: unknown']
    end
  end
end
