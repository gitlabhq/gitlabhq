# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GitlabForJiraAppDirectInstallationsCountMetric do
  before do
    create(:jira_connect_subscription)
  end

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT("jira_connect_installations"."id") FROM "jira_connect_installations" '\
    'INNER JOIN "jira_connect_subscriptions" ON "jira_connect_subscriptions"."jira_connect_installation_id" '\
    '= "jira_connect_installations"."id"'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
