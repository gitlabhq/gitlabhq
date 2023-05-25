# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InternalEvents, :snowplow, feature_category: :product_analytics do
  include TrackingHelpers
  include SnowplowHelpers

  before do
    allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
    allow(Gitlab::Tracking).to receive(:tracker).and_return(fake_snowplow)
    allow(fake_snowplow).to receive(:event)
  end

  def expect_redis_hll_tracking(event_name)
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to have_received(:track_event)
      .with(event_name, anything)
  end

  def expect_snowplow_tracking(event_name)
    service_ping_context = Gitlab::Tracking::ServicePingContext
      .new(data_source: :redis_hll, event: event_name)
      .to_context
      .to_json

    expect(SnowplowTracker::SelfDescribingJson).to have_received(:new)
      .with(service_ping_context[:schema], service_ping_context[:data]).at_least(:once)

    # Add test for creation of both contexts
    contexts = [instance_of(SnowplowTracker::SelfDescribingJson), instance_of(SnowplowTracker::SelfDescribingJson)]

    expect(fake_snowplow).to have_received(:event)
      .with('InternalEventTracking', event_name, context: contexts)
  end

  let_it_be(:user) { build(:user) }
  let_it_be(:project) { build(:project) }
  let_it_be(:namespace) { project.namespace }

  let(:fake_snowplow) { instance_double(Gitlab::Tracking::Destinations::Snowplow) }
  let(:event_name) { 'g_edit_by_web_ide' }

  it 'updates both RedisHLL and Snowplow', :aggregate_failures do
    params = { user_id: user.id, project_id: project.id, namespace_id: namespace.id }
    described_class.track_event(event_name, **params)

    expect_redis_hll_tracking(event_name)
    expect_snowplow_tracking(event_name) # Add test for arguments
  end

  it 'rescues error' do
    params = { user_id: user.id, project_id: project.id, namespace_id: namespace.id }
    error = StandardError.new("something went wrong")
    allow(fake_snowplow).to receive(:event).and_raise(error)

    expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      .with(
        error,
        snowplow_category: 'InternalEventTracking',
        snowplow_action: event_name
      )

    expect { described_class.track_event(event_name, **params) }.not_to raise_error
  end
end
