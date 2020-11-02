# frozen_string_literal: true

RSpec.shared_examples 'a tracked issue edit event' do |event|
  before do
    stub_application_setting(usage_ping_enabled: true)
  end

  def count_unique(date_from:, date_to:)
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: action, start_date: date_from, end_date: date_to)
  end

  specify do
    aggregate_failures do
      expect(track_action(author: user1)).to be_truthy
      expect(track_action(author: user1)).to be_truthy
      expect(track_action(author: user2)).to be_truthy
      expect(track_action(author: user3, time: time - 3.days)).to be_truthy

      expect(count_unique(date_from: time, date_to: time)).to eq(2)
      expect(count_unique(date_from: time - 5.days, date_to: 1.day.since(time))).to eq(3)
    end
  end

  it 'does not track edit actions if author is not present' do
    expect(track_action(author: nil)).to be_nil
  end

  context 'when feature flag track_issue_activity_actions is disabled' do
    it 'does not track edit actions' do
      stub_feature_flags(track_issue_activity_actions: false)

      expect(track_action(author: user1)).to be_nil
    end
  end
end
