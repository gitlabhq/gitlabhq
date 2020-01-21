# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::CustomMetricEmbedService do
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

    context 'not embedded' do
      let(:params) { valid_params.except(:embedded) }

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
        expect(Gitlab::Metrics::Dashboard::Cache).not_to receive(:fetch)

        described_class.new(*service_params).get_dashboard
      end

      context 'multiple metrics meet criteria' do
        let!(:metric_2) { create(:prometheus_metric, project: project, query: 'avg(metric_2)') }

        it_behaves_like 'valid embedded dashboard service response'

        it 'includes both metrics' do
          result = service_call
          included_queries = all_queries(result[:dashboard])

          expect(included_queries).to include('avg(metric_2)', 'avg(metric)')
        end
      end
    end

    context 'when the metric exists in another project' do
      let!(:metric) { create(:prometheus_metric, project: create(:project)) }

      it_behaves_like 'misconfigured dashboard service response', :not_found
    end
  end

  private

  def all_queries(dashboard)
    dashboard[:panel_groups].flat_map do |group|
      group[:panels].flat_map do |panel|
        panel[:metrics].map do |metric|
          metric[:query_range]
        end
      end
    end
  end
end
