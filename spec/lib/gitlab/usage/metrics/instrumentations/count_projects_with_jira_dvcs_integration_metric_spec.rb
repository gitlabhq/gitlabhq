# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithJiraDvcsIntegrationMetric,
  feature_category: :integrations do
  describe 'metric value and query' do
    let_it_be_with_reload(:project_1) { create(:project) }
    let_it_be_with_reload(:project_2) { create(:project) }
    let_it_be_with_reload(:project_3) { create(:project) }

    before do
      project_1.feature_usage.log_jira_dvcs_integration_usage(cloud: false)
      project_2.feature_usage.log_jira_dvcs_integration_usage(cloud: false)
      project_3.feature_usage.log_jira_dvcs_integration_usage(cloud: true)
    end

    context 'when counting cloud integrations' do
      let(:expected_value) { 1 }
      let(:expected_query) do
        'SELECT COUNT("project_feature_usages"."project_id") FROM "project_feature_usages" ' \
          'WHERE "project_feature_usages"."jira_dvcs_cloud_last_sync_at" IS NOT NULL'
      end

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', options: { cloud: true } }
    end

    context 'when counting non-cloud integrations' do
      let(:expected_value) { 2 }
      let(:expected_query) do
        'SELECT COUNT("project_feature_usages"."project_id") FROM "project_feature_usages" ' \
          'WHERE "project_feature_usages"."jira_dvcs_server_last_sync_at" IS NOT NULL'
      end

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', options: { cloud: false } }
    end
  end

  it "raises an exception if option is not present" do
    expect do
      described_class.new(options: {}, time_frame: 'all')
    end.to raise_error(ArgumentError, %r{must be a boolean})
  end

  it "raises an exception if option has invalid value" do
    expect do
      described_class.new(options: { cloud: 'yes' }, time_frame: 'all')
    end.to raise_error(ArgumentError, %r{must be a boolean})
  end
end
