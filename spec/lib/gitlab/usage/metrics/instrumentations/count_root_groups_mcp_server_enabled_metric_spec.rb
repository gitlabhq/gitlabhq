# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountRootGroupsMcpServerEnabledMetric,
  feature_category: :service_ping do
  it 'raises an error with invalid mcp_server_enabled option' do
    expect do
      described_class.new(options: { mcp_server_enabled: 'invalid' }, time_frame: 'all')
    end.to raise_error(ArgumentError, /Unknown parameters: mcp_server_enabled:invalid/)
  end

  context 'when mcp_server_enabled is true' do
    context 'when no root groups have MCP server enabled' do
      it_behaves_like 'a correct instrumented metric value',
        options: { mcp_server_enabled: true }, time_frame: 'all' do
        let(:expected_value) { 0 }
      end
    end

    context 'when root groups have MCP server enabled' do
      let_it_be(:group) { create(:group, :with_mcp_server_enabled) }

      it_behaves_like 'a correct instrumented metric value',
        options: { mcp_server_enabled: true }, time_frame: 'all' do
        let(:expected_value) { 1 }
      end
    end

    context 'when only subgroups have MCP server enabled' do
      let_it_be(:root_group) { create(:group, :with_mcp_server_disabled) }
      let_it_be(:subgroup) { create(:group, :with_mcp_server_enabled, parent: root_group) }

      it_behaves_like 'a correct instrumented metric value',
        options: { mcp_server_enabled: true }, time_frame: 'all' do
        let(:expected_value) { 0 }
      end
    end
  end

  context 'when mcp_server_enabled is false' do
    context 'when no root groups have MCP server disabled' do
      it_behaves_like 'a correct instrumented metric value',
        options: { mcp_server_enabled: false }, time_frame: 'all' do
        let(:expected_value) { 0 }
      end
    end

    context 'when root groups have MCP server disabled' do
      let_it_be(:group) { create(:group, :with_mcp_server_disabled) }

      it_behaves_like 'a correct instrumented metric value',
        options: { mcp_server_enabled: false }, time_frame: 'all' do
        let(:expected_value) { 1 }
      end
    end

    context 'when a root group has mcp_server_enabled not set (NULL)' do
      let_it_be(:group) { create(:group) }

      it_behaves_like 'a correct instrumented metric value',
        options: { mcp_server_enabled: false }, time_frame: 'all' do
        let(:expected_value) { 0 }
      end
    end
  end

  context 'when both enabled and disabled root groups exist' do
    let_it_be(:enabled_groups) { create_list(:group, 2, :with_mcp_server_enabled) }
    let_it_be(:disabled_groups) { create_list(:group, 3, :with_mcp_server_disabled) }

    it_behaves_like 'a correct instrumented metric value',
      options: { mcp_server_enabled: true }, time_frame: 'all' do
      let(:expected_value) { 2 }
    end

    it_behaves_like 'a correct instrumented metric value',
      options: { mcp_server_enabled: false }, time_frame: 'all' do
      let(:expected_value) { 3 }
    end
  end
end
