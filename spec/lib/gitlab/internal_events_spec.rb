# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InternalEvents, :snowplow, feature_category: :product_analytics_data_management do
  include TrackingHelpers
  include SnowplowHelpers

  before do
    allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
    allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
    allow(Gitlab::Tracking).to receive(:tracker).and_return(fake_snowplow)
    allow(Gitlab::InternalEvents::EventDefinitions).to receive(:unique_property).and_return(:user)
    allow(fake_snowplow).to receive(:event)
  end

  def expect_redis_hll_tracking(event_name)
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to have_received(:track_event)
      .with(event_name, values: unique_value)
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

  let_it_be(:user) { build(:user, id: 1) }
  let_it_be(:project) { build(:project, id: 2) }
  let_it_be(:namespace) { project.namespace }

  let(:fake_snowplow) { instance_double(Gitlab::Tracking::Destinations::Snowplow) }
  let(:event_name) { 'g_edit_by_web_ide' }
  let(:unique_value) { user.id }

  it 'updates both RedisHLL and Snowplow', :aggregate_failures do
    params = { user: user, project: project, namespace: namespace }
    described_class.track_event(event_name, **params)

    expect_redis_hll_tracking(event_name)
    expect_snowplow_tracking(event_name) # Add test for arguments
  end

  it 'rescues error', :aggregate_failures do
    params = { user: user, project: project, namespace: namespace }
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

  it 'logs error on unknown event', :aggregate_failures do
    expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      .with(described_class::UnknownEventError, event_name: 'unknown_event', kwargs: {})

    expect { described_class.track_event('unknown_event') }.not_to raise_error
  end

  it 'logs error on missing property' do
    expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

    expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
      .with(described_class::InvalidPropertyError, event_name: event_name, kwargs: { merge_request_id: 1 })
  end

  context 'when unique property is missing' do
    before do
      allow(Gitlab::InternalEvents::EventDefinitions).to receive(:unique_property)
        .and_raise(Gitlab::InternalEvents::EventDefinitions::InvalidMetricConfiguration)
    end

    it 'fails on missing unique property' do
      expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
    end
  end

  context 'when unique key is defined' do
    let(:event_name) { 'p_ci_templates_terraform_base_latest' }
    let(:unique_value) { project.id }
    let(:property_name) { :project }

    before do
      allow(Gitlab::InternalEvents::EventDefinitions).to receive(:unique_property)
        .with(event_name)
        .and_return(property_name)
    end

    it 'is used when logging to RedisHLL', :aggregate_failures do
      described_class.track_event(event_name, user: user, project: project)

      expect_redis_hll_tracking(event_name)
      expect_snowplow_tracking(event_name)
    end

    context 'when property is missing' do
      it 'logs error' do
        expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

        expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
          .with(described_class::InvalidPropertyError, event_name: event_name, kwargs: { merge_request_id: 1 })
      end
    end

    context 'when method does not exist on property' do
      it 'logs error on missing method' do
        expect { described_class.track_event(event_name, project: "a_string") }.not_to raise_error

        expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
          .with(described_class::InvalidMethodError, event_name: event_name, kwargs: { project: 'a_string' })
      end
    end
  end
end
