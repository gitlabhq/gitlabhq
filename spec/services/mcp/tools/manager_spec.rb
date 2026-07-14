# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Manager, feature_category: :ai_agents do
  let(:api_double) { class_double(API::API) }

  before do
    custom_tools = {
      'get_mcp_server_version' => Mcp::Tools::GetServerVersionService
    }
    stub_const("#{described_class}::CUSTOM_TOOLS", custom_tools)
    stub_const("::EE::#{described_class}::CUSTOM_TOOLS", {})

    # Stub the GRAPHQL_TOOLS with GraphQL tools
    graphql_tools = {
      'create_workitem_note' => Mcp::Tools::WorkItems::CreateWorkItemNoteService
    }
    stub_const("#{described_class}::GRAPHQL_TOOLS", graphql_tools)
    stub_const("::EE::#{described_class}::EE_GRAPHQL_TOOLS", {})
  end

  describe '#initialize' do
    let(:routes) { [] }

    before do
      stub_const('API::API', api_double)
      allow(api_double).to receive(:reset_routes!)
      allow(api_double).to receive(:routes).and_return(routes)
    end

    context 'with no API routes' do
      it 'initializes with custom and graphql tools' do
        manager = described_class.new

        expect(manager.tools.keys).to contain_exactly(
          'get_mcp_server_version',
          'create_workitem_note'
        )
      end
    end

    context 'with API routes that have MCP settings without aggregators' do
      let(:app1) { instance_double(Grape::Endpoint) }
      let(:app2) { instance_double(Grape::Endpoint) }
      let(:route1) { instance_double(Grape::Router::Route, app: app1) }
      let(:route2) { instance_double(Grape::Router::Route, app: app2) }
      let(:routes) { [route1, route2] }
      let(:mcp_settings1) { { tool_name: :create_user, params: [:name, :email], version: '1.0.0' } }
      let(:mcp_settings2) { { tool_name: :delete_user, params: [:id], version: '1.1.0' } }
      let(:api_tool1) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool2) { instance_double(Mcp::Tools::ApiTool) }

      before do
        allow(app1).to receive(:route_setting).with(:mcp).and_return(mcp_settings1)
        allow(app2).to receive(:route_setting).with(:mcp).and_return(mcp_settings2)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(name: 'create_user', route: route1).and_return(api_tool1)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(name: 'delete_user', route: route2).and_return(api_tool2)
      end

      it 'creates ApiTool instances for routes with MCP settings' do
        manager = described_class.new

        expect(manager.tools).to include(
          'create_user' => api_tool1,
          'delete_user' => api_tool2,
          'get_mcp_server_version' => be_a(Mcp::Tools::GetServerVersionService),
          'create_workitem_note' => be_a(Mcp::Tools::WorkItems::CreateWorkItemNoteService)
        )
        expect(manager.tools.size).to eq(4)
      end

      it 'converts tool_name symbols to strings' do
        manager = described_class.new

        expect(manager.tools.keys).to include('create_user', 'delete_user')
        expect(manager.tools.keys).not_to include(:create_user, :delete_user)
      end
    end

    context 'with API routes that have MCP settings with aggregators' do
      let(:app1) { instance_double(Grape::Endpoint) }
      let(:app2) { instance_double(Grape::Endpoint) }
      let(:app3) { instance_double(Grape::Endpoint) }
      let(:route1) { instance_double(Grape::Router::Route, app: app1) }
      let(:route2) { instance_double(Grape::Router::Route, app: app2) }
      let(:route3) { instance_double(Grape::Router::Route, app: app3) }
      let(:routes) { [route1, route2, route3] }
      let(:aggregator_class) { class_double(Mcp::Tools::Base::AggregatedService, tool_name: 'gitlab_search_test') }
      let(:aggregated_service) { instance_double(Mcp::Tools::Base::AggregatedService) }
      let(:mcp_settings1) { { tool_name: :search_issues, aggregators: [aggregator_class] } }
      let(:mcp_settings2) { { tool_name: :search_mrs, aggregators: [aggregator_class] } }
      let(:mcp_settings3) { { tool_name: :regular_tool } }
      let(:api_tool1) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool2) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool3) { instance_double(Mcp::Tools::ApiTool) }

      before do
        allow(app1).to receive(:route_setting).with(:mcp).and_return(mcp_settings1)
        allow(app2).to receive(:route_setting).with(:mcp).and_return(mcp_settings2)
        allow(app3).to receive(:route_setting).with(:mcp).and_return(mcp_settings3)
        allow(Mcp::Tools::ApiTool).to receive(:new)
          .with(name: 'search_issues', route: route1).and_return(api_tool1)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(name: 'search_mrs', route: route2).and_return(api_tool2)
        allow(Mcp::Tools::ApiTool).to receive(:new)
          .with(name: 'regular_tool', route: route3).and_return(api_tool3)
        allow(aggregator_class).to receive(:new).with(tools: [api_tool1, api_tool2]).and_return(aggregated_service)
      end

      it 'creates aggregated tools for routes with aggregators' do
        manager = described_class.new

        expect(manager.tools).to include(
          'gitlab_search_test' => aggregated_service,
          'regular_tool' => api_tool3
        )

        expected_tool_count = 2 + Mcp::Tools::Manager::CUSTOM_TOOLS.size + Mcp::Tools::Manager::GRAPHQL_TOOLS.size
        expect(manager.tools.size).to eq(expected_tool_count)
      end

      it 'groups tools by aggregator class' do
        described_class.new.tools

        expect(aggregator_class).to have_received(:new).with(tools: [api_tool1, api_tool2])
      end
    end

    context 'with mixed aggregated and non-aggregated routes' do
      let(:app1) { instance_double(Grape::Endpoint) }
      let(:app2) { instance_double(Grape::Endpoint) }
      let(:app3) { instance_double(Grape::Endpoint) }
      let(:app4) { instance_double(Grape::Endpoint) }
      let(:route1) { instance_double(Grape::Router::Route, app: app1) }
      let(:route2) { instance_double(Grape::Router::Route, app: app2) }
      let(:route3) { instance_double(Grape::Router::Route, app: app3) }
      let(:route4) { instance_double(Grape::Router::Route, app: app4) }
      let(:routes) { [route1, route2, route3, route4] }
      let(:search_aggregator) { class_double(Mcp::Tools::Base::AggregatedService, tool_name: 'search') }
      let(:user_aggregator) { class_double(Mcp::Tools::Base::AggregatedService, tool_name: 'user_management') }
      let(:search_service) { instance_double(Mcp::Tools::Base::AggregatedService) }
      let(:user_service) { instance_double(Mcp::Tools::Base::AggregatedService) }
      let(:mcp_settings1) { { tool_name: :search_issues, aggregators: [search_aggregator] } }
      let(:mcp_settings2) { { tool_name: :search_mrs, aggregators: [search_aggregator] } }
      let(:mcp_settings3) { { tool_name: :create_user, aggregators: [user_aggregator] } }
      let(:mcp_settings4) { { tool_name: :standalone_tool, params: [:id], version: '1.1.0' } }
      let(:api_tool1) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool2) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool3) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool4) { instance_double(Mcp::Tools::ApiTool) }

      before do
        allow(app1).to receive(:route_setting).with(:mcp).and_return(mcp_settings1)
        allow(app2).to receive(:route_setting).with(:mcp).and_return(mcp_settings2)
        allow(app3).to receive(:route_setting).with(:mcp).and_return(mcp_settings3)
        allow(app4).to receive(:route_setting).with(:mcp).and_return(mcp_settings4)
        allow(Mcp::Tools::ApiTool).to receive(:new)
          .with(name: 'search_issues', route: route1).and_return(api_tool1)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(name: 'search_mrs', route: route2).and_return(api_tool2)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(name: 'create_user', route: route3).and_return(api_tool3)
        allow(Mcp::Tools::ApiTool).to receive(:new)
          .with(name: 'standalone_tool', route: route4).and_return(api_tool4)
        allow(search_aggregator).to receive(:new).with(tools: [api_tool1, api_tool2]).and_return(search_service)
        allow(user_aggregator).to receive(:new).with(tools: [api_tool3]).and_return(user_service)
      end

      it 'creates both aggregated and standalone tools' do
        manager = described_class.new

        expect(manager.tools).to include(
          'search' => search_service,
          'user_management' => user_service,
          'standalone_tool' => api_tool4
        )

        expected_tool_count = 3 + Mcp::Tools::Manager::CUSTOM_TOOLS.size + Mcp::Tools::Manager::GRAPHQL_TOOLS.size
        expect(manager.tools.size).to eq(expected_tool_count)
      end
    end

    context 'with API routes that have blank MCP settings' do
      let(:app1) { instance_double(Grape::Endpoint) }
      let(:app2) { instance_double(Grape::Endpoint) }
      let(:app3) { instance_double(Grape::Endpoint) }
      let(:route1) { instance_double(Grape::Router::Route, app: app1) }
      let(:route2) { instance_double(Grape::Router::Route, app: app2) }
      let(:route3) { instance_double(Grape::Router::Route, app: app3) }
      let(:routes) { [route1, route2, route3] }
      let(:mcp_settings1) { { tool_name: :valid_tool, params: [:param] } }
      let(:api_tool1) { instance_double(Mcp::Tools::ApiTool) }

      before do
        allow(app1).to receive(:route_setting).with(:mcp).and_return(mcp_settings1)
        allow(app2).to receive(:route_setting).with(:mcp).and_return(nil)
        allow(app3).to receive(:route_setting).with(:mcp).and_return({})
        allow(Mcp::Tools::ApiTool).to receive(:new).with(name: 'valid_tool', route: route1).and_return(api_tool1)
      end

      it 'skips routes with blank MCP settings' do
        manager = described_class.new

        expect(manager.tools).to include(
          'valid_tool' => api_tool1,
          'get_mcp_server_version' => be_a(Mcp::Tools::GetServerVersionService),
          'create_workitem_note' => be_a(Mcp::Tools::WorkItems::CreateWorkItemNoteService)
        )
        expect(manager.tools.size).to eq(3)
        expect(Mcp::Tools::ApiTool).to have_received(:new).once.with(name: 'valid_tool', route: route1)
        expect(Mcp::Tools::ApiTool).not_to have_received(:new).with('route2', route2)
        expect(Mcp::Tools::ApiTool).not_to have_received(:new).with('route3', route3)
      end
    end
  end

  describe '#list_tools' do
    it 'returns the tools hash' do
      manager = described_class.new

      expect(manager.list_tools).to eq(manager.tools)
    end

    it 'does not include tool aliases' do
      manager = described_class.new

      expect(manager.list_tools.keys).to include('search')
      expect(manager.list_tools.keys).not_to include('gitlab_search')
    end
  end

  describe '#get_tool' do
    let(:manager) { described_class.new }

    context 'with custom tool' do
      context 'when requesting specific version' do
        it 'returns the correct version' do
          tool = manager.get_tool(name: 'get_mcp_server_version', version: '0.1.0')

          expect(tool).to be_a(Mcp::Tools::GetServerVersionService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting latest version' do
        it 'returns the latest version' do
          tool = manager.get_tool(name: 'get_mcp_server_version')

          expect(tool).to be_a(Mcp::Tools::GetServerVersionService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting non-existent version' do
        it 'raises VersionNotFoundError' do
          expect { manager.get_tool(name: 'get_mcp_server_version', version: '99.99.99') }
            .to raise_error(described_class::VersionNotFoundError) do |error|
              expect(error.tool_name).to eq('get_mcp_server_version')
              expect(error.requested_version).to eq('99.99.99')
              expect(error.available_versions).to eq(['0.1.0'])
            end
        end
      end
    end

    context 'with non-existent tool' do
      it 'raises ToolNotFoundError' do
        expect { manager.get_tool(name: 'non_existent_tool') }
          .to raise_error(described_class::ToolNotFoundError) do |error|
            expect(error.tool_name).to eq('non_existent_tool')
          end
      end
    end

    context 'with invalid version format' do
      it 'raises InvalidVersionFormatError' do
        expect { manager.get_tool(name: 'get_mcp_server_version', version: 'invalid-version') }
          .to raise_error(described_class::InvalidVersionFormatError) do |error|
            expect(error.version).to eq('invalid-version')
          end
      end
    end

    context 'with aggregated API tool' do
      context 'when requesting latest version' do
        it 'returns the latest version' do
          tool = manager.get_tool(name: 'search')

          expect(tool).to be_a(Mcp::Tools::Search::SearchService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting specific version' do
        it 'returns the correct version' do
          tool = manager.get_tool(name: 'search', version: '0.1.0')

          expect(tool).to be_a(Mcp::Tools::Search::SearchService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting non-existent version' do
        it 'raises VersionNotFoundError' do
          expect { manager.get_tool(name: 'search', version: '99.99.99') }
            .to raise_error(described_class::VersionNotFoundError) do |error|
            expect(error.tool_name).to eq('search')
            expect(error.requested_version).to eq('99.99.99')
            expect(error.available_versions).to eq(['0.1.0'])
          end
        end
      end
    end

    context 'with tool alias' do
      context 'when requesting by alias name' do
        it 'resolves to the canonical tool' do
          tool = manager.get_tool(name: 'gitlab_search')

          expect(tool).to be_a(Mcp::Tools::Search::SearchService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting alias with specific version' do
        it 'resolves to the canonical tool with correct version' do
          tool = manager.get_tool(name: 'gitlab_search', version: '0.1.0')

          expect(tool).to be_a(Mcp::Tools::Search::SearchService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting alias with non-existent version' do
        it 'raises VersionNotFoundError with alias name' do
          expect { manager.get_tool(name: 'gitlab_search', version: '99.99.99') }
            .to raise_error(described_class::VersionNotFoundError) do |error|
            expect(error.tool_name).to eq('search')
            expect(error.requested_version).to eq('99.99.99')
            expect(error.available_versions).to eq(['0.1.0'])
          end
        end
      end
    end

    context 'with graphql tool' do
      context 'when requesting specific version' do
        it 'returns the correct version' do
          tool = manager.get_tool(name: 'create_workitem_note', version: '0.1.0')

          expect(tool).to be_a(Mcp::Tools::WorkItems::CreateWorkItemNoteService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting latest version' do
        it 'returns the latest version' do
          tool = manager.get_tool(name: 'create_workitem_note')

          expect(tool).to be_a(Mcp::Tools::WorkItems::CreateWorkItemNoteService)
          expect(tool.version).to eq('0.1.0')
        end
      end

      context 'when requesting non-existent version' do
        it 'raises VersionNotFoundError' do
          expect { manager.get_tool(name: 'create_workitem_note', version: '99.99.99') }
            .to raise_error(described_class::VersionNotFoundError) do |error|
            expect(error.tool_name).to eq('create_workitem_note')
            expect(error.requested_version).to eq('99.99.99')
            expect(error.available_versions).to eq(['0.1.0'])
          end
        end
      end
    end

    describe 'semantic search tool' do
      let(:semantic_search_app) { instance_double(Grape::Endpoint) }
      let(:semantic_search_route) { instance_double(Grape::Router::Route, app: semantic_search_app) }
      let(:semantic_search_api_tool) { instance_double(Mcp::Tools::ApiTool) }

      before do
        allow(semantic_search_app).to receive(:route_setting).with(:mcp)
          .and_return({ tool_name: :semantic_code_search })
        allow(API::API).to receive(:routes).and_return([semantic_search_route])
        allow(Mcp::Tools::ApiTool).to receive(:new)
          .with(name: 'semantic_code_search', route: semantic_search_route)
          .and_return(semantic_search_api_tool)
        allow(semantic_search_api_tool).to receive(:version).and_return('1.0.0')
      end

      it 'resolves semantic_code_search to the discovered ApiTool' do
        tool = manager.get_tool(name: 'semantic_code_search')

        expect(tool).to eq(semantic_search_api_tool)
      end
    end
  end
end
