# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new branch', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }

  let(:input) { { project_path: project.full_path, name: new_branch, ref: ref } }
  let(:new_branch) { "new_branch_#{SecureRandom.hex(4)}" }
  let(:ref) { 'master' }

  let(:mutation) { graphql_mutation(:create_branch, input) }
  let(:mutation_response) { graphql_mutation_response(:create_branch) }

  shared_examples 'creates a new branch' do
    specify do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['branch']).to include(
        'name' => new_branch,
        'commit' => a_hash_including('id')
      )
    end
  end

  context 'when project is public' do
    let_it_be(:project) { create(:project, :public, :empty_repo) }

    context 'when user is not allowed to create a branch' do
      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when user is a direct project member' do
      context 'and user is a developer' do
        before_all do
          project.add_developer(current_user)
        end

        it_behaves_like 'creates a new branch'

        context 'when ref is not correct' do
          err_msg = 'Failed to create branch \'another_branch\': invalid reference name \'unknown\''
          let(:new_branch) { 'another_branch' }
          let(:ref) { 'unknown' }

          it_behaves_like 'a mutation that returns errors in the response', errors: [err_msg]
        end
      end
    end

    context 'when user is an inherited member from the group' do
      context 'when project has a private repository' do
        let_it_be(:project) { create(:project, :public, :empty_repo, :repository_private, group: group) }

        context 'and user is a guest' do
          before_all do
            group.add_guest(current_user)
          end

          it_behaves_like 'a mutation that returns a top-level access error'
        end

        context 'and user is a developer' do
          before_all do
            group.add_developer(current_user)
          end

          it_behaves_like 'creates a new branch'
        end
      end
    end
  end

  context 'when project is private' do
    let_it_be(:project) { create(:project, :private, :empty_repo, group: group) }

    context 'when user is an inherited member from the group' do
      context 'and user is a guest' do
        before_all do
          group.add_guest(current_user)
        end

        it_behaves_like 'a mutation that returns a top-level access error'
      end

      context 'and user is a developer' do
        before_all do
          group.add_developer(current_user)
        end

        it_behaves_like 'creates a new branch'
      end
    end
  end
end
