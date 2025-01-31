# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Types::UserPreference, type: :model, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:work_item_type).class_name('WorkItems::Type').inverse_of(:user_preferences) }
  end
end
