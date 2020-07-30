# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::SelfMonitoringDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:service_params) { [project, user, { environment: environment }] }

  before do
    project.add_maintainer(user)
    stub_application_setting(self_monitoring_project_id: project.id)
  end

  subject do
    described_class.new(service_params)
  end

  describe '#raw_dashboard' do
    it_behaves_like '#raw_dashboard raises error if dashboard loading fails'
  end

  describe '#get_dashboard' do
    let(:service_call) { subject.get_dashboard }

    subject { described_class.new(*service_params) }

    it_behaves_like 'valid dashboard service response'
    it_behaves_like 'raises error for users with insufficient permissions'
    it_behaves_like 'caches the unprocessed dashboard for subsequent calls'
    it_behaves_like 'refreshes cache when dashboard_version is changed'
    it_behaves_like 'updates gitlab_metrics_dashboard_processing_time_ms metric'

    it_behaves_like 'dashboard_version contains SHA256 hash of dashboard file content' do
      let(:dashboard_path) { described_class::DASHBOARD_PATH }
      let(:dashboard_version) { subject.send(:dashboard_version) }
    end
  end

  describe '.all_dashboard_paths' do
    it 'returns the dashboard attributes' do
      all_dashboards = described_class.all_dashboard_paths(project)

      expect(all_dashboards).to eq(
        [{
          path: described_class::DASHBOARD_PATH,
          display_name: described_class::DASHBOARD_NAME,
          default: true,
          system_dashboard: true,
          out_of_the_box_dashboard: true
        }]
      )
    end
  end

  describe '.valid_params?' do
    subject { described_class.valid_params?(params) }

    context 'with environment' do
      let(:params) { { environment: environment } }

      it { is_expected.to be_truthy }
    end

    context 'with dashboard_path' do
      let(:params) { { dashboard_path: self_monitoring_dashboard_path } }

      it { is_expected.to be_truthy }
    end

    context 'with a different dashboard selected' do
      let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
      let(:params) { { dashboard_path: dashboard_path, environment: environment } }

      it { is_expected.to be_falsey }
    end

    context 'missing environment and dashboard_path' do
      let(:params) { {} }

      it { is_expected.to be_falsey }
    end
  end
end
