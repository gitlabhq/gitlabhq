# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineScheduleUpdate', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: current_user) }

  let_it_be(:variable_one) do
    create(:ci_pipeline_schedule_variable, key: 'foo', value: 'foovalue', pipeline_schedule: pipeline_schedule)
  end

  let_it_be(:variable_two) do
    create(:ci_pipeline_schedule_variable, key: 'bar', value: 'barvalue', pipeline_schedule: pipeline_schedule)
  end

  let(:repository) { project.repository }
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
              variableType
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
    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when authorized' do
    before_all do
      project.update!(ci_pipeline_variables_minimum_override_role: :developer)
      project.add_developer(current_user)
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

      before do
        repository.add_branch(project.creator, 'patch-x', 'master')
      end

      it do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)

        expect_graphql_errors_to_be_empty

        expect(mutation_response['pipelineSchedule']['id']).to eq(pipeline_schedule.to_global_id.to_s)

        %w[description cron cronTimezone active].each do |key|
          expect(mutation_response['pipelineSchedule'][key]).to eq(pipeline_schedule_parameters[key.to_sym])
        end

        expect(mutation_response['pipelineSchedule']['refForDisplay']).to eq(pipeline_schedule_parameters[:ref])

        expect(mutation_response['pipelineSchedule']['variables']['nodes'][2]['key']).to eq('AAA')
        expect(mutation_response['pipelineSchedule']['variables']['nodes'][2]['value']).to eq('AAA123')
      end
    end

    context 'when updating and removing variables' do
      let(:pipeline_schedule_parameters) do
        {
          variables: [
            { key: 'ABC', value: "ABC123", variableType: 'ENV_VAR', destroy: false },
            { id: variable_one.to_global_id.to_s,
              key: 'foo', value: "foovalue",
              variableType: 'ENV_VAR',
              destroy: true },
            { id: variable_two.to_global_id.to_s, key: 'newbar', value: "newbarvalue", variableType: 'ENV_VAR' }
          ]
        }
      end

      it 'processes variables correctly' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)

        expect(mutation_response['pipelineSchedule']['variables']['nodes'])
          .to match_array(
            [
              { "key" => 'newbar', "value" => 'newbarvalue', "variableType" => 'ENV_VAR' },
              { "key" => 'ABC', "value" => "ABC123", "variableType" => 'ENV_VAR' }
            ]
          )
      end
    end

    context 'when failure' do
      context 'when params are invalid' do
        let(:ref) { '' }
        let(:pipeline_schedule_parameters) do
          {
            description: '',
            cron: 'abc',
            cronTimezone: 'cCc',
            ref: ref,
            active: true,
            variables: []
          }
        end

        it 'only returns the ref error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)

          expect(mutation_response['errors'])
            .to match_array(
              [
                "Ref is ambiguous"
              ]
            )
        end

        context 'when ref is valid' do
          let(:ref) { "#{Gitlab::Git::TAG_REF_PREFIX}some_tag" }

          it 'returns the rest of the errors' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)

            expect(mutation_response['errors'])
              .to match_array(
                [
                  "Cron syntax is invalid",
                  "Cron timezone syntax is invalid",
                  "Description can't be blank"
                ]
              )
          end
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
          post_graphql_mutation(mutation, current_user: current_user)

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
