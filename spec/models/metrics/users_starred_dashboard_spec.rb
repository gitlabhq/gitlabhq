# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::UsersStarredDashboard do
  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:metrics_users_starred_dashboards) }
    it { is_expected.to belong_to(:user).inverse_of(:metrics_users_starred_dashboards) }
  end

  describe 'validation' do
    subject { build(:metrics_users_starred_dashboard) }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:dashboard_path) }
    it { is_expected.to validate_length_of(:dashboard_path).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:dashboard_path).scoped_to(%i[user_id project_id]) }
  end

  context 'scopes' do
    let_it_be(:project) { create(:project) }
    let_it_be(:starred_dashboard_a) { create(:metrics_users_starred_dashboard, project: project, dashboard_path: 'path_a') }
    let_it_be(:starred_dashboard_b) { create(:metrics_users_starred_dashboard, project: project, dashboard_path: 'path_b') }
    let_it_be(:starred_dashboard_c) { create(:metrics_users_starred_dashboard, dashboard_path: 'path_b') }

    describe '#for_project' do
      it 'selects only starred dashboards belonging to project' do
        expect(described_class.for_project(project)).to contain_exactly starred_dashboard_a, starred_dashboard_b
      end
    end

    describe '#for_project_dashboard' do
      it 'selects only starred dashboards belonging to project with given dashboard path' do
        expect(described_class.for_project_dashboard(project, 'path_b')).to contain_exactly starred_dashboard_b
      end
    end
  end
end
