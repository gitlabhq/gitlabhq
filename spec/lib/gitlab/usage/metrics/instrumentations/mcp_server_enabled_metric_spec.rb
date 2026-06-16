# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::McpServerEnabledMetric,
  feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  where(:mcp_server_enabled, :expected_value) do
    false | false
    true  | true
  end

  with_them do
    before do
      stub_application_setting(mcp_server_enabled: mcp_server_enabled)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end
end
