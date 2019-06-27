# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::SystemDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe 'get_dashboard' do
    let(:dashboard_path) { described_class::SYSTEM_DASHBOARD_PATH }
    let(:service_params) { [project, user, { environment: environment, dashboard_path: dashboard_path }] }
    let(:service_call) { described_class.new(*service_params).get_dashboard }

    it_behaves_like 'valid dashboard service response'
    it_behaves_like 'raises error for users with insufficient permissions'

    it 'caches the unprocessed dashboard for subsequent calls' do
      expect(YAML).to receive(:safe_load).once.and_call_original

      described_class.new(*service_params).get_dashboard
      described_class.new(*service_params).get_dashboard
    end

    context 'when called with a non-system dashboard' do
      let(:dashboard_path) { 'garbage/dashboard/path' }

      # We want to alwaus return the system dashboard.
      it_behaves_like 'valid dashboard service response'
    end
  end

  describe '::all_dashboard_paths' do
    it 'returns the dashboard attributes' do
      all_dashboards = described_class.all_dashboard_paths(project)

      expect(all_dashboards).to eq(
        [{
          path: described_class::SYSTEM_DASHBOARD_PATH,
          display_name: described_class::SYSTEM_DASHBOARD_NAME,
          default: true
        }]
      )
    end
  end
end
