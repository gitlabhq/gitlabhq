# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineScheduleUpdate', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

  let(:mutation) do
    variables = {
      id: pipeline_schedule.to_global_id.to_s,
      **pipeline_schedule_parameters
    }

    graphql_mutation(
      :pipeline_schedule_update,
      variables,
      <<-QL
        pipelineSchedule {
          id
          description
          cron
          refForDisplay
          active
          cronTimezone
          variables {
            nodes {
              key
              value
            }
          }
        }
        errors
      QL
    )
  end

  let(:pipeline_schedule_parameters) { {} }
  let(:mutation_response) { graphql_mutation_response(:pipeline_schedule_update) }

  context 'when unauthorized' do
    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: create(:user))

      expect(graphql_errors).not_to be_empty
      expect(graphql_errors[0]['message'])
        .to eq(
          "The resource that you are attempting to access does not exist " \
          "or you don't have permission to perform this action"
        )
    end
  end

  context 'when authorized' do
    before do
      project.add_developer(user)
    end

    context 'when success' do
      let(:pipeline_schedule_parameters) do
        {
          description: 'updated_desc',
          cron: '0 1 * * *',
          cronTimezone: 'UTC',
          ref: 'patch-x',
          active: true,
          variables: [
            { key: 'AAA', value: "AAA123", variableType: 'ENV_VAR' }
          ]
        }
      end

      it do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)

        expect_graphql_errors_to_be_empty

        expect(mutation_response['pipelineSchedule']['id']).to eq(pipeline_schedule.to_global_id.to_s)

        %w[description cron cronTimezone active].each do |key|
          expect(mutation_response['pipelineSchedule'][key]).to eq(pipeline_schedule_parameters[key.to_sym])
        end

        expect(mutation_response['pipelineSchedule']['refForDisplay']).to eq(pipeline_schedule_parameters[:ref])

        expect(mutation_response['pipelineSchedule']['variables']['nodes'][0]['key']).to eq('AAA')
        expect(mutation_response['pipelineSchedule']['variables']['nodes'][0]['value']).to eq('AAA123')
      end
    end

    context 'when failure' do
      context 'when params are invalid' do
        let(:pipeline_schedule_parameters) do
          {
            description: '',
            cron: 'abc',
            cronTimezone: 'cCc',
            ref: '',
            active: true,
            variables: []
          }
        end

        it do
          post_graphql_mutation(mutation, current_user: user)

          expect(response).to have_gitlab_http_status(:success)

          expect(mutation_response['errors'])
            .to match_array(
              [
                "Cron  is invalid syntax",
                "Cron timezone  is invalid syntax",
                "Ref can't be blank",
                "Description can't be blank"
              ]
            )
        end
      end

      context 'when params have duplicate variables' do
        let(:pipeline_schedule_parameters) do
          {
            variables: [
              { key: 'AAA', value: "AAA123", variableType: 'ENV_VAR' },
              { key: 'AAA', value: "AAA123", variableType: 'ENV_VAR' }
            ]
          }
        end

        it 'returns error' do
          post_graphql_mutation(mutation, current_user: user)

          expect(response).to have_gitlab_http_status(:success)

          expect(mutation_response['errors'])
            .to match_array(
              [
                "Variables have duplicate values (AAA)"
              ]
            )
        end
      end
    end
  end
end
