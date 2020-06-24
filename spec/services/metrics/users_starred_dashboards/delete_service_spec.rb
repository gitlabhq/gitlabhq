# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::UsersStarredDashboards::DeleteService do
  subject(:service_instance) { described_class.new(user, project, dashboard_path) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    let_it_be(:user_starred_dashboard_1) { create(:metrics_users_starred_dashboard, user: user, project: project, dashboard_path: 'dashboard_1') }
    let_it_be(:user_starred_dashboard_2) { create(:metrics_users_starred_dashboard, user: user, project: project) }
    let_it_be(:other_user_starred_dashboard) { create(:metrics_users_starred_dashboard, project: project) }
    let_it_be(:other_project_starred_dashboard) { create(:metrics_users_starred_dashboard, user: user) }

    context 'without dashboard_path' do
      let(:dashboard_path) { nil }

      it 'does not scope user starred dashboards by dashboard path' do
        result = service_instance.execute

        expect(result.success?).to be_truthy
        expect(result.payload[:deleted_rows]).to be(2)
        expect(Metrics::UsersStarredDashboard.all).to contain_exactly(other_user_starred_dashboard, other_project_starred_dashboard)
      end
    end

    context 'with dashboard_path' do
      let(:dashboard_path) { 'dashboard_1' }

      it 'does scope user starred dashboards by dashboard path' do
        result = service_instance.execute

        expect(result.success?).to be_truthy
        expect(result.payload[:deleted_rows]).to be(1)
        expect(Metrics::UsersStarredDashboard.all).to contain_exactly(user_starred_dashboard_2, other_user_starred_dashboard, other_project_starred_dashboard)
      end
    end
  end
end
