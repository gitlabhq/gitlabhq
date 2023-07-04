# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountSlackAppInstallationsGbpMetric, feature_category: :integrations do
  let_it_be(:slack_integration) { create(:slack_integration) }
  let_it_be(:slack_integration_legacy) { create(:slack_integration, :legacy) }

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT("slack_integrations"."id") FROM "slack_integrations" ' \
      'WHERE "slack_integrations"."bot_user_id" IS NOT NULL'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
