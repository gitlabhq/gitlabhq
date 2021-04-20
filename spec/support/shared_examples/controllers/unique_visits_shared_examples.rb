# frozen_string_literal: true

RSpec.shared_examples 'tracking unique visits' do |method|
  let(:request_params) { {} }

  it 'tracks unique visit if the format is HTML' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter)
      .to receive(:track_event).with(target_id, values: kind_of(String))

    get method, params: request_params, format: :html
  end

  it 'tracks unique visit if DNT is not enabled' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter)
      .to receive(:track_event).with(target_id, values: kind_of(String))

    request.headers['DNT'] = '0'

    get method, params: request_params, format: :html
  end

  it 'does not track unique visit if DNT is enabled' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)
    request.headers['DNT'] = '1'

    get method, params: request_params, format: :html
  end

  it 'does not track unique visit if the format is JSON' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

    get method, params: request_params, format: :json
  end
end
