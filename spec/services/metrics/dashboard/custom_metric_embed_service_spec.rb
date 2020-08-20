# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::CustomMetricEmbedService do
  include MetricsDashboardHelpers

  let_it_be(:project, reload: true) { build(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  let(:dashboard_path) { system_dashboard_path }
  let(:group) { business_metric_title }
  let(:title) { 'title' }
  let(:y_label) { 'y_label' }

  describe '.valid_params?' do
    let(:valid_params) do
      {
        embedded: true,
        dashboard_path: dashboard_path,
        group: group,
        title: title,
        y_label: y_label
      }
    end

    subject { described_class.valid_params?(params) }

    let(:params) { valid_params }

    it { is_expected.to be_truthy }

    context 'missing embedded' do
      let(:params) { valid_params.except(:embedded) }

      it { is_expected.to be_falsey }
    end

    context 'not embedded' do
      let(:params) { valid_params.merge(embedded: 'false') }

      it { is_expected.to be_falsey }
    end

    context 'non-system dashboard' do
      let(:dashboard_path) { '.gitlab/dashboards/test.yml' }

      it { is_expected.to be_falsey }
    end

    context 'undefined dashboard' do
      let(:params) { valid_params.except(:dashboard_path) }

      it { is_expected.to be_truthy }
    end

    context 'non-custom metric group' do
      let(:group) { 'Different Group' }

      it { is_expected.to be_falsey }
    end

    context 'missing group' do
      let(:group) { nil }

      it { is_expected.to be_falsey }
    end

    context 'missing title' do
      let(:title) { nil }

      it { is_expected.to be_falsey }
    end

    context 'undefined y-axis label' do
      let(:params) { valid_params.except(:y_label) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#get_dashboard' do
    let(:service_params) do
      [
        project,
        user,
        {
          embedded: true,
          environment: environment,
          dashboard_path: dashboard_path,
          group: group,
          title: title,
          y_label: y_label
        }
      ]
    end

    let(:service_call) { described_class.new(*service_params).get_dashboard }

    it_behaves_like 'misconfigured dashboard service response', :not_found
    it_behaves_like 'raises error for users with insufficient permissions'

    context 'the custom metric exists' do
      let!(:metric) { create(:prometheus_metric, project: project) }

      it_behaves_like 'valid embedded dashboard service response'

      it 'does not cache the unprocessed dashboard' do
        # Fail spec if any method of Cache class is called.
        stub_const('Gitlab::Metrics::Dashboard::Cache', double)

        described_class.new(*service_params).get_dashboard
      end

      context 'multiple metrics meet criteria' do
        let!(:metric_2) { create(:prometheus_metric, project: project, query: 'avg(metric_2)') }

        it_behaves_like 'valid embedded dashboard service response'

        it 'includes both metrics in a single panel' do
          result = service_call

          panel_groups = result[:dashboard][:panel_groups]
          panels = panel_groups[0][:panels]
          metrics = panels[0][:metrics]
          queries = metrics.map { |metric| metric[:query_range] }

          expect(panel_groups.length).to eq(1)
          expect(panels.length).to eq(1)
          expect(metrics.length).to eq(2)
          expect(queries).to include('avg(metric_2)', 'avg(metric)')
        end
      end
    end

    context 'when the metric exists in another project' do
      let!(:metric) { create(:prometheus_metric, project: create(:project)) }

      it_behaves_like 'misconfigured dashboard service response', :not_found
    end
  end
end
