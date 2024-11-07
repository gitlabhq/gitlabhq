# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::DeletionSchedule, feature_category: :seat_cost_management do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
    it { is_expected.to belong_to(:user).required }
    it { is_expected.to belong_to(:scheduled_by).required }
  end
end
