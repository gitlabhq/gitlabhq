# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Pipelines::GetPipelineService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :success, source: :push) }

  let(:service) { described_class.new(name: 'get_pipeline') }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'inherits from GraphqlService' do
      expect(described_class.superclass).to eq(Mcp::Tools::Base::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'is read-only' do
      expect(described_class.version_metadata('0.1.0')[:annotations]).to eq({ readOnlyHint: true })
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          id: {
            type: 'string',
            description: 'ID or full path of the project'
          },
          pipeline_id: {
            type: 'integer',
            description: 'ID of the pipeline'
          },
          include: {
            type: 'array',
            description: 'Facet to include alongside the pipeline, one per call: jobs, downstream_pipelines, ' \
              'or bridge_jobs.',
            items: {
              type: 'string',
              enum: %w[jobs downstream_pipelines bridge_jobs]
            },
            maxItems: 1
          },
          job_status: {
            type: 'string',
            enum: ::Ci::HasStatus::AVAILABLE_STATUSES,
            description: 'Filters the jobs facet by status (for example, failed). ' \
              'Only applies when include is jobs.'
          },
          first: {
            type: 'integer',
            minimum: 1,
            maximum: 100,
            description: 'Number of items for the selected include facet to return after the cursor ' \
              '(forward pagination). Default 20, max 100.'
          },
          after: {
            type: 'string',
            description: 'Cursor for forward pagination of items for the selected include facet. ' \
              'Use page_info.end_cursor from a previous response.'
          }
        },
        required: %w[id pipeline_id]
      })
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) { { arguments: { id: project.full_path, pipeline_id: pipeline.id } } }

    it 'retrieves the base pipeline metadata', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to include(id: pipeline.id, status: 'success')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::Pipelines::GetPipelineTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    context 'when include requests more than one facet' do
      it 'returns a validation error naming the limit' do
        arguments = params[:arguments].merge(include: %w[jobs downstream_pipelines])
        result = service.execute(request: request, params: { arguments: arguments })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('include cannot contain more than 1 items')
      end
    end

    context 'when first is outside the allowed range' do
      it 'returns a validation error' do
        arguments = params[:arguments].merge(first: 101)
        result = service.execute(request: request, params: { arguments: arguments })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('first is invalid')
      end
    end

    context 'when current_user is not set' do
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
