# frozen_string_literal: true

RSpec.shared_examples 'an incident management tracked event' do |event|
  describe ".track_event", :clean_gitlab_redis_shared_state do
    let(:counter) { Gitlab::UsageDataCounters::HLLRedisCounter }
    let(:start_time) { 1.week.ago }
    let(:end_time) { 1.week.from_now }

    it "tracks the event using redis" do
      # Allow other subsequent calls
      allow(Gitlab::UsageDataCounters::HLLRedisCounter)
        .to receive(:track_event)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter)
        .to receive(:track_event)
        .with(event.to_s, values: current_user.id)
        .and_call_original

      expect { subject }
        .to change { counter.unique_events(event_names: event.to_s, start_date: start_time, end_date: end_time) }
        .by 1
    end
  end
end

RSpec.shared_examples 'does not track incident management event' do |event|
  it 'does not track the event', :clean_gitlab_redis_shared_state do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter)
      .not_to receive(:track_event)
      .with(anything, event.to_s)
  end
end
