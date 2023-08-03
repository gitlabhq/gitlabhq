# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Finder, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '.find' do
    let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
    let(:service_call) { described_class.find(project, user, environment: environment, dashboard_path: dashboard_path) }

    context 'when the dashboard exists' do
      let(:project) { project_with_dashboard(dashboard_path) }

      it_behaves_like 'valid dashboard service response'
    end

    context 'when the system dashboard is specified' do
      let(:dashboard_path) { system_dashboard_path }

      it_behaves_like 'valid dashboard service response'
    end

    context 'when no dashboard is specified' do
      let(:service_call) { described_class.find(project, user, environment: environment) }

      it_behaves_like 'valid dashboard service response'
    end
  end

  describe '.find_raw' do
    let(:dashboard) { load_dashboard_yaml(File.read(Rails.root.join('config', 'prometheus', 'common_metrics.yml'))) }
    let(:params) { {} }

    subject { described_class.find_raw(project, **params) }

    it { is_expected.to eq dashboard }

    context 'when the system dashboard is specified' do
      let(:params) { { dashboard_path: system_dashboard_path } }

      it { is_expected.to eq dashboard }
    end
  end

  describe '.find_all_paths' do
    let(:all_dashboard_paths) { described_class.find_all_paths(project) }
    let(:system_dashboard) { { path: system_dashboard_path, display_name: 'Overview', default: true, system_dashboard: true, out_of_the_box_dashboard: true } }

    it 'includes OOTB dashboards by default' do
      expect(all_dashboard_paths).to eq([system_dashboard])
    end
  end
end
