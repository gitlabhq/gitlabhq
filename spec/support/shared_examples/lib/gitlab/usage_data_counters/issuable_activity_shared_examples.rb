# frozen_string_literal: true

RSpec.shared_examples 'tracked issuable snowplow and service ping events for given event params' do
  before do
    stub_application_setting(usage_ping_enabled: true)
  end

  def count_unique(date_from: Date.today.beginning_of_week, date_to: 1.week.from_now)
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
end

RSpec.shared_examples 'tracked issuable snowplow and service ping events with project' do
  it_behaves_like 'tracked issuable snowplow and service ping events for given event params' do
    let(:context) do
      Gitlab::Tracking::ServicePingContext
        .new(data_source: :redis_hll, event: event_property)
        .to_h
    end

    let(:track_params) { original_params || { project: project } }
    let(:event_params) { { project: project }.merge(label: event_label, property: event_property, namespace: project.namespace, context: [context]) }
  end
end

RSpec.shared_examples 'tracked issuable snowplow and service ping events with namespace' do
  it_behaves_like 'tracked issuable snowplow and service ping events for given event params' do
    let(:context) do
      Gitlab::Tracking::ServicePingContext
        .new(data_source: :redis_hll, event: event_property)
        .to_h
    end

    let(:track_params) { { namespace: namespace } }
    let(:event_params) { track_params.merge(label: event_label, property: event_property, context: [context]) }
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
