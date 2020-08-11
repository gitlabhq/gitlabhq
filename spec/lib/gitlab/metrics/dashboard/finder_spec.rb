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

    context 'when the self monitoring dashboard is specified' do
      let(:dashboard_path) { self_monitoring_dashboard_path }

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
    let(:dashboard) { load_dashboard_yaml(File.read(Rails.root.join('config', 'prometheus', 'common_metrics.yml'))) }
    let(:params) { {} }

    subject { described_class.find_raw(project, **params) }

    it { is_expected.to eq dashboard }

    context 'when the system dashboard is specified' do
      let(:params) { { dashboard_path: system_dashboard_path } }

      it { is_expected.to eq dashboard }
    end

    context 'when an existing project dashboard is specified' do
      let(:dashboard) { load_sample_dashboard }
      let(:params) { { dashboard_path: '.gitlab/dashboards/test.yml' } }
      let(:project) { project_with_dashboard(params[:dashboard_path]) }

      it { is_expected.to eq dashboard }
    end
  end

  describe '.find_all_paths' do
    let(:all_dashboard_paths) { described_class.find_all_paths(project) }
    let(:system_dashboard) { { path: system_dashboard_path, display_name: 'Overview', default: true, system_dashboard: true, out_of_the_box_dashboard: true } }
    let(:k8s_pod_health_dashboard) { { path: pod_dashboard_path, display_name: 'K8s pod health', default: false, system_dashboard: false, out_of_the_box_dashboard: true } }

    it 'includes OOTB dashboards by default' do
      expect(all_dashboard_paths).to eq([k8s_pod_health_dashboard, system_dashboard])
    end

    context 'when the project contains dashboards' do
      let(:dashboard_content) { fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml') }
      let(:project) { project_with_dashboards(dashboards) }

      let(:dashboards) do
        {
          '.gitlab/dashboards/metrics.yml' => dashboard_content,
          '.gitlab/dashboards/better_metrics.yml' => dashboard_content
        }
      end

      it 'includes OOTB and project dashboards' do
        project_dashboard1 = {
          path: '.gitlab/dashboards/metrics.yml',
          display_name: 'metrics.yml',
          default: false,
          system_dashboard: false,
          out_of_the_box_dashboard: false
        }

        project_dashboard2 = {
          path: '.gitlab/dashboards/better_metrics.yml',
          display_name: 'better_metrics.yml',
          default: false,
          system_dashboard: false,
          out_of_the_box_dashboard: false
        }

        expect(all_dashboard_paths).to eq([project_dashboard2, k8s_pod_health_dashboard, project_dashboard1, system_dashboard])
      end
    end

    context 'when the project is self monitoring' do
      let(:self_monitoring_dashboard) do
        {
          path: self_monitoring_dashboard_path,
          display_name: 'Overview',
          default: true,
          system_dashboard: true,
          out_of_the_box_dashboard: true
        }
      end

      let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
      let(:project) { project_with_dashboard(dashboard_path) }

      before do
        stub_application_setting(self_monitoring_project_id: project.id)
      end

      it 'includes self monitoring and project dashboards' do
        project_dashboard = {
          path: dashboard_path,
          display_name: 'test.yml',
          default: false,
          system_dashboard: false,
          out_of_the_box_dashboard: false
        }

        expect(all_dashboard_paths).to eq([self_monitoring_dashboard, project_dashboard])
      end
    end
  end
end
