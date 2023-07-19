# frozen_string_literal: true

# Requires a context containing:
# - subject
# - action
# - user
# Optionally, the context can contain:
# - project
# - namespace

RSpec.shared_examples 'internal event tracking' do
  let(:fake_tracker) { instance_spy(Gitlab::Tracking::Destinations::Snowplow) }
  let(:namespace) { nil }
  let(:proejct) { nil }

  before do
    allow(Gitlab::Tracking).to receive(:tracker).and_return(fake_tracker)

    allow(Gitlab::Tracking::StandardContext).to receive(:new).and_call_original
    allow(Gitlab::Tracking::ServicePingContext).to receive(:new).and_call_original
  end

  it 'logs to Snowplow', :aggregate_failures do
    subject

    expect(Gitlab::Tracking::StandardContext)
      .to have_received(:new)
        .with(
          project_id: project&.id,
          user_id: user.id,
          namespace_id: namespace&.id,
          plan_name: namespace&.actual_plan_name
        )

    expect(Gitlab::Tracking::ServicePingContext)
      .to have_received(:new)
        .with(data_source: :redis_hll, event: action)

    expect(fake_tracker).to have_received(:event)
      .with(
        'InternalEventTracking',
        action,
        context: [
          an_instance_of(SnowplowTracker::SelfDescribingJson),
          an_instance_of(SnowplowTracker::SelfDescribingJson)
        ]
      )
      .exactly(:once)
  end
end
