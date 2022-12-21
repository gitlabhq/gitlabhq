# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::UserAchievement, type: :model, feature_category: :users do
  describe 'associations' do
    it { is_expected.to belong_to(:achievement).inverse_of(:user_achievements).required }
    it { is_expected.to belong_to(:user).inverse_of(:user_achievements).required }

    it { is_expected.to belong_to(:awarded_by_user).class_name('User').inverse_of(:awarded_user_achievements).optional }
    it { is_expected.to belong_to(:revoked_by_user).class_name('User').inverse_of(:revoked_user_achievements).optional }
  end
end
