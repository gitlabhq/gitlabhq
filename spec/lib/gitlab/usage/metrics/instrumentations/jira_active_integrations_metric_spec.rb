# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::JiraActiveIntegrationsMetric,
  feature_category: :integrations do
  let(:options) { { deployment_type: 'cloud', series: 0 } }
  let(:integration_attributes) { { active: true, deployment_type: 'cloud' } }
  let(:expected_value) { 3 }
  let(:expected_query) do
    'SELECT COUNT("integrations"."id") FROM "integrations" ' \
      'INNER JOIN "jira_tracker_data" ON "jira_tracker_data"."integration_id" = "integrations"."id" ' \
      'WHERE "integrations"."type_new" = \'Integrations::Jira\' AND "integrations"."active" = TRUE ' \
      'AND "jira_tracker_data"."deployment_type" = 2'
  end

  before do
    create_list :jira_integration, 3, integration_attributes

    create :jira_integration, integration_attributes.merge(active: false)
    create :jira_integration, integration_attributes.merge(deployment_type: 'server')
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { options: { deployment_type: 'cloud' }, time_frame: 'all' }

  it "raises an exception if option is not present" do
    expect do
      described_class.new(options: options.except(:deployment_type), time_frame: 'all')
    end.to raise_error(ArgumentError, %r{deployment_type .* must be one of})
  end

  it "raises an exception if option has invalid value" do
    expect do
      options[:deployment_type] = 'cloood'
      described_class.new(options: options, time_frame: 'all')
    end.to raise_error(ArgumentError, %r{deployment_type .* must be one of})
  end
end
