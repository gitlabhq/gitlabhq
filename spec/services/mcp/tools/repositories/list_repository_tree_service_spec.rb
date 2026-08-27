# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::ListRepositoryTreeService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :small_repo) }

  let(:service) { described_class.new(name: 'list_repository_tree') }

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

    it 'locks the description' do
      expect(described_class.version_metadata('0.1.0')[:description]).to eq(
        'List files and directories in a GitLab repository at a given path and ref. ' \
          'Identify the project with exactly one of url or project_id. Returns entry metadata only, ' \
          'never file contents; use get_repository_file to read a file. Each call returns up to 100 ' \
          'entries; when pageInfo.hasNextPage is true, pass pageInfo.endCursor as after to fetch the ' \
          'next page.'
      )
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        required: [],
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the project. Provide exactly one of url or project_id.'
          },
          project_id: {
            type: 'string',
            description: 'Project ID or full path. Provide exactly one of url or project_id.'
          },
          path: {
            type: 'string',
            description: 'Path of the directory to list, relative to the repository root. ' \
              'Defaults to the root.'
          },
          ref: {
            type: 'string',
            description: 'Branch name, tag name, or commit SHA. Defaults to HEAD, the default branch.'
          },
          recursive: {
            type: 'boolean',
            description: 'When true, lists entries of all subdirectories recursively. Defaults to false.'
          },
          after: {
            type: 'string',
            description: 'Cursor for forward pagination of entries. ' \
              'Use pageInfo.endCursor from a previous response.'
          }
        }
      })
    end
  end

  describe 'schema validation' do
    it 'rejects unknown arguments' do
      expect(service.input_schema[:additionalProperties]).to be(false)
    end

    it 'rejects a first argument, since the page size is fixed by the backend' do
      result = service.execute(
        request: nil, params: { arguments: { project_id: project.full_path, first: 20 } }
      )

      expect(result[:content].first[:text]).to include('Validation error')
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) { { arguments: { project_id: project.full_path } } }

    it 'returns the merged entries with pagination info', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to have_key('entries')
      expect(result[:structuredContent]).to have_key('pageInfo')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::Repositories::ListRepositoryTreeTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error response', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
