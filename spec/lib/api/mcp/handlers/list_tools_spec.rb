# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Mcp::Handlers::ListTools, feature_category: :mcp_server do
  let(:manager) { instance_double(Mcp::Tools::Manager, list_tools: {}) }
  let(:logger) { instance_double(Gitlab::Mcp::Logger) }
  let_it_be(:current_user) { create(:user) }

  subject(:handler) { described_class.new(manager) }

  before do
    allow(Gitlab::Mcp::Logger).to receive(:build).and_return(logger)
    allow(logger).to receive(:conditional_info)
  end

  describe '#invoke' do
    it 'tracks the list tools event' do
      expect { handler.invoke(current_user) }
        .to trigger_internal_events('list_mcp_tools')
        .with(user: current_user)
        .and increment_usage_metrics(
          'counts.count_total_list_mcp_tools_weekly',
          'counts.count_total_list_mcp_tools_monthly',
          'counts.count_total_list_mcp_tools'
        )
    end

    it 'logs the tools list request' do
      handler.invoke(current_user)

      expect(logger).to have_received(:conditional_info).with(
        current_user,
        message: 'MCP tools list',
        event_name: 'tools_list',
        ai_component: 'mcp_server',
        tool_count: 0
      )
    end
  end
end
