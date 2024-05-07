# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GitlabForJiraAppProxyInstallationsCountMetric do
  let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'http://self-managed-gitlab.com') }

  before do
    create(:jira_connect_subscription, installation: installation)
  end

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT("jira_connect_installations"."id") FROM "jira_connect_installations" '\
    'WHERE "jira_connect_installations"."instance_url" IS NOT NULL'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
