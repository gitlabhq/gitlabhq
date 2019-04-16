require 'spec_helper'

describe MetricsDashboardProcessingService do
  let(:project) { build(:project) }
  let(:dashboard_yml) { YAML.load_file('spec/fixtures/services/metrics_dashboard_processing_service.yml') }

  describe 'process' do
    let(:dashboard) { JSON.parse(described_class.new(dashboard_yml, project).process, symbolize_names: true) }

    context 'when dashboard config corresponds to common metrics' do
      let!(:common_metric) { create(:prometheus_metric, :common, identifier: 'metric_a1') }

      it 'inserts metric ids into the config' do
        target_metric = all_metrics.find { |metric| metric[:id] == 'metric_a1' }

        expect(target_metric).to include(:metric_id)
      end
    end

    context 'when the project has associated metrics' do
      let!(:project_metric) { create(:prometheus_metric, project: project) }

      it 'includes project-specific metrics' do
        project_metric_details = {
          query_range: project_metric.query,
          unit: project_metric.unit,
          label: project_metric.legend,
          metric_id: project_metric.id
        }

        expect(all_metrics).to include project_metric_details
      end

      it 'includes project metrics at the end of the config' do
        expected_metrics_order = ['metric_b', 'metric_a2', 'metric_a1', nil]
        actual_metrics_order = all_metrics.map { |m| m[:id] }

        expect(actual_metrics_order).to eq expected_metrics_order
      end
    end

    it 'orders groups by priority and panels by weight' do
      expected_metrics_order = %w('metric_b metric_a2 metric_a1')
      actual_metrics_order = all_metrics.map { |m| m[:id] }

      expect(actual_metrics_order).to eq expected_metrics_order
    end
  end

  def all_metrics
    dashboard[:panel_groups].map do |group|
      group[:panels].map { |panel| panel[:metrics] }
    end.flatten
  end
end
