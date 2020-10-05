# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::CustomDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
  let(:service_params) { [project, user, { environment: environment, dashboard_path: dashboard_path }] }

  subject { described_class.new(*service_params) }

  before do
    project.add_maintainer(user)
  end

  describe '#raw_dashboard' do
    let(:project) { project_with_dashboard(dashboard_path) }

    it_behaves_like '#raw_dashboard raises error if dashboard loading fails'
  end

  describe '#get_dashboard' do
    let(:service_call) { subject.get_dashboard }

    context 'when the dashboard does not exist' do
      it_behaves_like 'misconfigured dashboard service response', :not_found

      it 'does not update gitlab_metrics_dashboard_processing_time_ms metric', :prometheus do
        service_call
        metric = subject.send(:processing_time_metric)
        labels = subject.send(:processing_time_metric_labels)

        expect(metric.get(labels)).to eq(0)
      end
    end

    it_behaves_like 'raises error for users with insufficient permissions'

    context 'when the dashboard exists' do
      let(:project) { project_with_dashboard(dashboard_path) }

      it_behaves_like 'valid dashboard service response'
      it_behaves_like 'updates gitlab_metrics_dashboard_processing_time_ms metric'

      it 'caches the unprocessed dashboard for subsequent calls' do
        expect_any_instance_of(described_class)
          .to receive(:get_raw_dashboard)
          .once
          .and_call_original

        described_class.new(*service_params).get_dashboard
        described_class.new(*service_params).get_dashboard
      end

      it 'tracks panel type' do
        allow(::Gitlab::Tracking).to receive(:event).and_call_original

        described_class.new(*service_params).get_dashboard

        expect(::Gitlab::Tracking).to have_received(:event)
          .with('MetricsDashboard::Chart', 'chart_rendered', { label: 'area-chart' })
          .at_least(:once)
      end

      context 'with metric in database' do
        let!(:prometheus_metric) do
          create(:prometheus_metric, project: project, identifier: 'metric_a1', group: 'custom')
        end

        it 'includes metric_id' do
          dashboard = described_class.new(*service_params).get_dashboard

          metric_id = dashboard[:dashboard][:panel_groups].find { |panel_group| panel_group[:group] == 'Group A' }
            .fetch(:panels).find { |panel| panel[:title] == 'Super Chart A1' }
            .fetch(:metrics).find { |metric| metric[:id] == 'metric_a1' }
            .fetch(:metric_id)

          expect(metric_id).to eq(prometheus_metric.id)
        end
      end

      context 'and the dashboard is then deleted' do
        it 'does not return the previously cached dashboard' do
          described_class.new(*service_params).get_dashboard

          delete_project_dashboard(project, user, dashboard_path)

          expect_any_instance_of(described_class)
          .to receive(:get_raw_dashboard)
          .once
          .and_call_original

          described_class.new(*service_params).get_dashboard
        end
      end
    end

    context 'when the dashboard is configured incorrectly' do
      let(:project) { project_with_dashboard(dashboard_path, {}) }

      it_behaves_like 'misconfigured dashboard service response', :unprocessable_entity
    end
  end

  describe '.all_dashboard_paths' do
    let(:all_dashboards) { described_class.all_dashboard_paths(project) }

    context 'when there are no project dashboards' do
      it 'returns an empty array' do
        expect(all_dashboards).to be_empty
      end
    end

    context 'when there are project dashboards available' do
      let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
      let(:project) { project_with_dashboard(dashboard_path) }

      it 'returns the dashboard attributes' do
        expect(all_dashboards).to eq(
          [{
            path: dashboard_path,
            display_name: 'test.yml',
            default: false,
            system_dashboard: false,
            out_of_the_box_dashboard: false
          }]
        )
      end

      it 'caches repo file list' do
        expect(Gitlab::Metrics::Dashboard::RepoDashboardFinder).to receive(:list_dashboards)
          .with(project)
          .once
          .and_call_original

        described_class.all_dashboard_paths(project)
        described_class.all_dashboard_paths(project)
      end
    end
  end

  describe '.valid_params?' do
    let(:params) { { dashboard_path: '.gitlab/dashboard/test.yml' } }

    subject { described_class.valid_params?(params) }

    it { is_expected.to be_truthy }

    context 'missing dashboard_path' do
      let(:params) { {} }

      it { is_expected.to be_falsey }
    end

    context 'empty dashboard_path' do
      let(:params) { { dashboard_path: '' } }

      it { is_expected.to be_falsey }
    end
  end
end
