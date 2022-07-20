# frozen_string_literal: true

RSpec.shared_examples 'counter that does not track the event' do
  it 'does not track the event' do
    expect { 3.times { track_event } }.to not_change {
      Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
        event_names: event_name,
        start_date: 2.weeks.ago,
        end_date: 2.weeks.from_now
      )
    }
  end
end

RSpec.shared_examples 'work item unique counter' do
  context 'when track_work_items_activity FF is enabled' do
    it 'tracks a unique event only once' do
      expect { 3.times { track_event } }.to change {
        Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
          event_names: event_name,
          start_date: 2.weeks.ago,
          end_date: 2.weeks.from_now
        )
      }.by(1)
    end

    context 'when author is nil' do
      let(:user) { nil }

      it_behaves_like 'counter that does not track the event'
    end
  end

  context 'when track_work_items_activity FF is disabled' do
    before do
      stub_feature_flags(track_work_items_activity: false)
    end

    it_behaves_like 'counter that does not track the event'
  end
end
