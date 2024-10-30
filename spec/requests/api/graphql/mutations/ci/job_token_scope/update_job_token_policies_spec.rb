# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CiJobTokenScopeUpdatePolicies', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) do
    create(:project, ci_inbound_job_token_scope_enabled: true)
  end

  let(:variables) do
    {
      project_path: project.full_path,
      target_path: target_path,
      job_token_policies: policies
    }
  end

  let(:mutation) do
    graphql_mutation(:ci_job_token_scope_update_policies, variables) do
      <<~QL
        errors
        ciJobTokenScope {
          projects {
            nodes {
              path
            }
          }
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:ci_job_token_scope_update_policies) }

  context 'when policies are updated for a target project' do
    let_it_be(:target_project) { create(:project, :private) }
    let_it_be(:target_path) { target_project.full_path }

    let(:policies) { %w[READ_PROJECT READ_PACKAGE] }

    context 'when user does not have permissions to admin project' do
      let_it_be(:current_user) { create(:user, guest_of: target_project) }

      it_behaves_like 'a mutation on an unauthorized resource'
    end

    context 'when user does not have permissions to read target project' do
      let_it_be(:current_user) { create(:user, maintainer_of: project) }

      it_behaves_like 'a mutation that returns errors in the response',
        errors: ['You have insufficient permission to update this job token scope']
    end

    context 'when authorized' do
      let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_project) }

      context 'when the job token scope does not exist' do
        it_behaves_like 'a mutation that returns errors in the response',
          errors: ['Unable to find a job token scope for the given project & target']
      end

      context 'when the job token scope exists' do
        before do
          create(
            :ci_job_token_project_scope_link,
            source_project: project,
            target_project: target_project,
            job_token_policies: %w[read_project],
            direction: :inbound
          )
        end

        it 'updates policies for target project' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)

          # TODO: include jobTokenPolicies in response,
          # https://gitlab.com/gitlab-org/govern/authorization/team-tasks/-/issues/87
          expect(mutation_response.dig('ciJobTokenScope', 'projects', 'nodes', 0, 'path')).to eq(project.path)
        end

        context 'when target path is invalid' do
          before do
            variables[:target_path] = 'unknown/project'
          end

          it_behaves_like 'a mutation that returns errors in the response', errors: ['The target does not exist']
        end

        context 'when the policies provided are invalid' do
          let(:policies) { %w[READ_ISSUE] }

          it_behaves_like 'a mutation that returns top-level errors' do
            let(:match_errors) { include(/was provided invalid value for jobTokenPolicies/) }
          end
        end

        context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
          before do
            stub_feature_flags(add_policies_to_ci_job_token: false)
          end

          it_behaves_like 'a mutation that returns top-level errors',
            errors: ["`add_policies_to_ci_job_token` feature flag is disabled."]
        end
      end
    end
  end

  context 'when policies are updated for a target group' do
    let_it_be(:target_group) { create(:group, :private) }
    let_it_be(:target_path) { target_group.full_path }

    let(:policies) { %w[READ_GROUP READ_PACKAGE] }

    context 'when user does not have permissions to admin project' do
      let_it_be(:current_user) { create(:user, guest_of: target_group) }

      it_behaves_like 'a mutation on an unauthorized resource'
    end

    context 'when user does not have permissions to read target group' do
      let_it_be(:current_user) { create(:user, maintainer_of: project) }

      it_behaves_like 'a mutation that returns errors in the response',
        errors: ['You have insufficient permission to update this job token scope']
    end

    context 'when authorized' do
      let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_group) }

      context 'when the job token scope does not exist' do
        it_behaves_like 'a mutation that returns errors in the response',
          errors: ['Unable to find a job token scope for the given project & target']
      end

      context 'when the job token scope exists' do
        before do
          create(
            :ci_job_token_group_scope_link,
            source_project: project,
            target_group: target_group,
            job_token_policies: %w[read_group]
          )
        end

        it 'updates policies for target group' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)

          # TODO: include jobTokenPolicies in response,
          # https://gitlab.com/gitlab-org/govern/authorization/team-tasks/-/issues/87
          expect(mutation_response.dig('ciJobTokenScope', 'projects', 'nodes', 0, 'path')).to eq(project.path)
        end

        context 'when target path is invalid' do
          before do
            variables[:target_path] = 'unknown/group'
          end

          it_behaves_like 'a mutation that returns errors in the response', errors: ['The target does not exist']
        end

        context 'when the policies provided are invalid' do
          let(:policies) { %w[READ_ISSUE] }

          it_behaves_like 'a mutation that returns top-level errors' do
            let(:match_errors) { include(/was provided invalid value for jobTokenPolicies/) }
          end
        end

        context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
          before do
            stub_feature_flags(add_policies_to_ci_job_token: false)
          end

          it_behaves_like 'a mutation that returns top-level errors',
            errors: ["`add_policies_to_ci_job_token` feature flag is disabled."]
        end
      end
    end
  end
end
