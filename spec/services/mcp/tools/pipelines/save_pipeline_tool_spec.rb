# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Pipelines::SavePipelineTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }

  let(:params) { { project_id: project.full_path, ref: 'master' } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
  end

  describe 'operation selection' do
    context 'when pipeline_id is absent' do
      it 'selects the create mutation' do
        expect(tool.operation_name).to eq('pipelineCreate')
        expect(tool.graphql_operation).to include('mutation createPipeline')
      end
    end

    context 'when pipeline_id is present with action retry' do
      let(:params) { { pipeline_id: pipeline.id, action: 'retry' } }

      it 'selects the retry mutation' do
        expect(tool.operation_name).to eq('pipelineRetry')
        expect(tool.graphql_operation).to include('mutation mcpRetryPipeline')
      end
    end

    context 'when pipeline_id is present with action cancel' do
      let(:params) { { pipeline_id: pipeline.id, action: 'cancel' } }

      it 'selects the cancel mutation' do
        expect(tool.operation_name).to eq('pipelineCancel')
        expect(tool.graphql_operation).to include('mutation mcpCancelPipeline')
      end
    end

    context 'when pipeline_id is present without action' do
      let(:params) { { pipeline_id: pipeline.id } }

      it 'raises an error' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Provide action: "retry", "cancel", or "update" when pipeline_id is set')
      end
    end

    context 'when neither pipeline_id nor ref is present' do
      let(:params) { { project_id: project.full_path } }

      it 'raises an error' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Provide ref to create a pipeline, or pipeline_id and action')
      end
    end
  end

  describe '#build_variables' do
    context 'when creating a pipeline' do
      it 'resolves the project path from project_id' do
        expect(tool.build_variables).to eq({ input: { projectPath: project.full_path, ref: 'master' } })
      end

      context 'with url' do
        let(:params) { { url: project.web_url, ref: 'master' } }

        it 'resolves the project path from the url' do
          expect(tool.build_variables[:input][:projectPath]).to eq(project.full_path)
        end
      end

      context 'with both url and project_id' do
        let(:params) { { url: project.web_url, project_id: project.full_path, ref: 'master' } }

        it 'raises an error' do
          expect { tool.build_variables }.to raise_error(ArgumentError, 'Provide exactly one of: url or project_id')
        end
      end

      context 'with variables and inputs' do
        let(:params) do
          {
            project_id: project.full_path,
            ref: 'master',
            variables: [{ 'key' => 'DEPLOY', 'value' => 'true', 'variable_type' => 'env_var' }],
            inputs: { 'stage' => 'test' }
          }
        end

        it 'maps them to the mutation input shape' do
          expect(tool.build_variables[:input]).to include(
            variables: [{ key: 'DEPLOY', value: 'true', variableType: 'ENV_VAR' }],
            inputs: [{ name: 'stage', value: 'test' }]
          )
        end
      end
    end

    context 'when acting on an existing pipeline' do
      let(:params) { { pipeline_id: pipeline.id, action: 'retry' } }

      it 'builds the pipeline global ID' do
        expect(tool.build_variables).to eq({ input: { id: "gid://gitlab/Ci::Pipeline/#{pipeline.id}" } })
      end
    end
  end

  describe '#execute' do
    let_it_be(:running_pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :running) }
    let_it_be(:running_build) { create(:ci_build, :running, pipeline: running_pipeline) }

    let(:params) { { pipeline_id: running_pipeline.id, action: 'cancel' } }

    it 'returns a compact pipeline payload with a plain ID and an absolute URL', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to eq(
        action: 'cancel',
        id: running_pipeline.id,
        status: 'running',
        ref: 'master',
        web_url: "#{project.web_url}/-/pipelines/#{running_pipeline.id}"
      )
    end
  end
end
