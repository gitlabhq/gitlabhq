# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::ServiceSelector do
  include MetricsDashboardHelpers

  describe '#call' do
    let(:arguments) { {} }

    subject { described_class.call(arguments) }

    it { is_expected.to be Metrics::Dashboard::SystemDashboardService }

    context 'when just the dashboard path is provided' do
      let(:arguments) { { dashboard_path: '.gitlab/dashboards/test.yml' } }

      it { is_expected.to be Metrics::Dashboard::ProjectDashboardService }

      context 'when the path is for the system dashboard' do
        let(:arguments) { { dashboard_path: system_dashboard_path } }

        it { is_expected.to be Metrics::Dashboard::SystemDashboardService }
      end

      context 'when the path is for the pod dashboard' do
        let(:arguments) { { dashboard_path: pod_dashboard_path } }

        it { is_expected.to be Metrics::Dashboard::PodDashboardService }
      end
    end

    context 'when the embedded flag is provided' do
      let(:arguments) { { embedded: true } }

      it { is_expected.to be Metrics::Dashboard::DefaultEmbedService }

      context 'when an incomplete set of dashboard identifiers are provided' do
        let(:arguments) { { embedded: true, dashboard_path: '.gitlab/dashboards/test.yml' } }

        it { is_expected.to be Metrics::Dashboard::DefaultEmbedService }
      end

      context 'when all the chart identifiers are provided' do
        let(:arguments) do
          {
            embedded: true,
            dashboard_path: '.gitlab/dashboards/test.yml',
            group: 'Important Metrics',
            title: 'Total Requests',
            y_label: 'req/sec'
          }
        end

        it { is_expected.to be Metrics::Dashboard::DynamicEmbedService }
      end

      context 'when all chart params expect dashboard_path are provided' do
        let(:arguments) do
          {
            embedded: true,
            group: 'Important Metrics',
            title: 'Total Requests',
            y_label: 'req/sec'
          }
        end

        it { is_expected.to be Metrics::Dashboard::DynamicEmbedService }
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

      context 'with a grafana link' do
        let(:arguments) do
          {
            embedded: true,
            grafana_url: 'https://grafana.example.com'
          }
        end

        it { is_expected.to be Metrics::Dashboard::GrafanaMetricEmbedService }
      end
    end
  end
end
