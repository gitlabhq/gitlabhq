# frozen_string_literal: true

# Requires a context containing:
# - subject
# - event
# Optionally, the context can contain:
# - user
# - project
# - namespace
# - category
# - label
# - property
# - value

RSpec.shared_examples 'internal event tracking' do
  let(:fake_tracker) { instance_spy(Gitlab::Tracking::Destinations::Snowplow) }
  let(:fake_counter) { class_spy(Gitlab::UsageDataCounters::HLLRedisCounter) }

  before do
    allow(Gitlab::Tracking).to receive(:tracker).and_return(fake_tracker)
    stub_const('Gitlab::UsageDataCounters::HLLRedisCounter', fake_counter)

    allow(Gitlab::Tracking::StandardContext).to receive(:new).and_call_original
    allow(Gitlab::Tracking::ServicePingContext).to receive(:new).and_call_original
  end

  it 'logs to Snowplow and Redis', :aggregate_failures do
    subject

    project = try(:project)
    user = try(:user)
    namespace = try(:namespace) || project&.namespace
    category = try(:category) || 'InternalEventTracking'

    additional_properties = {
      label: try(:label),
      property: try(:property),
      value: try(:value)
    }.compact

    expect(Gitlab::Tracking::StandardContext)
      .to have_received(:new)
        .with(
          feature_enabled_by_namespace_ids: try(:feature_enabled_by_namespace_ids),
          project_id: project&.id,
          user_id: user&.id,
          namespace_id: namespace&.id,
          plan_name: namespace&.actual_plan_name
        ).at_least(:once)

    expect(Gitlab::Tracking::ServicePingContext)
      .to have_received(:new)
        .with(data_source: :redis_hll, event: event)
        .at_least(:once)

    expect(fake_tracker).to have_received(:event)
      .with(
        category.to_s,
        event,
        a_hash_including(
          context: [
            an_instance_of(SnowplowTracker::SelfDescribingJson),
            an_instance_of(SnowplowTracker::SelfDescribingJson)
          ],
          **additional_properties
        )
      ).at_least(:once)

    Gitlab::InternalEvents::EventDefinitions.unique_properties(event).each do |property|
      expect(fake_counter).to have_received(:track_event)
        .with(
          event,
          a_hash_including(
            values: send(property)&.id,
            property_name: property
          )
        )
    end
  end
end

# Requires a context containing:
# - subject
# Optionally, the context can contain:
# - event

RSpec.shared_examples 'internal event not tracked' do
  it 'does not record an internal event' do
    if defined?(event)
      expect(Gitlab::InternalEvents).not_to receive(:track_event).with(event, any_args)
    else
      expect(Gitlab::InternalEvents).not_to receive(:track_event)
    end

    subject
  end
end
