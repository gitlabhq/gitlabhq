# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Kas::ExponentialBackoff, feature_category: :deployment_management do
  describe '#next' do
    context 'without jitter' do
      subject(:backoff) { described_class.new(min: 1, max: 30, multiplier: 2, jitter: false) }

      it 'returns increasing delays that grow by the multiplier' do
        expect([backoff.next, backoff.next, backoff.next, backoff.next]).to eq([1, 2, 4, 8])
      end

      it 'caps the delay at max' do
        # 1, 2, 4, 8, 16, then capped at 30
        7.times { backoff.next }

        expect(backoff.next).to eq(30)
      end
    end

    context 'with jitter' do
      subject(:backoff) { described_class.new(min: 4, max: 30, multiplier: 2, jitter: true) }

      it 'returns a value within [0, current] for each step', :aggregate_failures do
        # First step is based on min (4) -> jittered into [0, 4].
        # Second step is based on 8 -> jittered into [0, 8].
        expect(backoff.next).to be_between(0.0, 4.0)
        expect(backoff.next).to be_between(0.0, 8.0)
      end

      it 'caps the jittered delay ceiling at max' do
        # Advance well past max (4, 8, 16, then capped at 30) so the jitter window is [0, 30].
        10.times { backoff.next }

        expect(backoff.next).to be_between(0.0, 30.0)
      end
    end
  end

  describe '#reset' do
    subject(:backoff) { described_class.new(min: 1, max: 30, multiplier: 2, jitter: false) }

    it 'resets the delay back to min' do
      3.times { backoff.next }

      backoff.reset

      expect(backoff.next).to eq(1)
    end

    it 'returns nil' do
      expect(backoff.reset).to be_nil
    end
  end
end
