# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Labels::SearchService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:label) { create(:label, project: project, title: 'bug') }

  let(:service) { described_class.new(name: 'search_labels') }
  let(:request) { instance_double(ActionDispatch::Request) }

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

    it 'has correct description' do
      expect(service.description).to eq('Search labels in a GitLab project or group')
    end

    it 'is annotated read-only with no destructiveHint' do
      expect(service.annotations).to eq({ readOnlyHint: true })
    end
  end

  describe 'input schema' do
    it 'matches the expected contract' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq(
        {
          type: 'object',
          properties: {
            full_path: {
              type: 'string',
              description: 'Full path of the project or group. Required.'
            },
            is_project: {
              type: 'boolean',
              description: 'Whether to search in a project (true) or group (false). Required.'
            },
            search: {
              type: 'string',
              description: 'Search term to filter labels by title.'
            }
          },
          required: %w[full_path is_project]
        }
      )
    end
  end

  describe '#graphql_tool_class' do
    it 'returns SearchTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::Labels::SearchTool)
    end
  end

  describe '#perform_0_1_0' do
    let(:arguments) do
      {
        full_path: project.full_path,
        is_project: true
      }
    end

    it 'executes graphql tool with arguments' do
      expect(service).to receive(:execute_graphql_tool).with(arguments)

      service.send(:perform_0_1_0, arguments)
    end

    it 'returns result from graphql tool' do
      result = service.send(:perform_0_1_0, arguments)

      expect(result).to be_a(Hash)
      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to be_present
    end
  end

  describe '#perform_default' do
    let(:arguments) do
      {
        full_path: project.full_path,
        is_project: true
      }
    end

    it 'delegates to perform_0_1_0' do
      expect(service).to receive(:perform_0_1_0).with(arguments)

      service.send(:perform_default, arguments)
    end
  end

  describe '#execute' do
    let(:params) do
      {
        arguments: {
          full_path: project.full_path,
          is_project: true
        }
      }
    end

    it 'retrieves labels from project' do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to be_present
    end

    it 'instantiates tool with correct parameters' do
      expect(Mcp::Tools::Labels::SearchTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    context 'with search parameter' do
      let(:params) do
        {
          arguments: {
            full_path: project.full_path,
            is_project: true,
            search: 'bug'
          }
        }
      end

      it 'passes search parameter to tool' do
        expect(Mcp::Tools::Labels::SearchTool).to receive(:new).with(
          current_user: user,
          params: hash_including(
            search: 'bug'
          ),
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
