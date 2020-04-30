# frozen_string_literal: true

require 'spec_helper'

describe Metrics::UsersStarredDashboard do
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
end
