# frozen_string_literal: true

RSpec.shared_examples 'a daily tracked issuable event' do
  before do
    stub_application_setting(usage_ping_enabled: true)
  end

  def count_unique(date_from: 1.minute.ago, date_to: 1.minute.from_now)
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: action, start_date: date_from, end_date: date_to)
  end

  specify do
    aggregate_failures do
      expect(track_action(author: user1)).to be_truthy
      expect(track_action(author: user1)).to be_truthy
      expect(track_action(author: user2)).to be_truthy
      expect(count_unique).to eq(2)
    end
  end

  it 'does not track edit actions if author is not present' do
    expect(track_action(author: nil)).to be_nil
  end
end

RSpec.shared_examples 'does not track when feature flag is disabled' do |feature_flag|
  context "when feature flag #{feature_flag} is disabled" do
    it 'does not track action' do
      stub_feature_flags(feature_flag => false)

      expect(track_action(author: user1)).to be_nil
    end
  end
end

RSpec.shared_examples 'a daily tracked issuable snowplow and service ping events' do
  before do
    stub_application_setting(usage_ping_enabled: true)
  end

  def count_unique(date_from: 1.minute.ago, date_to: 1.minute.from_now)
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: action, start_date: date_from, end_date: date_to)
  end

  specify do
    aggregate_failures do
      expect(track_action(author: user1, project: project)).to be_truthy
      expect(track_action(author: user1, project: project)).to be_truthy
      expect(track_action(author: user2, project: project)).to be_truthy
      expect(count_unique).to eq(2)
    end
  end

  it 'does not track edit actions if author is not present' do
    expect(track_action(author: nil, project: project)).to be_nil
  end

  it 'emits snowplow event' do
    track_action(author: user1, project: project)

    expect_snowplow_event(category: 'issues_edit', action: action, user: user1,
                          namespace: project.namespace, project: project)
  end

  context 'with route_hll_to_snowplow_phase2 disabled' do
    before do
      stub_feature_flags(route_hll_to_snowplow_phase2: false)
    end

    it 'does not emit snowplow event' do
      track_action(author: user1, project: project)

      expect_no_snowplow_event
    end
  end
end
