# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::IncrementPerActionedResource,
  :freeze_time, :clean_gitlab_redis_rate_limiting do
  let(:cache_key) { 'test' }
  let(:expiry) { 60 }
  let(:key_does_not_exist) { -2 }

  def increment(resource_key, ttl = expiry)
    described_class.new(resource_key).increment(cache_key, ttl)
  end

  def ttl
    Gitlab::Redis::RateLimiting.with { |r| r.ttl(cache_key) }
  end

  describe '#increment' do
    it 'increments per resource', :aggregate_failures do
      expect(increment('resource_1')).to eq(1)
      expect(increment('resource_1')).to eq(1)
      expect(increment('resource_2')).to eq(2)
      expect(increment('resource_2')).to eq(2)
      expect(increment('resource_3')).to eq(3)
    end

    it 'sets time to live (TTL) for the key on first increment' do
      expect(ttl).to eq key_does_not_exist
      expect { increment('resource_1') }.to change { ttl }.by(a_value > 0)
      expect { increment('resource_1', expiry + 1) }.not_to change { ttl }
      expect { increment('resource_2', expiry + 2) }.not_to change { ttl }
    end

    context 'when optimize_rate_limiter_redis_expiry is disabled' do
      before do
        stub_feature_flags(optimize_rate_limiter_redis_expiry: false)
      end

      it 'sets TTL on each increment' do
        expect(ttl).to eq key_does_not_exist
        expect { increment('resource_1') }.to change { ttl }.by(a_value > 0)
        expect { increment('resource_1', expiry + 1) }.to change { ttl }.by(a_value > 0)
        expect { increment('resource_2', expiry + 2) }.to change { ttl }.by(a_value > 0)
      end
    end
  end

  describe '#read' do
    def read
      described_class.new(nil).read(cache_key)
    end

    it 'returns 0 when there is no data' do
      expect(read).to eq 0
    end

    it 'returns the correct value', :aggregate_failures do
      increment 'r1'
      expect(read).to eq 1

      increment 'r2'
      expect(read).to eq 2
    end
  end
end
