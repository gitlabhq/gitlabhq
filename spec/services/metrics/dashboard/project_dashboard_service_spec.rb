# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::ProjectDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe 'get_dashboard' do
    let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
    let(:service_params) { [project, user, { environment: environment, dashboard_path: dashboard_path }] }
    let(:service_call) { described_class.new(*service_params).get_dashboard }

    context 'when the dashboard does not exist' do
      it_behaves_like 'misconfigured dashboard service response', :not_found
    end

    it_behaves_like 'raises error for users with insufficient permissions'

    context 'when the dashboard exists' do
      let(:project) { project_with_dashboard(dashboard_path) }

      it_behaves_like 'valid dashboard service response'

      it 'caches the unprocessed dashboard for subsequent calls' do
        expect_any_instance_of(described_class)
          .to receive(:get_raw_dashboard)
          .once
          .and_call_original

        described_class.new(*service_params).get_dashboard
        described_class.new(*service_params).get_dashboard
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

  describe '::all_dashboard_paths' do
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
            system_dashboard: false
          }]
        )
      end
    end
  end
end
