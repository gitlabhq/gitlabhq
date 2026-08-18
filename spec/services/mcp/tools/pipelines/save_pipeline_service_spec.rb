# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Pipelines::SavePipelineService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:service) { described_class.new(name: 'save_pipeline') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'is a write, destructive tool', :aggregate_failures do
      expect(service.annotations[:readOnlyHint]).to be(false)
      expect(service.annotations[:destructiveHint]).to be(true)
    end
  end

  describe '#input_schema' do
    it 'matches the expected contract' do
      expect(service.input_schema).to eq(
        {
          type: 'object',
          required: [],
          additionalProperties: false,
          properties: {
            url: {
              type: 'string',
              description: 'GitLab URL of the project. Used only when creating a pipeline.'
            },
            project_id: {
              type: 'string',
              description: 'ID or full path of the project. Used only when creating a pipeline.'
            },
            pipeline_id: {
              type: 'integer',
              description: 'ID of an existing pipeline to target. When set, requires action. ' \
                'Omit to create a new pipeline.'
            },
            action: {
              type: 'string',
              enum: %w[retry cancel],
              description: 'Lifecycle action to perform on pipeline_id. Required when pipeline_id is set.'
            },
            ref: {
              type: 'string',
              description: 'Branch or tag name. Required to create a pipeline (when pipeline_id is absent).'
            },
            variables: {
              type: 'array',
              description: 'Pipeline variables to create the pipeline with.',
              items: {
                type: 'object',
                properties: {
                  key: { type: 'string', description: 'Name of the variable.' },
                  value: { type: 'string', description: 'Value of the variable.' },
                  variable_type: {
                    type: 'string',
                    enum: %w[env_var file],
                    description: 'Type of the variable. Defaults to env_var.'
                  }
                },
                required: %w[key value]
              }
            },
            inputs: {
              type: 'object',
              description: 'Pipeline input parameters as key-value pairs.'
            }
          }
        }
      )
    end
  end

  describe '#execute' do
    context 'when creating a pipeline' do
      let(:params) { { arguments: { project_id: project.full_path, ref: project.default_branch } } }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(test: { script: 'echo test' }))
      end

      it 'creates a pipeline and returns its reference', :aggregate_failures do
        expect { service.execute(request: request, params: params) }
          .to change { project.ci_pipelines.count }.by(1)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(action: 'create', ref: project.default_branch)
      end

      context 'with variables and inputs' do
        let(:params) do
          {
            arguments: {
              project_id: project.full_path,
              ref: project.default_branch,
              variables: [{ key: 'DEPLOY_ENV', value: 'staging', variable_type: 'env_var' }],
              inputs: { job_name: 'my-input-job' }
            }
          }
        end

        before do
          stub_ci_pipeline_yaml_file(<<~YAML)
            spec:
              inputs:
                job_name:
            ---
            "$[[ inputs.job_name ]]":
              script: echo test
          YAML
        end

        it 'creates the pipeline with the variables and inputs applied', :aggregate_failures do
          expect { service.execute(request: request, params: params) }
            .to change { project.ci_pipelines.count }.by(1)

          created_pipeline = project.ci_pipelines.last

          expect(created_pipeline.variables.map(&:key)).to include('DEPLOY_ENV')
          expect(created_pipeline.builds.map(&:name)).to contain_exactly('my-input-job')
        end
      end
    end

    context 'when retrying a pipeline' do
      let_it_be(:failed_pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :failed) }
      let_it_be(:failed_build) { create(:ci_build, :failed, :retryable, pipeline: failed_pipeline) }

      let(:params) { { arguments: { pipeline_id: failed_pipeline.id, action: 'retry' } } }

      it 'retries the pipeline', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(action: 'retry', id: failed_pipeline.id)
      end
    end

    context 'when the pipeline does not exist' do
      let(:params) { { arguments: { pipeline_id: non_existing_record_id, action: 'cancel' } } }

      it 'returns an error response', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Couldn't find Ci::Pipeline")
      end
    end

    context 'with an invalid action' do
      let(:params) { { arguments: { pipeline_id: 1, action: 'delete' } } }

      it 'returns a validation error', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Invalid action: 'delete'")
      end
    end

    context 'when current_user is not set' do
      let(:params) { { arguments: { project_id: project.full_path, ref: 'master' } } }

      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
