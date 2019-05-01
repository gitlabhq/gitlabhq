# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::SystemDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:project) { build(:project) }
  set(:environment) { build(:environment, project: project) }

  describe 'get_dashboard' do
    let(:dashboard_path) { described_class::SYSTEM_DASHBOARD_PATH }
    let(:service_params) { [project, nil, { environment: environment, dashboard_path: dashboard_path }] }
    let(:service_call) { described_class.new(*service_params).get_dashboard }

    it_behaves_like 'valid dashboard service response'

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
end
