# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new commit', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:input) { { project_path: project.full_path, branch: branch, message: message, actions: actions } }
  let(:branch) { 'master' }
  let(:message) { 'Commit message' }
  let(:actions) do
    [
      {
        action: 'CREATE',
        filePath: 'NEW_FILE.md',
        content: 'Hello'
      }
    ]
  end

  let(:mutation) { graphql_mutation(:commit_create, input) }
  let(:mutation_response) { graphql_mutation_response(:commit_create) }

  shared_examples 'a commit is successful' do
    it 'creates a new commit' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)

      expect(mutation_response['commit']).to include(
        'title' => message
      )
    end
  end

  context 'the user is not allowed to create a commit' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create a commit' do
    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a commit is successful'

    context 'when branch is not correct' do
      let(:branch) { 'unknown' }

      it_behaves_like 'a mutation that returns errors in the response',
        errors: ['You can only create or edit files when you are on a branch']
    end

    context 'when branch is new, and a start_branch is defined' do
      let(:input) { { project_path: project.full_path, branch: branch, start_branch: start_branch, message: message, actions: actions } }
      let(:branch) { 'new-branch' }
      let(:start_branch) { 'master' }
      let(:actions) do
        [
          {
            action: 'CREATE',
            filePath: 'ANOTHER_FILE.md',
            content: 'Bye'
          }
        ]
      end

      it_behaves_like 'a commit is successful'
    end
  end
end
