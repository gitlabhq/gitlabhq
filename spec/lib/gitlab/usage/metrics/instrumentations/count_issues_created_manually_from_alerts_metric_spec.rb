# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountIssuesCreatedManuallyFromAlertsMetric,
  feature_category: :service_ping do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:issue_with_alert) { create(:issue, :with_alert) }

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT("issues"."id") FROM "issues" ' \
      'INNER JOIN "alert_management_alerts" ON "alert_management_alerts"."issue_id" = "issues"."id" ' \
      'WHERE "issues"."author_id" != 99'
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }

  context 'on SaaS', :saas do
    let(:expected_value) { -1 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end
end
