# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::IncrementResourceUsagePerAction, :freeze_time,
  :clean_gitlab_redis_rate_limiting, feature_category: :shared do
  let(:resource_key) { :usage_duration_s }
  let(:usage) { 100 }
  let(:cache_key) { 'test' }
  let(:expiry) { 60 }
  let(:key_does_not_exist) { -2 }

  subject(:counter) { described_class.new(resource_key) }

  around do |example|
    Gitlab::SafeRequestStore.ensure_request_store do
      Gitlab::SafeRequestStore[resource_key] = usage

      example.run
    end
  end

  def increment(ttl = expiry)
    counter.increment(cache_key, ttl)
  end

  def ttl
    Gitlab::Redis::RateLimiting.with { |r| r.ttl(cache_key) }
  end

  describe '#increment' do
    it 'increments per call' do
      expect(increment).to eq usage
      expect(increment).to eq 2 * usage
      expect(increment).to eq 3 * usage
    end

    it 'sets time to live (TTL) for the key on first increment' do
      expect(ttl).to eq key_does_not_exist
      expect { increment }.to change { ttl }.by(a_value > 0)
      expect { increment(expiry + 1) }.not_to change { ttl }
    end

    context 'when usage value is 0' do
      let(:usage) { 0 }

      it 'does not store the value in Redis' do
        expect(increment).to eq usage

        Gitlab::Redis::RateLimiting.with do |r|
          expect(r.get(cache_key)).to be_nil
        end
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
      expect(read).to eq usage

      increment
      expect(read).to eq 2 * usage
    end
  end
end
