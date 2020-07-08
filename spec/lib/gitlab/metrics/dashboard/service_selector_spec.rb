# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::ServiceSelector do
  include MetricsDashboardHelpers

  describe '#call' do
    let(:arguments) { {} }

    subject { described_class.call(arguments) }

    it { is_expected.to be Metrics::Dashboard::SystemDashboardService }

    context 'when just the dashboard path is provided' do
      let(:arguments) { { dashboard_path: '.gitlab/dashboards/test.yml' } }

      it { is_expected.to be Metrics::Dashboard::CustomDashboardService }

      context 'when the path is for the system dashboard' do
        let(:arguments) { { dashboard_path: system_dashboard_path } }

        it { is_expected.to be Metrics::Dashboard::SystemDashboardService }
      end

      context 'when the path is for the pod dashboard' do
        let(:arguments) { { dashboard_path: pod_dashboard_path } }

        it { is_expected.to be Metrics::Dashboard::PodDashboardService }
      end
    end

    context 'when the path is for the self monitoring dashboard' do
      let(:arguments) { { dashboard_path: self_monitoring_dashboard_path } }

      it { is_expected.to be Metrics::Dashboard::SelfMonitoringDashboardService }
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

      context 'with the embed defined in the arguments' do
        let(:arguments) do
          {
            embedded: true,
            embed_json: '{}'
          }
        end

        it { is_expected.to be Metrics::Dashboard::TransientEmbedService }
      end

      context 'when cluster is provided' do
        let(:arguments) { { cluster: "some cluster" } }

        it { is_expected.to be Metrics::Dashboard::ClusterDashboardService }
      end

      context 'when cluster is provided and embedded is not true' do
        let(:arguments) { { cluster: "some cluster", embedded: 'false' } }

        it { is_expected.to be Metrics::Dashboard::ClusterDashboardService }
      end

      context 'when cluster dashboard_path is provided' do
        let(:arguments) { { dashboard_path: ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH } }

        it { is_expected.to be Metrics::Dashboard::ClusterDashboardService }
      end

      context 'when cluster is provided and embed params' do
        let(:arguments) do
          {
            cluster: "some cluster",
            embedded: 'true',
            cluster_type: 'project',
            format: :json,
            group: 'Food metrics',
            title: 'Pizza Consumption',
            y_label: 'Slice Count'
          }
        end

        it { is_expected.to be Metrics::Dashboard::ClusterMetricsEmbedService }
      end

      context 'when metrics embed is for an alert' do
        let(:arguments) { { embedded: true, prometheus_alert_id: 5 } }

        it { is_expected.to be Metrics::Dashboard::GitlabAlertEmbedService }
      end
    end
  end
end
