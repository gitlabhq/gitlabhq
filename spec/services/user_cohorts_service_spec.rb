require 'spec_helper'

describe UserCohortsService do
  describe '#execute' do
    def month_start(months_ago)
      months_ago.months.ago.beginning_of_month.to_date
    end

    # In the interests of speed and clarity, this example has minimal data.
    it 'returns a list of user cohorts' do
      6.times do |months_ago|
        months_ago_time = (months_ago * 2).months.ago

        create(:user, created_at: months_ago_time, current_sign_in_at: Time.now)
        create(:user, created_at: months_ago_time, current_sign_in_at: months_ago_time)
      end

      create(:user) # this user is inactive and belongs to the current month

      expected = {
        month_start(11) => { months: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], total: 0, inactive: 0 },
        month_start(10) => { months: [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], total: 2, inactive: 0 },
        month_start(9) => { months: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], total: 0, inactive: 0 },
        month_start(8) => { months: [2, 1, 1, 1, 1, 1, 1, 1, 1], total: 2, inactive: 0 },
        month_start(7) => { months: [0, 0, 0, 0, 0, 0, 0, 0], total: 0, inactive: 0 },
        month_start(6) => { months: [2, 1, 1, 1, 1, 1, 1], total: 2, inactive: 0 },
        month_start(5) => { months: [0, 0, 0, 0, 0, 0], total: 0, inactive: 0 },
        month_start(4) => { months: [2, 1, 1, 1, 1], total: 2, inactive: 0 },
        month_start(3) => { months: [0, 0, 0, 0], total: 0, inactive: 0 },
        month_start(2) => { months: [2, 1, 1], total: 2, inactive: 0 },
        month_start(1) => { months: [0, 0], total: 0, inactive: 0 },
        month_start(0) => { months: [2], total: 2, inactive: 1 }
      }

      expect(described_class.new.execute).to eq(expected)
    end
  end
end
