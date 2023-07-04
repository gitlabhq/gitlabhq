# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountSlackAppInstallationsMetric, feature_category: :integrations do
  let_it_be(:slack_integration) { create(:slack_integration) }
  let_it_be(:slack_integration_legacy) { create(:slack_integration, :legacy) }

  let(:expected_value) { 2 }
  let(:expected_query) { 'SELECT COUNT("slack_integrations"."id") FROM "slack_integrations"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
