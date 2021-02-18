# frozen_string_literal: true
#
# Requires a context containing:
# - request
# - expected_type
# - target_id

RSpec.shared_examples 'tracking unique hll events' do
  it 'tracks unique event' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to(
      receive(:track_event)
        .with(target_id, values: expected_type)
        .and_call_original # we call original to trigger additional validations; otherwise the method is stubbed
    )

    request
  end
end
