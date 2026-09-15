# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MCP tool toolset declarations', feature_category: :ai_agents do
  describe 'toolset constants' do
    it 'has no overlap between ALWAYS_ON, DEFAULT, and OPT_IN', :aggregate_failures do
      always_on = Mcp::Tools::Toolsets::ALWAYS_ON
      default_ts = Mcp::Tools::Toolsets::DEFAULT
      opt_in = Mcp::Tools::Toolsets::OPT_IN

      expect(always_on & default_ts).to be_empty
      expect(always_on & opt_in).to be_empty
      expect(default_ts & opt_in).to be_empty
    end
  end

  describe 'every registered tool is reachable through a declared toolset' do
    let(:manager) { Mcp::Tools::Manager.new }

    it 'has no tools outside declared toolsets' do
      orphans = manager.tools.keys - manager.tools_in_toolsets(Mcp::Tools::Toolsets::ALL)

      expect(orphans).to be_empty,
        "Tools not reachable via any declared toolset: #{orphans}. Add `toolset:` to register_version " \
          "metadata (service classes) or route_setting :mcp (API routes)."
    end
  end
end
