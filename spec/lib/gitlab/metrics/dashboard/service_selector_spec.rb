# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::ServiceSelector do
  include MetricsDashboardHelpers

  describe '#call' do
    let(:arguments) { {} }

    subject { described_class.call(arguments) }

    it { is_expected.to be Metrics::Dashboard::SystemDashboardService }

    context 'when just the dashboard path is provided' do
      context 'when the path is for the system dashboard' do
        let(:arguments) { { dashboard_path: system_dashboard_path } }

        it { is_expected.to be Metrics::Dashboard::SystemDashboardService }
      end
    end

    context 'when the embedded flag is provided' do
      let(:arguments) { { embedded: true } }

      it { is_expected.to be Metrics::Dashboard::DefaultEmbedService }

      context 'when an incomplete set of dashboard identifiers are provided' do
        let(:arguments) { { embedded: true, dashboard_path: '.gitlab/dashboards/test.yml' } }

        it { is_expected.to be Metrics::Dashboard::DefaultEmbedService }
      end

      context 'with a system dashboard and "custom" group' do
        let(:arguments) do
          {
            embedded: true,
            dashboard_path: system_dashboard_path,
            group: business_metric_title,
            title: 'Total Requests',
            y_label: 'req/sec'
          }
        end

        it { is_expected.to be Metrics::Dashboard::CustomMetricEmbedService }
      end

      context 'when metrics embed is for an alert' do
        let(:arguments) { { embedded: true, prometheus_alert_id: 5 } }

        it { is_expected.to be Metrics::Dashboard::GitlabAlertEmbedService }
      end
    end
  end
end
