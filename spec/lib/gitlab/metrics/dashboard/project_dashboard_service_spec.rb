# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::Metrics::Dashboard::ProjectDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:user) { build(:user) }
  set(:project) { build(:project) }
  set(:environment) { build(:environment, project: project) }

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
end
