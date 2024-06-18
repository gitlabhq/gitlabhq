# frozen_string_literal: true

RSpec.shared_examples 'tracking unique visits' do |method|
  include TrackingHelpers

  let(:request_params) { {} }

  it 'tracks unique visit if the format is HTML' do
    ids = target_id.instance_of?(String) ? [target_id] : target_id

    ids.each do |id|
      expect(Gitlab::Redis::HLL)
      .to receive(:add).with(hash_including(key: a_string_including(id)))
    end

    # allow other method calls in addition to the expected one
    allow(Gitlab::Redis::HLL).to receive(:add)

    get method, params: request_params, format: :html
  end

  it 'tracks unique visit if DNT is not enabled' do
    ids = target_id.instance_of?(String) ? [target_id] : target_id

    allow(Gitlab::Redis::HLL).to receive(:add)
    ids.each do |id|
      expect(Gitlab::Redis::HLL)
        .to receive(:add)
          .with(hash_including(
            key: a_string_including(id),
            value: anything
          ))
    end

    # allow other method calls in addition to the expected one
    allow(Gitlab::Redis::HLL).to receive(:add)

    stub_do_not_track('0')

    get method, params: request_params, format: :html
  end

  it 'does not track unique visit if DNT is enabled' do
    expect(Gitlab::Redis::HLL).not_to receive(:add)

    stub_do_not_track('1')

    get method, params: request_params, format: :html
  end

  it 'does not track unique visit if the format is JSON' do
    expect(Gitlab::Redis::HLL).not_to receive(:add)

    get method, params: request_params, format: :json
  end
end
