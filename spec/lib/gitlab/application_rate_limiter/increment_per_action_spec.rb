# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::IncrementPerAction, :freeze_time, :clean_gitlab_redis_rate_limiting do
  let(:cache_key) { 'test' }
  let(:expiry) { 60 }
  let(:key_does_not_exist) { -2 }

  subject(:counter) { described_class.new }

  def increment(ttl = expiry)
    counter.increment(cache_key, ttl)
  end

  def ttl
    Gitlab::Redis::RateLimiting.with { |r| r.ttl(cache_key) }
  end

  describe '#increment' do
    it 'increments per call' do
      expect(increment).to eq 1
      expect(increment).to eq 2
      expect(increment).to eq 3
    end

    it 'sets time to live (TTL) for the key on first increment' do
      expect(ttl).to eq key_does_not_exist
      expect { increment }.to change { ttl }.by(a_value > 0)
      expect { increment(expiry + 1) }.not_to change { ttl }
    end

    context 'when optimize_rate_limiter_redis_expiry is disabled' do
      before do
        stub_feature_flags(optimize_rate_limiter_redis_expiry: false)
      end

      it 'sets TTL on each increment' do
        expect(ttl).to eq key_does_not_exist
        expect { increment }.to change { ttl }.by(a_value > 0)
        expect { increment(expiry + 1) }.to change { ttl }.by(a_value > 0)
      end
    end
  end

  describe '#read' do
    def read
      counter.read(cache_key)
    end

    it 'returns 0 when there is no data' do
      expect(read).to eq 0
    end

    it 'returns the correct value', :aggregate_failures do
      increment
      expect(read).to eq 1

      increment
      expect(read).to eq 2
    end
  end
end
