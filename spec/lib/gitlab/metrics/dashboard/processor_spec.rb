# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Processor do
  include MetricsDashboardHelpers

  let(:project) { build(:project) }
  let(:environment) { create(:environment, project: project) }
  let(:dashboard_yml) { load_sample_dashboard }

  describe 'process' do
    let(:sequence) do
      [
        Gitlab::Metrics::Dashboard::Stages::PanelIdsInserter,
        Gitlab::Metrics::Dashboard::Stages::UrlValidator
      ]
    end

    let(:process_params) { [project, dashboard_yml, sequence, { environment: environment }] }
    let(:dashboard) { described_class.new(*process_params).process }

    it 'includes an id for each dashboard panel' do
      expect(all_panels).to satisfy_all do |panel|
        panel[:id].present?
      end
    end

    context 'when the dashboard is not present' do
      let(:dashboard_yml) { nil }

      it 'returns nil' do
        expect(dashboard).to be_nil
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
