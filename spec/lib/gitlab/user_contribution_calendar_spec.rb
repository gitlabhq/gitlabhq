require 'spec_helper'

describe Gitlab::UserContributionCalendar, lib: true do
  let(:contributor) { create(:user) }
  let(:today) { Time.now.to_date }
  let(:last_week) { today - 7.days }

  def create_contributions(day, count)
    UserContribution.create!(
      user: contributor,
      contributions: count,
      date: day
    )
  end

  describe '.calculate' do
    it 'returns a Hash mapping dates to contribution counts for the user' do
      create_contributions(last_week, 2)
      create_contributions(today, 1)

      user_contribution_calendar = Gitlab::UserContributionCalendar.new(contributor)
      expect(user_contribution_calendar.calculate).to eq(last_week => 2, today => 1)
    end
  end
end
