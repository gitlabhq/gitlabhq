# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::UnassignFromProject, feature_category: :runner_core do
  include GraphqlHelpers

  let_it_be(:group_owner) { create(:user) }
  let_it_be(:project_owner) { create(:user) }
  let_it_be(:group) { create(:group, owners: group_owner) }
  let_it_be(:owner_project) { create(:project, namespace: group, owners: project_owner) }
  let_it_be(:project) { create(:project, namespace: group, owners: project_owner) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [owner_project, project]) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_accessible_user) { create(:user) }

  let(:mutation_params) do
    {
      project_path: project.full_path,
      runner_id: runner.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(
      :runner_unassign_from_project,
      mutation_params,
      'errors'
    )
  end

  let(:mutation_response) { graphql_mutation_response(:runner_unassign_from_project) }

  specify { expect(described_class).to require_graphql_authorizations(:unassign_runner) }

  context 'with invalid parameters' do
    context 'when project_path is missing' do
      let(:mutation_params) do
        {
          runner_id: runner.to_global_id
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect_graphql_errors_to_include("invalid value for projectPath")
      end
    end

    context 'when project_path is invalid' do
      let(:mutation_params) do
        {
          runner_id: runner.to_global_id,
          project_path: 'non/existing/project/path'
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you " \
          "don't have permission to perform this action")
      end
    end

    context 'when runner_id is missing' do
      let(:mutation_params) do
        {
          project_path: project.full_path
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect_graphql_errors_to_include('invalid value for runnerId')
      end
    end

    context 'when runner_id is invalid' do
      let(:mutation_params) do
        {
          runner_id: "gid://gitlab/Ci::Runner/#{non_existing_record_id}",
          project_path: project.full_path
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you " \
          "don't have permission to perform this action")
      end
    end
  end

  context 'with permission checks' do
    context 'when user does not have necessary permissions' do
      it 'does not allow non-accessible user to unassign a runner from a project' do
        post_graphql_mutation(mutation, current_user: non_accessible_user)
        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to include("User not allowed to manage project's runners")
        expect(runner.reload.projects).to include(project)
      end
    end

    context 'when user has necessary permissions' do
      context 'when the user is group owner' do
        it 'allows group owner to unassign a runner from a project' do
          post_graphql_mutation(mutation, current_user: group_owner)
          expect(response).to have_gitlab_http_status(:success)
          expect(runner.reload.projects).not_to include(project)
        end
      end

      context 'when user is admin', :enable_admin_mode do
        it 'allows admin to unassign a runner from a project' do
          post_graphql_mutation(mutation, current_user: admin)
          expect(response).to have_gitlab_http_status(:success)
          expect(runner.reload.projects).not_to include(project)
        end
      end

      context 'when the user is project owner' do
        it 'allows project owner to unassign a runner from a project' do
          post_graphql_mutation(mutation, current_user: project_owner)
          expect(response).to have_gitlab_http_status(:success)
          expect(runner.reload.projects).not_to include(project)
        end
      end
    end
  end

  context 'with runner assignment scenarios' do
    context 'when the runner is not assigned to the project' do
      let_it_be(:project2) { create(:project, namespace: group) }
      let(:mutation_params) do
        {
          project_path: project2.full_path,
          runner_id: runner.to_global_id
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you " \
          "don't have permission to perform this action")
        expect(runner.reload.projects).to include(project)
      end
    end

    context 'when the runner is the last one assigned to the project' do
      it 'successfully unassigns the runner' do
        expect(project.runners.count).to eq(1)
        post_graphql_mutation(mutation, current_user: project_owner)
        expect(response).to have_gitlab_http_status(:success)
        expect(project.reload.runners.count).to eq(0)
      end
    end

    context 'when the project has multiple runners' do
      let_it_be(:another_runner) { create(:ci_runner, :project, projects: [project]) }

      it 'only unassigns the specified runner' do
        expect(project.runners.count).to eq(2)
        post_graphql_mutation(mutation, current_user: project_owner)
        expect(response).to have_gitlab_http_status(:success)
        expect(project.reload.runners.count).to eq(1)
        expect(project.runners).to include(another_runner)
        expect(project.runners).not_to include(runner)
      end
    end

    context 'when unassigning a owner project from the runner' do
      let(:mutation_params) do
        {
          project_path: owner_project.full_path,
          runner_id: runner.to_global_id
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect(mutation_response['errors']).to include("You cannot unassign a runner from the owner project. " \
          "Delete the runner instead")
      end
    end
  end

  context 'when service returns an error' do
    before do
      service = instance_double(::Ci::Runners::UnassignRunnerService)
      result = ServiceResponse.error(message: 'Custom error message')

      allow(::Ci::Runners::UnassignRunnerService).to receive(:new).and_return(service)
      allow(service).to receive(:execute).and_return(result)
    end

    it 'returns the error from the service' do
      post_graphql_mutation(mutation, current_user: project_owner)
      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['errors']).to include('Custom error message')
    end
  end
end
