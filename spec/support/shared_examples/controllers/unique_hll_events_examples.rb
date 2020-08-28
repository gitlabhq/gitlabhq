# frozen_string_literal: true

RSpec.shared_examples 'tracking unique hll events' do |method|
  it 'tracks unique event if the format is HTML' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(instance_of(String), target_id)

    get method, params: request_params, format: :html
  end

  it 'tracks unique event if DNT is not enabled' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(instance_of(String), target_id)
    request.headers['DNT'] = '0'

    get method, params: request_params, format: :html
  end

  it 'does not track unique event if DNT is enabled' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(instance_of(String), target_id)
    request.headers['DNT'] = '1'

    get method, params: request_params, format: :html
  end

  it 'does not track unique event if the format is JSON' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(instance_of(String), target_id)

    get method, params: request_params, format: :json
  end
end
