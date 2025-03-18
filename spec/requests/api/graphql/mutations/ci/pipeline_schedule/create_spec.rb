# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineSchedulecreate', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public, :repository) }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      **pipeline_schedule_parameters
    }

    graphql_mutation(
      :pipeline_schedule_create,
      variables,
      <<-QL
        pipelineSchedule {
          id
          description
          cron
          refForDisplay
          active
          cronTimezone
          inputs {
            nodes {
              name
              value
            }
          }
          variables {
            nodes {
              key
              value
            }
          }
          owner {
            id
          }
        }
        errors
      QL
    )
  end

  let(:pipeline_schedule_parameters) do
    {
      description: 'created_desc',
      cron: '0 1 * * *',
      cronTimezone: 'UTC',
      ref: 'master',
      active: true,
      variables: [
        { key: 'AAA', value: "AAA123", variableType: 'ENV_VAR' }
      ],
      inputs: [
        { name: 'array_input', value: [1, 2] },
        { name: 'boolean_input', value: true },
        { name: 'number_input', value: 666 },
        { name: 'string_input', value: 'testing inputs' }
      ]
    }
  end

  let(:mutation_response) { graphql_mutation_response(:pipeline_schedule_create) }

  context 'when unauthorized' do
    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when authorized' do
    before_all do
      project.update!(ci_pipeline_variables_minimum_override_role: :developer)
      project.add_developer(current_user)
    end

    context 'when success' do
      it 'creates and returns a pipeline schedule' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)

        expect(mutation_response['pipelineSchedule']['owner']['id']).to eq(current_user.to_global_id.to_s)

        %w[description cron cronTimezone active].each do |key|
          expect(mutation_response['pipelineSchedule'][key]).to eq(pipeline_schedule_parameters[key.to_sym])
        end

        expect(mutation_response['pipelineSchedule']['refForDisplay']).to eq(pipeline_schedule_parameters[:ref])

        expect(mutation_response['pipelineSchedule']['variables']['nodes'][0]['key']).to eq('AAA')
        expect(mutation_response['pipelineSchedule']['variables']['nodes'][0]['value']).to eq('AAA123')

        expect(mutation_response['pipelineSchedule']['owner']['id']).to eq(current_user.to_global_id.to_s)

        expect(mutation_response['errors']).to eq([])

        inputs = mutation_response['pipelineSchedule']['inputs']['nodes']
        inputs_names = inputs.pluck('name')
        inputs_values = inputs.pluck('value')

        expect(inputs_names).to contain_exactly('array_input', 'boolean_input', 'number_input', 'string_input')
        expect(inputs_values).to contain_exactly([1, 2], true, 666, 'testing inputs')
      end

      context 'when ci_inputs_for_pipelines is disabled' do
        before do
          stub_feature_flags(ci_inputs_for_pipelines: false)
        end

        it 'does not persist inputs' do
          post_graphql_mutation(mutation, current_user: current_user)

          inputs = mutation_response['pipelineSchedule']['inputs']['nodes']
          expect(inputs).to be_empty
        end
      end
    end

    context 'when failure' do
      context 'when params are invalid' do
        let(:pipeline_schedule_parameters) do
          {
            description: 'some description',
            cron: 'abc',
            cronTimezone: 'cCc',
            ref: ref,
            active: true,
            variables: []
          }
        end

        let(:ref) { "#{Gitlab::Git::TAG_REF_PREFIX}asd" }

        it do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)

          expect(mutation_response['errors'])
            .to match_array(
              [
                "Cron syntax is invalid",
                "Cron timezone syntax is invalid"
              ]
            )
        end

        context 'when ref is short' do
          let(:ref) { "asd" }

          it 'returns ref is ambiguous' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)

            expect(mutation_response['errors'])
              .to match_array(
                [
                  "Ref is ambiguous"
                ]
              )
          end
        end
      end

      context 'when variables have duplicate name' do
        before do
          pipeline_schedule_parameters.merge!(
            {
              variables: [
                { key: 'AAA', value: "AAA123", variableType: 'ENV_VAR' },
                { key: 'AAA', value: "AAA123", variableType: 'ENV_VAR' }
              ]
            }
          )
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
