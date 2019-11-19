# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Finder, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:project) { create(:project) }
  set(:user) { create(:user) }
  set(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '.find' do
    let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
    let(:service_call) { described_class.find(project, user, environment: environment, dashboard_path: dashboard_path) }

    it_behaves_like 'misconfigured dashboard service response', :not_found

    context 'when the dashboard exists' do
      let(:project) { project_with_dashboard(dashboard_path) }

      it_behaves_like 'valid dashboard service response'
    end

    context 'when the dashboard is configured incorrectly' do
      let(:project) { project_with_dashboard(dashboard_path, {}) }

      it_behaves_like 'misconfigured dashboard service response', :unprocessable_entity
    end

    context 'when the dashboard contains a metric without a query' do
      let(:dashboard) { { 'panel_groups' => [{ 'panels' => [{ 'metrics' => [{ 'id' => 'mock' }] }] }] } }
      let(:project) { project_with_dashboard(dashboard_path, dashboard.to_yaml) }

      it_behaves_like 'misconfigured dashboard service response', :unprocessable_entity
    end

    context 'when the system dashboard is specified' do
      let(:dashboard_path) { system_dashboard_path }

      it_behaves_like 'valid dashboard service response'
    end

    context 'when no dashboard is specified' do
      let(:service_call) { described_class.find(project, user, environment: environment) }

      it_behaves_like 'valid dashboard service response'
    end

    context 'when the dashboard is expected to be embedded' do
      let(:service_call) { described_class.find(project, user, **params) }
      let(:params) { { environment: environment, embedded: true } }

      it_behaves_like 'valid embedded dashboard service response'

      context 'when params are incomplete' do
        let(:params) { { environment: environment, embedded: true, dashboard_path: system_dashboard_path } }

        it_behaves_like 'valid embedded dashboard service response'
      end

      context 'when the panel is specified' do
        context 'as a custom metric' do
          let(:params) do
            {
              environment: environment,
              embedded: true,
              dashboard_path: system_dashboard_path,
              group: business_metric_title,
              title: 'title',
              y_label: 'y_label'
            }
          end

          it_behaves_like 'misconfigured dashboard service response', :not_found

          context 'when the metric exists' do
            before do
              create(:prometheus_metric, project: project)
            end

            it_behaves_like 'valid embedded dashboard service response'
          end
        end

        context 'as a project-defined panel' do
          let(:dashboard_path) { '.gitlab/dashboard/test.yml' }
          let(:params) do
            {
              environment: environment,
              embedded: true,
              dashboard_path: dashboard_path,
              group: 'Group A',
              title: 'Super Chart A1',
              y_label: 'y_label'
            }
          end

          it_behaves_like 'misconfigured dashboard service response', :not_found

          context 'when the metric exists' do
            let(:project) { project_with_dashboard(dashboard_path) }

            it_behaves_like 'valid embedded dashboard service response'
          end
        end
      end
    end
  end

  describe '.find_raw' do
    let(:dashboard) { YAML.load_file(Rails.root.join('config', 'prometheus', 'common_metrics.yml')) }
    let(:params) { {} }

    subject { described_class.find_raw(project, **params) }

    it { is_expected.to eq dashboard }

    context 'when the system dashboard is specified' do
      let(:params) { { dashboard_path: system_dashboard_path } }

      it { is_expected.to eq dashboard }
    end

    context 'when an existing project dashboard is specified' do
      let(:dashboard) { YAML.safe_load(fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml')) }
      let(:params) { { dashboard_path: '.gitlab/dashboards/test.yml' } }
      let(:project) { project_with_dashboard(params[:dashboard_path]) }

      it { is_expected.to eq dashboard }
    end
  end

  describe '.find_all_paths' do
    let(:all_dashboard_paths) { described_class.find_all_paths(project) }
    let(:system_dashboard) { { path: system_dashboard_path, display_name: 'Default', default: true, system_dashboard: true } }

    it 'includes only the system dashboard by default' do
      expect(all_dashboard_paths).to eq([system_dashboard])
    end

    context 'when the project contains dashboards' do
      let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
      let(:project) { project_with_dashboard(dashboard_path) }

      it 'includes system and project dashboards' do
        project_dashboard = { path: dashboard_path, display_name: 'test.yml', default: false, system_dashboard: false }

        expect(all_dashboard_paths).to contain_exactly(system_dashboard, project_dashboard)
      end
    end
  end
end
