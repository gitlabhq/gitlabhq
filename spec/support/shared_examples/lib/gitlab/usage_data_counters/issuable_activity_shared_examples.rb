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

RSpec.shared_examples 'a daily tracked issuable snowplow and service ping events for given event params' do
  before do
    stub_application_setting(usage_ping_enabled: true)
  end

  def count_unique(date_from: 1.minute.ago, date_to: 1.minute.from_now)
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: action, start_date: date_from, end_date: date_to)
  end

  specify do
    aggregate_failures do
      expect(track_action({ author: user1 }.merge(track_params))).to be_truthy
      expect(track_action({ author: user1 }.merge(track_params))).to be_truthy
      expect(track_action({ author: user2 }.merge(track_params))).to be_truthy
      expect(count_unique).to eq(2)
    end
  end

  it 'does not track edit actions if author is not present' do
    expect(track_action({ author: nil }.merge(track_params))).to be_nil
  end

  it 'emits snowplow event' do
    track_action({ author: user1 }.merge(track_params))

    expect_snowplow_event(**{ category: category, action: event_action, user: user1 }.merge(event_params))
  end

  context 'with route_hll_to_snowplow_phase2 disabled' do
    before do
      stub_feature_flags(route_hll_to_snowplow_phase2: false)
    end

    it 'does not emit snowplow event' do
      track_action({ author: user1 }.merge(track_params))

      expect_no_snowplow_event
    end
  end
end

RSpec.shared_examples 'a daily tracked issuable snowplow and service ping events' do
  it_behaves_like 'a daily tracked issuable snowplow and service ping events for given event params' do
    let_it_be(:track_params) { { project: project } }
    let_it_be(:event_params) { track_params.merge(namespace: project.namespace) }
    let_it_be(:category) { 'issues_edit' }
    let_it_be(:event_action) { action }
  end
end

RSpec.shared_examples 'a daily tracked issuable snowplow and service ping events with namespace' do
  it_behaves_like 'a daily tracked issuable snowplow and service ping events for given event params' do
    let(:track_params) { { namespace: namespace } }
    let(:event_params) { track_params.merge(label: event_label, property: event_property) }
  end
end

RSpec.shared_examples 'does not track with namespace when feature flag is disabled' do |feature_flag|
  context "when feature flag #{feature_flag} is disabled" do
    it 'does not track action' do
      stub_feature_flags(feature_flag => false)

      expect(track_action(author: user1, namespace: namespace)).to be_nil
    end
  end
end
