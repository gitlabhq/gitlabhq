# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::IncrementPerAction, :freeze_time, :clean_gitlab_redis_rate_limiting do
  let(:cache_key) { 'test' }
  let(:expiry) { 60 }

  subject(:counter) { described_class.new }

  def increment
    counter.increment(cache_key, expiry)
  end

  describe '#increment' do
    it 'increments per call' do
      expect(increment).to eq 1
      expect(increment).to eq 2
      expect(increment).to eq 3
    end

    it 'sets time to live (TTL) for the key' do
      def ttl
        Gitlab::Redis::RateLimiting.with { |r| r.ttl(cache_key) }
      end

      key_does_not_exist = -2

      expect(ttl).to eq key_does_not_exist
      expect { increment }.to change { ttl }.by(a_value > 0)
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
