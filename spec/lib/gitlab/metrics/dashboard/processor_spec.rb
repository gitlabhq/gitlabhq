# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Processor do
  let(:project) { build(:project) }
  let(:environment) { create(:environment, project: project) }
  let(:dashboard_yml) { YAML.load_file('spec/fixtures/lib/gitlab/metrics/dashboard/sample_dashboard.yml') }

  describe 'process' do
    let(:sequence) do
      [
        Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
        Gitlab::Metrics::Dashboard::Stages::CustomMetricsInserter,
        Gitlab::Metrics::Dashboard::Stages::CustomMetricsDetailsInserter,
        Gitlab::Metrics::Dashboard::Stages::EndpointInserter,
        Gitlab::Metrics::Dashboard::Stages::Sorter,
        Gitlab::Metrics::Dashboard::Stages::AlertsInserter,
        Gitlab::Metrics::Dashboard::Stages::PanelIdsInserter
      ]
    end

    let(:process_params) { [project, dashboard_yml, sequence, { environment: environment }] }
    let(:dashboard) { described_class.new(*process_params).process }

    it 'includes a path for the prometheus endpoint with each metric' do
      expect(all_metrics).to satisfy_all do |metric|
        metric[:prometheus_endpoint_path] == prometheus_path(metric[:query_range])
      end
    end

    it 'includes an id for each dashboard panel' do
      expect(all_panels).to satisfy_all do |panel|
        panel[:id].present?
      end
    end

    it 'includes boolean to indicate if panel group has custom metrics' do
      expect(dashboard[:panel_groups]).to all(include( { has_custom_metrics: boolean } ))
    end

    context 'when the dashboard is not present' do
      let(:dashboard_yml) { nil }

      it 'returns nil' do
        expect(dashboard).to be_nil
      end
    end

    context 'when dashboard config corresponds to common metrics' do
      let!(:common_metric) { create(:prometheus_metric, :common, identifier: 'metric_a1') }

      it 'inserts metric ids into the config' do
        target_metric = all_metrics.find { |metric| metric[:id] == 'metric_a1' }

        expect(target_metric).to include(:metric_id)
        expect(target_metric[:metric_id]).to eq(common_metric.id)
      end
    end

    context 'when the project has associated metrics' do
      let!(:project_response_metric) { create(:prometheus_metric, project: project, group: :response) }
      let!(:project_system_metric) { create(:prometheus_metric, project: project, group: :system) }
      let!(:project_business_metric) { create(:prometheus_metric, project: project, group: :business) }

      it 'includes project-specific metrics' do
        expect(all_metrics).to include get_metric_details(project_system_metric)
        expect(all_metrics).to include get_metric_details(project_response_metric)
        expect(all_metrics).to include get_metric_details(project_business_metric)
      end

      it 'orders groups by priority and panels by weight' do
        expected_metrics_order = [
          'metric_b', # group priority 10, panel weight 1
          'metric_a2', # group priority 1, panel weight 2
          'metric_a1', # group priority 1, panel weight 1
          project_business_metric.id, # group priority 0, panel weight nil (0)
          project_response_metric.id, # group priority -5, panel weight nil (0)
          project_system_metric.id # group priority -10, panel weight nil (0)
        ]
        actual_metrics_order = all_metrics.map { |m| m[:id] || m[:metric_id] }

        expect(actual_metrics_order).to eq expected_metrics_order
      end

      context 'when the project has multiple metrics in the same group' do
        let!(:project_response_metric) { create(:prometheus_metric, project: project, group: :response) }
        let!(:project_response_metric_2) { create(:prometheus_metric, project: project, group: :response) }

        it 'includes multiple metrics' do
          expect(all_metrics).to include get_metric_details(project_response_metric)
          expect(all_metrics).to include get_metric_details(project_response_metric_2)
        end
      end

      context 'when the dashboard should not include project metrics' do
        let(:sequence) do
          [
            Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
            Gitlab::Metrics::Dashboard::Stages::EndpointInserter,
            Gitlab::Metrics::Dashboard::Stages::Sorter
          ]
        end
        let(:dashboard) { described_class.new(*process_params).process }

        it 'includes only dashboard metrics' do
          metrics = all_metrics.map { |m| m[:id] }

          expect(metrics.length).to be(3)
          expect(metrics).to eq %w(metric_b metric_a2 metric_a1)
        end
      end

      context 'when sample_metrics are requested' do
        let(:process_params) { [project, dashboard_yml, sequence, { environment: environment, sample_metrics: true }] }

        it 'includes a sample metrics path for the prometheus endpoint with each metric' do
          expect(all_metrics).to satisfy_all do |metric|
            metric[:prometheus_endpoint_path] == sample_metrics_path(metric[:id])
          end
        end
      end
    end

    context 'when the dashboard references persisted metrics with alerts' do
      let!(:alert) do
        create(
          :prometheus_alert,
          environment: environment,
          project: project,
          prometheus_metric: persisted_metric
        )
      end

      shared_examples_for 'has saved alerts' do
        it 'includes an alert path' do
          target_metric = all_metrics.find { |metric| metric[:metric_id] == persisted_metric.id }

          expect(target_metric).to be_a Hash
          expect(target_metric).to include(:alert_path)
          expect(target_metric[:alert_path]).to include(
            project.path,
            persisted_metric.id.to_s,
            environment.id.to_s
          )
        end
      end

      context 'that are shared across projects' do
        let!(:persisted_metric) { create(:prometheus_metric, :common, identifier: 'metric_a1') }

        it_behaves_like 'has saved alerts'
      end

      context 'when the project has associated metrics' do
        let!(:persisted_metric) { create(:prometheus_metric, project: project, group: :business) }

        it_behaves_like 'has saved alerts'
      end
    end

    context 'when there are no alerts' do
      let!(:persisted_metric) { create(:prometheus_metric, :common, identifier: 'metric_a1') }

      it 'does not insert an alert_path' do
        target_metric = all_metrics.find { |metric| metric[:metric_id] == persisted_metric.id }

        expect(target_metric).to be_a Hash
        expect(target_metric).not_to include(:alert_path)
      end
    end

    shared_examples_for 'errors with message' do |expected_message|
      it 'raises a DashboardLayoutError' do
        error_class = Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError

        expect { dashboard }.to raise_error(error_class, expected_message)
      end
    end

    context 'when the dashboard is missing panel_groups' do
      let(:dashboard_yml) { {} }

      it_behaves_like 'errors with message', 'Top-level key :panel_groups must be an array'
    end

    context 'when the dashboard contains a panel_group which is missing panels' do
      let(:dashboard_yml) { { panel_groups: [{}] } }

      it_behaves_like 'errors with message', 'Each "panel_group" must define an array :panels'
    end

    context 'when the dashboard contains a panel which is missing metrics' do
      let(:dashboard_yml) { { panel_groups: [{ panels: [{}] }] } }

      it_behaves_like 'errors with message', 'Each "panel" must define an array :metrics'
    end

    context 'when the dashboard contains a metric which is missing a query' do
      let(:dashboard_yml) { { panel_groups: [{ panels: [{ metrics: [{}] }] }] } }

      it_behaves_like 'errors with message', 'Each "metric" must define one of :query or :query_range'
    end
  end

  private

  def all_metrics
    all_panels.flat_map { |panel| panel[:metrics] }
  end

  def all_panels
    dashboard[:panel_groups].flat_map { |group| group[:panels] }
  end

  def get_metric_details(metric)
    {
      query_range: metric.query,
      unit: metric.unit,
      label: metric.legend,
      metric_id: metric.id,
      prometheus_endpoint_path: prometheus_path(metric.query),
      edit_path: edit_metric_path(metric)
    }
  end

  def prometheus_path(query)
    Gitlab::Routing.url_helpers.prometheus_api_project_environment_path(
      project,
      environment,
      proxy_path: :query_range,
      query: query
    )
  end

  def sample_metrics_path(metric)
    Gitlab::Routing.url_helpers.sample_metrics_project_environment_path(
      project,
      environment,
      identifier: metric
    )
  end

  def edit_metric_path(metric)
    Gitlab::Routing.url_helpers.edit_project_prometheus_metric_path(
      project,
      metric.id
    )
  end
end
