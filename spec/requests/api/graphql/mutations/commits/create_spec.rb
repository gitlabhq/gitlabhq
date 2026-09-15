# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new commit', feature_category: :source_code_management do
  include GraphqlHelpers
  include ProjectForksHelper

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:input) { { project_path: project.full_path, branch: branch, message: message, actions: actions } }
  let(:branch) { 'master' }
  let(:message) { 'Commit message' }
  let(:file_path) { "NEW_FILE_#{SecureRandom.hex(4)}.md" }
  let(:actions) do
    [
      {
        action: 'CREATE',
        filePath: file_path,
        content: 'Hello'
      }
    ]
  end

  let(:mutation) { graphql_mutation(:commit_create, input) }
  let(:mutation_response) { graphql_mutation_response(:commit_create) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :push_code do
    let(:user) { create(:user, developer_of: project) }
    let(:boundary_object) { project }
    let(:mutation) { graphql_mutation(:commit_create, input, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

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
            filePath: "ANOTHER_FILE_#{SecureRandom.hex(4)}.md",
            content: 'Bye'
          }
        ]
      end

      it_behaves_like 'a commit is successful'
    end

    context 'when branch is new, and a start_sha is defined' do
      let(:input) do
        { project_path: project.full_path, branch: branch, start_sha: start_sha, message: message, actions: actions }
      end

      let(:branch) { 'new-branch-from-sha' }
      let(:start_sha) { project.repository.commit('master~1').sha }

      it 'creates the commit on a branch starting from the sha', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty

        new_commit = project.repository.commit(branch)
        expect(new_commit.parent_ids).to contain_exactly(start_sha)
      end

      context 'with a start_branch as well' do
        let(:input) { super().merge(start_branch: 'master') }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['Only one of [startBranch, startSha] arguments is allowed at the same time.']
      end

      context 'with an unknown sha' do
        let(:start_sha) { 'a' * 40 }

        it_behaves_like 'a mutation that returns errors in the response',
          errors: ["Cannot find start_sha '#{'a' * 40}'"]
      end
    end

    context 'when start_project_path is defined' do
      let_it_be(:upstream) { create(:project, :public, :repository) }
      let_it_be(:forked_project) { fork_project(upstream, nil, repository: true) }

      # Only exists in the upstream repository, so the commit can only be built
      # from it when start_project actually reaches the commit service.
      let_it_be(:upstream_only_sha) do
        upstream.repository.create_file(
          upstream.first_owner, 'upstream-only.md', 'Upstream',
          message: 'Upstream only', branch_name: 'master'
        )
      end

      let(:input) do
        { project_path: forked_project.full_path, branch: branch, start_sha: start_sha,
          start_project_path: upstream.full_path, message: message, actions: actions }
      end

      let(:branch) { 'new-branch-from-upstream' }
      let(:start_sha) { upstream_only_sha }

      before_all do
        forked_project.add_developer(current_user)
      end

      it 'creates the commit starting from the upstream project', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty
        expect(forked_project.repository.commit(branch).parent_ids).to contain_exactly(upstream_only_sha)
      end

      context 'when the start project is not in the fork network' do
        let_it_be(:unrelated) { create(:project, :public) }

        let(:input) { super().merge(start_project_path: unrelated.full_path) }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['startProjectPath is not the project or a member of its fork network, or you cannot read its code.']
      end

      context 'when the start project cannot be read' do
        let_it_be(:private_upstream) { create(:project, :private, :repository) }
        let_it_be(:private_fork) { fork_project(private_upstream, nil, repository: true) }

        let(:input) do
          { project_path: private_fork.full_path, branch: 'new-branch-from-private-upstream',
            start_sha: private_fork.repository.commit('master').sha,
            start_project_path: private_upstream.full_path, message: message, actions: actions }
        end

        before_all do
          private_fork.add_developer(current_user)
        end

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['startProjectPath is not the project or a member of its fork network, or you cannot read its code.']
      end

      context 'when the start project does not exist' do
        let(:input) { super().merge(start_project_path: 'does/not-exist') }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['startProjectPath is not the project or a member of its fork network, or you cannot read its code.']
      end
    end

    context 'when allow_empty is true' do
      let(:allow_empty) { true }

      context 'when actions argument is missing' do
        let(:input) { { project_path: project.full_path, branch: branch, message: message, allow_empty: allow_empty } }

        it_behaves_like 'a commit is successful'
      end

      context 'when actions is null' do
        let(:input) { { project_path: project.full_path, branch: branch, message: message, allow_empty: allow_empty, actions: nil } }

        it_behaves_like 'a commit is successful'
      end
    end

    context 'when actions argument is missing' do
      context 'when allow_empty is missing' do
        let(:input) { { project_path: project.full_path, branch: branch, message: message } }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['Provide at least one action, or set allowEmpty to true.']
      end

      context 'when allow_empty is null' do
        let(:input) { { project_path: project.full_path, branch: branch, message: message, allow_empty: nil } }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['Provide at least one action, or set allowEmpty to true.']
      end
    end

    context 'when actions is null and allow_empty is null' do
      let(:input) { { project_path: project.full_path, branch: branch, message: message } }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['Provide at least one action, or set allowEmpty to true.']
    end
  end
end
