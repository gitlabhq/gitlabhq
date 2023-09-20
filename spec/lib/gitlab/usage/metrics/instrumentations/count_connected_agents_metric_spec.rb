# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountConnectedAgentsMetric, feature_category: :service_ping do
  let_it_be(:agent_token_connected) { create(:cluster_agent_token, :active, last_used_at: 2.minutes.ago) }
  let_it_be(:agent_token_disconnected) { create(:cluster_agent_token) }

  let(:expected_value) { 1 }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
