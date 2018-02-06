require 'spec_helper'

describe UpdateUserActivityWorker, :clean_gitlab_redis_shared_state do
  let(:user_active_2_days_ago) { create(:user, current_sign_in_at: 10.months.ago) }
  let(:user_active_yesterday_1) { create(:user) }
  let(:user_active_yesterday_2) { create(:user) }
  let(:user_active_today) { create(:user) }
  let(:data) do
    {
      user_active_2_days_ago.id.to_s => 2.days.ago.at_midday.to_i.to_s,
      user_active_yesterday_1.id.to_s => 1.day.ago.at_midday.to_i.to_s,
      user_active_yesterday_2.id.to_s => 1.day.ago.at_midday.to_i.to_s,
      user_active_today.id.to_s => Time.now.to_i.to_s
    }
  end

  it 'updates users.last_activity_on' do
    subject.perform(data)

    aggregate_failures do
      expect(user_active_2_days_ago.reload.last_activity_on).to eq(2.days.ago.to_date)
      expect(user_active_yesterday_1.reload.last_activity_on).to eq(1.day.ago.to_date)
      expect(user_active_yesterday_2.reload.last_activity_on).to eq(1.day.ago.to_date)
      expect(user_active_today.reload.reload.last_activity_on).to eq(Date.today)
    end
  end

  it 'deletes the pairs from SharedState' do
    data.each { |id, time| Gitlab::UserActivities.record(id, time) }

    subject.perform(data)

    expect(Gitlab::UserActivities.new.to_a).to be_empty
  end
end
