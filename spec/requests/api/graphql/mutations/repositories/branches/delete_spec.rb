# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deletion of a branch', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }

  let(:input) { { project_path: project_path, name: branch_name } }
  let(:project_path) { project.full_path }
  let(:branch_name) { 'master' }

  let(:mutation) { graphql_mutation(:branch_delete, input) }
  let(:mutation_response) { graphql_mutation_response(:branch_delete) }

  shared_examples 'deletes a branch' do
    specify do
      expect(project.repository.find_branch(branch_name)).to be_present

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)

      expect(mutation_response).to have_key('branch')
      expect(mutation_response['branch']).to be_nil
      expect(mutation_response['errors']).to be_empty

      expect(project.repository.find_branch(branch_name)).to be_nil
    end
  end

  context 'when project is public' do
    let(:project) { create(:project, :public, :small_repo) }

    context 'when user is not allowed to delete a branch' do
      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when user is a direct project member' do
      context 'and user is a developer' do
        before do
          project.add_developer(current_user)
        end

        it_behaves_like 'deletes a branch'

        context 'when ref is not correct' do
          let(:branch_name) { 'unknown' }

          it_behaves_like 'a mutation that returns errors in the response', errors: ['No such branch']
        end

        context 'when path is not correct' do
          let(:project_path) { 'unknown' }

          it_behaves_like 'a mutation that returns a top-level access error'
        end
      end
    end
  end
end
