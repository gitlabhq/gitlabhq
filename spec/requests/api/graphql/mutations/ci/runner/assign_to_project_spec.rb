# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::AssignToProject, feature_category: :runner_core do
  include GraphqlHelpers

  let_it_be(:group_owner) { create(:user) }
  let_it_be(:project_owner) { create(:user) }
  let_it_be(:group) { create(:group, owners: group_owner) }
  let_it_be(:project) { create(:project, namespace: group, owners: project_owner) }
  let_it_be(:project2) { create(:project, namespace: group, owners: project_owner) }
  let_it_be(:project_with_org) { create(:project, organization: create(:organization), owners: project_owner) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project2]) }
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
      :runner_assign_to_project,
      mutation_params,
      'errors'
    )
  end

  let(:mutation_response) { graphql_mutation_response(:runner_assign_to_project) }

  specify { expect(described_class).to require_graphql_authorizations(:assign_runner) }

  context 'with invalid parameters' do
    context 'when project_path is not given' do
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

    context 'when runner_id is missing' do
      let(:mutation_params) do
        {
          project_path: project.full_path
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect_graphql_errors_to_include('was provided invalid value for runnerId')
      end
    end
  end

  context 'with runner type constraints' do
    context 'when the runner is not a project runner' do
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: group_owner)
        expect_graphql_errors_to_include('Runner is not a project runner')
      end
    end
  end

  context 'with organization constraints' do
    context "when project organization_id is not the same as the runner's" do
      let(:mutation_params) do
        {
          project_path: project_with_org.full_path,
          runner_id: runner.to_global_id
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: project_owner)
        expect(graphql_mutation_response(:runner_assign_to_project)['errors'])
          .to include("user is not authorized to add runners to project")
        expect(runner.reload.projects).not_to include(project)
      end
    end
  end

  context 'with permission checks' do
    context 'when user does not have necessary permissions' do
      it 'does not allow non-accessible user to assign a project to a runner' do
        post_graphql_mutation(mutation, current_user: non_accessible_user)
        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you " \
          "don't have permission to perform this action")
        expect(runner.reload.projects).not_to include(project)
      end
    end

    context 'when user has necessary permissions' do
      context 'when the user is group owner' do
        it 'allows accessible user to assign a project to a runner' do
          post_graphql_mutation(mutation, current_user: group_owner)
          expect(response).to have_gitlab_http_status(:success)
          expect(runner.reload.projects).to include(project)
        end

        context 'when the runner is locked' do
          let_it_be(:runner) { create(:ci_runner, :project, :locked, projects: [project2]) }

          it 'returns an error' do
            # this case is not explicitly handled in the mutation definition or service,
            # this is handled in the policy itself (app/policies/ci/runner_policy.rb)
            post_graphql_mutation(mutation, current_user: group_owner)
            expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you " \
              "don't have permission to perform this action")
            expect(runner.reload.projects).not_to include(project)
          end
        end

        context 'when the runner is already assigned to the project' do
          it 'assigns the project to the runner and does not duplicate the assignment' do
            post_graphql_mutation(mutation, current_user: group_owner)
            expect(response).to have_gitlab_http_status(:success)
            expect(runner.reload.projects).to include(project)

            # Check for duplicate assignments
            project_count = runner.reload.projects.count
            post_graphql_mutation(mutation, current_user: group_owner)
            expect(response).to have_gitlab_http_status(:success)
            expect(runner.reload.projects).to include(project)
            expect(runner.reload.projects.count).to eq(project_count)
          end
        end
      end

      context 'when user is admin', :enable_admin_mode do
        it 'allows accessible user to assign a project to a runner' do
          post_graphql_mutation(mutation, current_user: admin)
          expect(response).to have_gitlab_http_status(:success)
          expect(runner.reload.projects).to include(project)
        end
      end

      context 'when the user is project owner' do
        it 'allows accessible user to assign a project to a runner' do
          post_graphql_mutation(mutation, current_user: project_owner)
          expect(response).to have_gitlab_http_status(:success)
          expect(runner.reload.projects).to include(project)
        end
      end
    end
  end
end
