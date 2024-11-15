# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::DeletionSchedule, feature_category: :seat_cost_management do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
    it { is_expected.to belong_to(:user).required }
    it { is_expected.to belong_to(:scheduled_by).required }
  end

  describe 'validations' do
    it 'validates uniqueness of user and namespace' do
      existing = create(:members_deletion_schedules)
      deletion_schedule = build(:members_deletion_schedules, user: existing.user, namespace: existing.namespace)

      expect(deletion_schedule).to be_invalid
      expect(deletion_schedule.errors.full_messages).to eq ["User already scheduled for deletion"]
    end
  end
end
