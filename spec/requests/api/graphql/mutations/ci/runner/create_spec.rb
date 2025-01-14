# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnerCreate', feature_category: :runner do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let_it_be(:group) { create(:group, owners: group_owner) }
  let_it_be(:other_group) { create(:group) }

  let(:mutation_params) do
    {
      description: 'create description',
      maintenance_note: 'create maintenance note',
      maximum_timeout: 900,
      access_level: 'REF_PROTECTED',
      paused: true,
      run_untagged: false,
      tag_list: %w[tag1 tag2]
    }.deep_merge(mutation_scope_params)
  end

  let(:mutation) do
    graphql_mutation(
      :runner_create,
      mutation_params,
      <<-QL
        runner {
          ephemeralAuthenticationToken

          runnerType
          description
          maintenanceNote
          paused
          tagList
          accessLevel
          locked
          maximumTimeout
          runUntagged
        }
        errors
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:runner_create) }

  shared_context 'when model is invalid returns error' do
    let(:mutation_params) do
      {
        description: '',
        maintenanceNote: '',
        paused: true,
        accessLevel: 'NOT_PROTECTED',
        runUntagged: false,
        tagList: [],
        maximumTimeout: 1
      }.deep_merge(mutation_scope_params)
    end

    it do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)

      expect(mutation_response['errors']).to contain_exactly(
        'Tags list can not be empty when runner is not allowed to pick untagged jobs',
        'Maximum timeout needs to be at least 10 minutes'
      )
    end
  end

  shared_context 'when user does not have permissions' do
    let(:current_user) { user }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(
        'The resource that you are attempting to access does not exist ' \
        "or you don't have permission to perform this action"
      )
    end
  end

  shared_examples 'when runner is created successfully' do
    it do
      expected_args = { user: current_user, params: anything }
      expect_next_instance_of(::Ci::Runners::CreateRunnerService, expected_args) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)

      expect(mutation_response['errors']).to eq([])
      expect(mutation_response['runner']).not_to be_nil
      mutation_params.except(:group_id, :project_id).each_key do |key|
        expect(mutation_response['runner'][key.to_s.camelize(:lower)]).to eq mutation_params[key]
      end

      expect(mutation_response['runner']['ephemeralAuthenticationToken'])
        .to start_with Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX
    end
  end

  context 'when runnerType is INSTANCE_TYPE' do
    let(:mutation_scope_params) do
      { runner_type: 'INSTANCE_TYPE' }
    end

    it_behaves_like 'when user does not have permissions'

    context 'when user has permissions', :enable_admin_mode do
      let(:current_user) { admin }

      it_behaves_like 'when runner is created successfully'
      it_behaves_like 'when model is invalid returns error'
    end
  end

  context 'when runnerType is GROUP_TYPE' do
    let(:mutation_scope_params) do
      {
        runner_type: 'GROUP_TYPE',
        group_id: group.to_global_id
      }
    end

    it_behaves_like 'when user does not have permissions'

    context 'when user has permissions' do
      context 'when user is group owner' do
        let(:current_user) { group_owner }

        it_behaves_like 'when runner is created successfully'
        it_behaves_like 'when model is invalid returns error'

        context 'when group_id is missing' do
          let(:mutation_scope_params) do
            { runner_type: 'GROUP_TYPE' }
          end

          it 'returns an error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect_graphql_errors_to_include('`group_id` is missing')
          end
        end

        context 'when group_id is malformed' do
          let(:mutation_scope_params) do
            {
              runner_type: 'GROUP_TYPE',
              group_id: ''
            }
          end

          it 'returns an error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect_graphql_errors_to_include(
              "RunnerCreateInput! was provided invalid value for groupId"
            )
          end
        end

        context 'when group_id does not exist' do
          let(:mutation_scope_params) do
            {
              runner_type: 'GROUP_TYPE',
              group_id: "gid://gitlab/Group/#{non_existing_record_id}"
            }
          end

          it 'returns an error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(flattened_errors).not_to be_empty
          end
        end
      end

      context 'when user is admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }

        it_behaves_like 'when runner is created successfully'
        it_behaves_like 'when model is invalid returns error'
      end
    end
  end

  context 'when runnerType is PROJECT_TYPE' do
    let_it_be(:project) { create(:project, namespace: group) }

    let(:mutation_scope_params) do
      {
        runner_type: 'PROJECT_TYPE',
        project_id: project.to_global_id
      }
    end

    it_behaves_like 'when user does not have permissions'

    context 'when user has permissions' do
      context 'when user is group owner' do
        let(:current_user) { group_owner }

        it_behaves_like 'when runner is created successfully'
        it_behaves_like 'when model is invalid returns error'

        context 'when project_id is missing' do
          let(:mutation_scope_params) do
            { runner_type: 'PROJECT_TYPE' }
          end

          it 'returns an error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect_graphql_errors_to_include('`project_id` is missing')
          end
        end

        context 'when project_id is malformed' do
          let(:mutation_scope_params) do
            {
              runner_type: 'PROJECT_TYPE',
              project_id: ''
            }
          end

          it 'returns an error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect_graphql_errors_to_include(
              "RunnerCreateInput! was provided invalid value for projectId"
            )
          end
        end

        context 'when project_id does not exist' do
          let(:mutation_scope_params) do
            {
              runner_type: 'PROJECT_TYPE',
              project_id: "gid://gitlab/Project/#{non_existing_record_id}"
            }
          end

          it 'returns an error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect_graphql_errors_to_include(
              'The resource that you are attempting to access does not exist ' \
              "or you don't have permission to perform this action"
            )
          end
        end
      end

      context 'when user is admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }

        it_behaves_like 'when runner is created successfully'
        it_behaves_like 'when model is invalid returns error'
      end
    end
  end
end
