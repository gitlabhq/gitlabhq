# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::ClusterDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:cluster_project) { create(:cluster_project) }
  let_it_be(:cluster) { cluster_project.cluster }
  let_it_be(:project) { cluster_project.project }

  before do
    project.add_maintainer(user)
  end

  describe '.valid_params?' do
    let(:params) { { cluster: cluster, embedded: 'false' } }

    subject { described_class.valid_params?(params) }

    it { is_expected.to be_truthy }

    context 'with matching dashboard_path' do
      let(:params) { { dashboard_path: ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH } }

      it { is_expected.to be_truthy }
    end

    context 'missing cluster without dashboard_path' do
      let(:params) { {} }

      it { is_expected.to be_falsey }
    end
  end

  describe '#get_dashboard' do
    let(:service_params) { [project, user, { cluster: cluster, cluster_type: :project }] }
    let(:service_call) { subject.get_dashboard }

    subject { described_class.new(*service_params) }

    it_behaves_like 'valid dashboard service response'
    it_behaves_like 'caches the unprocessed dashboard for subsequent calls'
    it_behaves_like 'refreshes cache when dashboard_version is changed'

    it_behaves_like 'dashboard_version contains SHA256 hash of dashboard file content' do
      let(:dashboard_path) { described_class::DASHBOARD_PATH }
      let(:dashboard_version) { subject.send(:dashboard_version) }
    end

    context 'when called with a non-system dashboard' do
      let(:dashboard_path) { 'garbage/dashboard/path' }

      # We want to always return the cluster dashboard.
      it_behaves_like 'valid dashboard service response'
    end
  end
end
