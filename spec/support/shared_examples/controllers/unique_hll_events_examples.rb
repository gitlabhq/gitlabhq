# frozen_string_literal: true

#
# Requires a context containing:
# - request
# - expected_value
# - target_event

RSpec.shared_examples 'tracking unique hll events' do
  it 'tracks unique event' do
    # Allow any event tracking before we expect the specific event we want to check below
    allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).and_call_original

    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to(
      receive(:track_event)
        .with(target_event, values: expected_value)
        .and_call_original # we call original to trigger additional validations; otherwise the method is stubbed
    )

    request
  end
end
