# frozen_string_literal: true

RSpec.shared_examples 'returns Watchdog Monitor result' do |threshold_violated:|
  it 'returns if threshold is violated and payload' do
    result = monitor.call

    expect(result[:threshold_violated]).to eq(threshold_violated)
    expect(result[:payload]).to eq(payload)
  end
end
