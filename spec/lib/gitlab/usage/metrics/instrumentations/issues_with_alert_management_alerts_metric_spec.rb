# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::IssuesWithAlertManagementAlertsMetric, feature_category: :incident_management do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:alert_issue) { create(:alert_management_alert, :with_incident) }

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT("issues"."id") FROM "issues" ' \
      'INNER JOIN "alert_management_alerts" ' \
      'ON "alert_management_alerts"."issue_id" = "issues"."id"'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
