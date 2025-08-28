# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Manager, feature_category: :ai_agents do
  let(:custom_service) { Mcp::Tools::GetServerVersionService.new(name: 'get_mcp_server_version') }

  before do
    stub_const("#{described_class}::CUSTOM_TOOLS", { 'get_mcp_server_version' => custom_service })
  end

  describe '#initialize' do
    let(:api_double) { class_double(API::API) }
    let(:routes) { [] }

    before do
      stub_const('API::API', api_double)
      allow(api_double).to receive(:routes).and_return(routes)
    end

    context 'with no API routes' do
      it 'initializes with only custom tools' do
        manager = described_class.new

        expect(manager.tools).to eq(described_class::CUSTOM_TOOLS)
        expect(manager.tools.keys).to contain_exactly('get_mcp_server_version')
      end
    end

    context 'with API routes that have MCP settings' do
      let(:app1) { instance_double(Grape::Endpoint) }
      let(:app2) { instance_double(Grape::Endpoint) }
      let(:route1) { instance_double(Grape::Router::Route, app: app1) }
      let(:route2) { instance_double(Grape::Router::Route, app: app2) }
      let(:routes) { [route1, route2] }
      let(:mcp_settings1) { { tool_name: :create_user, params: [:name, :email] } }
      let(:mcp_settings2) { { tool_name: :delete_user, params: [:id] } }
      let(:api_tool1) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool2) { instance_double(Mcp::Tools::ApiTool) }

      before do
        allow(app1).to receive(:route_setting).with(:mcp).and_return(mcp_settings1)
        allow(app2).to receive(:route_setting).with(:mcp).and_return(mcp_settings2)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(route1).and_return(api_tool1)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(route2).and_return(api_tool2)
      end

      it 'creates ApiTool instances for routes with MCP settings' do
        manager = described_class.new

        expect(manager.tools).to include(
          'create_user' => api_tool1,
          'delete_user' => api_tool2,
          'get_mcp_server_version' => custom_service
        )
        expect(manager.tools.size).to eq(3)
      end

      it 'converts tool_name symbols to strings' do
        manager = described_class.new

        expect(manager.tools.keys).to include('create_user', 'delete_user')
        expect(manager.tools.keys).not_to include(:create_user, :delete_user)
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
        allow(Mcp::Tools::ApiTool).to receive(:new).with(route1).and_return(api_tool1)
      end

      it 'skips routes with blank MCP settings' do
        manager = described_class.new

        expect(manager.tools).to include(
          'valid_tool' => api_tool1,
          'get_mcp_server_version' => custom_service
        )
        expect(manager.tools.size).to eq(2)
        expect(Mcp::Tools::ApiTool).to have_received(:new).once.with(route1)
        expect(Mcp::Tools::ApiTool).not_to have_received(:new).with(route2)
        expect(Mcp::Tools::ApiTool).not_to have_received(:new).with(route3)
      end
    end

    context 'with mixed mcp and non-mcp routes' do
      let(:app1) { instance_double(Grape::Endpoint) }
      let(:app2) { instance_double(Grape::Endpoint) }
      let(:app3) { instance_double(Grape::Endpoint) }
      let(:route1) { instance_double(Grape::Router::Route, app: app1) }
      let(:route2) { instance_double(Grape::Router::Route, app: app2) }
      let(:route3) { instance_double(Grape::Router::Route, app: app3) }
      let(:routes) { [route1, route2, route3] }
      let(:mcp_settings1) { { tool_name: :first_tool, params: [:param1] } }
      let(:mcp_settings3) { { tool_name: :third_tool, params: [:param3] } }
      let(:api_tool1) { instance_double(Mcp::Tools::ApiTool) }
      let(:api_tool3) { instance_double(Mcp::Tools::ApiTool) }

      before do
        allow(app1).to receive(:route_setting).with(:mcp).and_return(mcp_settings1)
        allow(app2).to receive(:route_setting).with(:mcp).and_return(nil)
        allow(app3).to receive(:route_setting).with(:mcp).and_return(mcp_settings3)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(route1).and_return(api_tool1)
        allow(Mcp::Tools::ApiTool).to receive(:new).with(route3).and_return(api_tool3)
      end

      it 'only processes valid routes and merges with custom tools' do
        manager = described_class.new

        expect(manager.tools).to eq(
          'first_tool' => api_tool1,
          'third_tool' => api_tool3,
          'get_mcp_server_version' => custom_service
        )
      end
    end
  end
end
