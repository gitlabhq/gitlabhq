# frozen_string_literal: true

RSpec.shared_examples 'tracking unique visits' do |method|
  let(:request_params) { {} }

  it 'tracks unique visit if the format is HTML' do
    expect_any_instance_of(Gitlab::Analytics::UniqueVisits).to receive(:track_visit).with(instance_of(String), target_id)

    get method, params: request_params, format: :html
  end

  it 'tracks unique visit if DNT is not enabled' do
    expect_any_instance_of(Gitlab::Analytics::UniqueVisits).to receive(:track_visit).with(instance_of(String), target_id)
    request.headers['DNT'] = '0'

    get method, params: request_params, format: :html
  end

  it 'does not track unique visit if DNT is enabled' do
    expect_any_instance_of(Gitlab::Analytics::UniqueVisits).not_to receive(:track_visit)
    request.headers['DNT'] = '1'

    get method, params: request_params, format: :html
  end

  it 'does not track unique visit if the format is JSON' do
    expect_any_instance_of(Gitlab::Analytics::UniqueVisits).not_to receive(:track_visit)

    get method, params: request_params, format: :json
  end
end
