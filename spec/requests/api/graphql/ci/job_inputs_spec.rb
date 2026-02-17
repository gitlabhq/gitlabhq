# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.job.inputs', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          job(id: "#{job.to_global_id}") {
            inputsSpec {
              name
              type
              default
              required
            }
            inputs {
              name
              value
            }
          }
        }
      }
    )
  end

  let_it_be(:user) { create(:user) }

  before_all do
    project.add_developer(user)
  end

  describe 'inputsSpec' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    context 'when job is not a Build' do
      let(:job) { create(:ci_bridge, project: project, pipeline: pipeline) }

      it 'returns an empty array' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :job, :inputsSpec)).to eq([])
      end
    end

    context 'when job has no inputs' do
      let(:job) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'returns an empty array' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :job, :inputsSpec)).to eq([])
      end
    end

    context 'when job has empty inputs hash' do
      let(:job) { create(:ci_build, project: project, options: { inputs: {} }) }

      it 'returns an empty array' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :job, :inputsSpec)).to eq([])
      end
    end

    context 'when job has inputs configuration' do
      let(:inputs_spec) do
        {
          environment: { type: 'string', default: 'staging' },
          version: { type: 'string' }
        }
      end

      let(:job) { create(:ci_build, project: project, pipeline: pipeline, options: { inputs: inputs_spec }) }

      it 'returns input specifications' do
        post_graphql(query, current_user: user)

        inputs = graphql_data_at(:project, :job, :inputsSpec)
        expect(inputs).to be_an(Array)
        expect(inputs.size).to eq(2)
        expect(inputs.pluck('name')).to contain_exactly('environment', 'version')
      end
    end
  end

  describe 'inputs' do
    context 'when job is not a Build' do
      let(:job) { create(:ci_bridge, project: project) }

      it 'returns nil' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :job, :inputs)).to be_nil
      end
    end

    context 'when job has no persisted input values' do
      let(:job) { create(:ci_build, project: project) }

      it 'returns an empty array' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :job, :inputs)).to be_empty
      end
    end

    context 'when job has persisted input values' do
      let(:job) { create(:ci_build, project: project) }

      before do
        create(:ci_job_input, job: job, project: project, name: 'environment', value: 'production')
        create(:ci_job_input, job: job, project: project, name: 'debug', value: true)
      end

      it 'returns the persisted input values' do
        post_graphql(query, current_user: user)

        inputs = graphql_data_at(:project, :job, :inputs)
        expect(inputs).to be_an(Array)
        expect(inputs.size).to eq(2)
        expect(inputs.pluck('name')).to contain_exactly('environment', 'debug')
        expect(inputs.pluck('value')).to contain_exactly('production', true)
      end
    end
  end

  describe 'input fields call limit' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:job1) do
      create(:ci_build, project: project, pipeline: pipeline, options: { inputs: { env: { type: 'string' } } })
    end

    let_it_be(:job2) do
      create(:ci_build, project: project, pipeline: pipeline, options: { inputs: { version: { type: 'string' } } })
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              jobs {
                nodes {
                  id
                  inputsSpec {
                    name
                    type
                  }
                  inputs {
                    name
                    value
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'returns an error when requesting inputsSpec for multiple jobs' do
      post_graphql(query, current_user: user)

      expect_graphql_errors_to_include(
        '"inputsSpec" field can be requested only for 1 CiJob(s) at a time.'
      )
      expect_graphql_errors_to_include(
        '"inputs" field can be requested only for 1 CiJob(s) at a time.'
      )
    end
  end
end
