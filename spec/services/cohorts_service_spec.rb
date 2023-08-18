# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CohortsService, feature_category: :shared do
  describe '#execute' do
    def month_start(months_ago)
      months_ago.months.ago.beginning_of_month.to_date
    end

    # In the interests of speed and clarity, this example has minimal data.
    it 'returns a list of user cohorts' do
      6.times do |months_ago|
        months_ago_time = (months_ago * 2).months.ago

        create(:user, created_at: months_ago_time, last_activity_on: Time.current)
        create(:user, created_at: months_ago_time, last_activity_on: months_ago_time)
      end

      create(:user) # this user is inactive and belongs to the current month

      expected_cohorts = [
        {
          registration_month: month_start(11),
          activity_months: Array.new(11) { { total: 0, percentage: 0 } },
          total: 0,
          inactive: 0
        },
        {
          registration_month: month_start(10),
          activity_months: Array.new(10) { { total: 1, percentage: 50 } },
          total: 2,
          inactive: 0
        },
        {
          registration_month: month_start(9),
          activity_months: Array.new(9) { { total: 0, percentage: 0 } },
          total: 0,
          inactive: 0
        },
        {
          registration_month: month_start(8),
          activity_months: Array.new(8) { { total: 1, percentage: 50 } },
          total: 2,
          inactive: 0
        },
        {
          registration_month: month_start(7),
          activity_months: Array.new(7) { { total: 0, percentage: 0 } },
          total: 0,
          inactive: 0
        },
        {
          registration_month: month_start(6),
          activity_months: Array.new(6) { { total: 1, percentage: 50 } },
          total: 2,
          inactive: 0
        },
        {
          registration_month: month_start(5),
          activity_months: Array.new(5) { { total: 0, percentage: 0 } },
          total: 0,
          inactive: 0
        },
        {
          registration_month: month_start(4),
          activity_months: Array.new(4) { { total: 1, percentage: 50 } },
          total: 2,
          inactive: 0
        },
        {
          registration_month: month_start(3),
          activity_months: Array.new(3) { { total: 0, percentage: 0 } },
          total: 0,
          inactive: 0
        },
        {
          registration_month: month_start(2),
          activity_months: Array.new(2) { { total: 1, percentage: 50 } },
          total: 2,
          inactive: 0
        },
        {
          registration_month: month_start(1),
          activity_months: Array.new(1) { { total: 0, percentage: 0 } },
          total: 0,
          inactive: 0
        },
        {
          registration_month: month_start(0),
          activity_months: [],
          total: 2,
          inactive: 1
        }
      ]

      expect(described_class.new.execute).to eq(months_included: 12, cohorts: expected_cohorts)
    end
  end
end
