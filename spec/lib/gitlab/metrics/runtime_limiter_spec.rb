# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::RuntimeLimiter, feature_category: :value_stream_management do
  let(:max_runtime) { 321 }
  let(:runtime_limiter) { described_class.new(max_runtime) }

  describe '#elapsed_time' do
    it 'reports monotonic elapsed time since instantiation' do
      elapsed = 123
      first_monotonic_time = 100
      second_monotonic_time = first_monotonic_time + elapsed

      expect(Gitlab::Metrics::System).to receive(:monotonic_time)
        .and_return(first_monotonic_time, second_monotonic_time)

      expect(runtime_limiter.elapsed_time).to eq(elapsed)
    end
  end

  describe '#over_time?' do
    it 'returns true if over time' do
      start_time = 100
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(start_time, start_time + max_runtime - 1)

      expect(runtime_limiter.over_time?).to be(false)

      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(start_time + max_runtime)
      expect(runtime_limiter.over_time?).to be(true)

      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(start_time + max_runtime + 1)
      expect(runtime_limiter.over_time?).to be(true)
    end
  end

  describe '#was_over_time?' do
    it 'returns true if over_time? returned true at an earlier step' do
      first_monotonic_time = 10
      second_monotonic_time = first_monotonic_time + 50
      third_monotonic_time = second_monotonic_time + 50 # over time: 110 > 100

      expect(Gitlab::Metrics::System).to receive(:monotonic_time)
        .and_return(first_monotonic_time, second_monotonic_time, third_monotonic_time)

      runtime_limiter = described_class.new(100)

      expect(runtime_limiter.over_time?).to be(false) # uses the second_monotonic_time
      expect(runtime_limiter.was_over_time?).to be(false)

      expect(runtime_limiter.over_time?).to be(true) # uses the third_monotonic_time
      expect(runtime_limiter.was_over_time?).to be(true)
    end
  end
end
