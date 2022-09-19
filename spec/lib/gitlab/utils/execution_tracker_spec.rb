# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::ExecutionTracker do
  subject(:tracker) { described_class.new }

  describe '#over_limit?' do
    it 'is true when max runtime is exceeded' do
      monotonic_time_before = 1 # this will be the start time
      monotonic_time_after = described_class::MAX_RUNTIME.to_i + 1 # this will be returned when over_limit? is called

      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(monotonic_time_before, monotonic_time_after)

      tracker

      expect(tracker).to be_over_limit
    end

    it 'is false when max runtime is not exceeded' do
      expect(tracker).not_to be_over_limit
    end
  end
end
