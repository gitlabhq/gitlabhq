require 'spec_helper'

describe Gitlab::UserActivities::ActivitySet, :redis, lib: true do
  let(:user) { create(:user) }

  it 'shows the last user activity' do
    Timecop.freeze do
      user.record_activity

      expect(described_class.new.activities.first).to be_an_instance_of(Gitlab::UserActivities::Activity)
    end
  end

  context 'paginated activities' do
    before do
      Timecop.scale(3600)

      7.times do
        create(:user).record_activity
      end
    end

    after do
      Timecop.return
    end

    it 'shows the 5 oldest user activities paginated' do
      expect(described_class.new(per_page: 5).activities.count).to eq(5)
    end

    it 'shows the 2 reamining user activities paginated' do
      expect(described_class.new(per_page: 5, page: 2).activities.count).to eq(2)
    end

    it 'shows the oldest first' do
      activities = described_class.new.activities

      expect(activities.first.last_activity_at).to be < activities.last.last_activity_at
    end
  end

  context 'filter by date' do
    before do
      create(:user).record_activity
    end

    it 'shows activities from yesterday' do
      today = Date.today.to_s("%Y-%m-%d")

      expect(described_class.new(from: today).activities.count).to eq(1)
    end

    it 'filter activities from today' do
      tomorrow = Date.tomorrow.to_s("%Y-%m-%d")

      expect(described_class.new(from: tomorrow).activities.count).to eq(0)
    end
  end
end
