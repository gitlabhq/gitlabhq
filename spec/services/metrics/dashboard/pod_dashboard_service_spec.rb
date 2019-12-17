# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::PodDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe 'get_dashboard' do
    let(:dashboard_path) { described_class::DASHBOARD_PATH }
    let(:service_params) { [project, user, { environment: environment, dashboard_path: dashboard_path }] }
    let(:service_call) { described_class.new(*service_params).get_dashboard }

    it_behaves_like 'valid dashboard service response'
    it_behaves_like 'caches the unprocessed dashboard for subsequent calls'
  end
end
