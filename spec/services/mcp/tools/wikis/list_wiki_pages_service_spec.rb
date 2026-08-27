# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Wikis::ListWikiPagesService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, :public) }
  let_it_be(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page, container: project) }

  let_it_be(:arguments) { { project_id: project.full_path } }

  let(:service) { described_class.new(name: 'list_wiki_pages') }
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
      expect(service.description).to eq('List wiki pages in a GitLab project or group.')
    end

    it 'has readOnlyHint annotation' do
      annotations = service.annotations
      expect(annotations[:readOnlyHint]).to be(true)
    end
  end

  describe 'input schema' do
    let_it_be(:schema) { described_class.version_metadata('0.1.0')[:input_schema] }

    it 'matches the full expected contract' do
      expect(schema).to eq(
        {
          type: 'object',
          properties: {
            project_id: {
              type: 'string',
              description: 'ID or path of the project. Required if group_id is not provided.'
            },
            group_id: {
              type: 'string',
              description: 'ID or path of the group. Required if project_id is not provided.'
            },
            first: {
              type: 'integer',
              minimum: 1,
              maximum: 100,
              description: 'Number of wiki pages to return after the cursor (forward pagination). ' \
                'Default 20, max 100.'
            },
            after: {
              type: 'string',
              description: 'Cursor for forward pagination of wiki pages. ' \
                'Use pageInfo.endCursor from a previous response.'
            }
          }
        }
      )
    end
  end

  describe '#graphql_tool_class' do
    it 'returns ListWikiPagesTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::Wikis::ListWikiPagesTool)
    end
  end

  describe '#perform_v0_1_0' do
    it 'executes graphql tool with arguments' do
      expect(service).to receive(:execute_graphql_tool).with(arguments)

      service.send(:perform_v0_1_0, arguments)
    end

    it 'returns result from graphql tool', :aggregate_failures do
      result = service.send(:perform_v0_1_0, arguments)

      expect(result).to be_a(Hash)
      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to be_present
    end
  end

  describe '#perform_default' do
    it 'delegates to perform_v0_1_0' do
      expect(service).to receive(:perform_v0_1_0).with(arguments)

      service.send(:perform_default, arguments)
    end
  end

  describe '#execute' do
    let_it_be(:params) { { arguments: arguments } }

    it 'retrieves wiki pages from project', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to be_present
    end

    it 'instantiates tool with correct parameters' do
      expect(Mcp::Tools::Wikis::ListWikiPagesTool).to receive(:new).with(
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

      it 'returns error response', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
