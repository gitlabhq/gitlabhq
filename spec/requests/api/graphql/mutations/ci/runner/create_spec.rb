# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnerCreate', feature_category: :runner_fleet do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let(:mutation_params) do
    {
      description: 'create description',
      maintenance_note: 'create maintenance note',
      maximum_timeout: 900,
      access_level: 'REF_PROTECTED',
      paused: true,
      run_untagged: false,
      tag_list: %w[tag1 tag2]
    }
  end

  let(:mutation) do
    variables = {
      **mutation_params
    }

    graphql_mutation(
      :runner_create,
      variables,
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

  context 'when user does not have permissions' do
    let(:current_user) { user }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['errors']).to contain_exactly "Insufficient permissions"
    end
  end

  context 'when user has permissions', :enable_admin_mode do
    let(:current_user) { admin }

    context 'when :create_runner_workflow feature flag is disabled' do
      before do
        stub_feature_flags(create_runner_workflow: false)
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).not_to be_empty
        expect(graphql_errors[0]['message'])
          .to eq("`create_runner_workflow` feature flag is disabled.")
      end
    end

    context 'when success' do
      it do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)

        mutation_params.each_key do |key|
          expect(mutation_response['runner'][key.to_s.camelize(:lower)]).to eq mutation_params[key]
        end

        expect(mutation_response['runner']['ephemeralAuthenticationToken']).to start_with 'glrt'

        expect(mutation_response['errors']).to eq([])
      end
    end

    context 'when failure' do
      let(:mutation_params) do
        {
          description: "",
          maintenanceNote: "",
          paused: true,
          accessLevel: "NOT_PROTECTED",
          runUntagged: false,
          tagList:
            [],
          maximumTimeout: 1
        }
      end

      it do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)

        expect(mutation_response['errors']).to contain_exactly(
          "Tags list can not be empty when runner is not allowed to pick untagged jobs",
          "Maximum timeout needs to be at least 10 minutes"
        )
      end
    end
  end
end
