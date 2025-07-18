# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RateLimiting do
  include_examples "redis_new_instance_shared_examples", 'rate_limiting', Gitlab::Redis::Cache

  describe '.with_suppressed_errors' do
    subject(:ping) { described_class.with_suppressed_errors(&:ping) }

    before do
      allow(described_class).to receive(:with).and_yield(redis)
    end

    context 'when using Redis' do
      let(:redis) { described_class.send(:init_redis, { url: 'redis://127.0.0.0:0' }) }

      it 'tracks the error and returns nil' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(a_kind_of(::Redis::CannotConnectError))

        expect(ping).to be_nil
      end
    end

    context 'when using RedisCluster' do
      let(:redis) do
        described_class.send(:init_redis, {
          nodes: [
            { host: '127.0.0.0', port: 0, db: 1 },
            { host: '127.0.0.0', port: 0, db: 2 },
            { host: '127.0.0.0', port: 0, db: 3 }
          ]
        })
      end

      it 'tracks the error and returns nil' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(a_kind_of(::Redis::Cluster::InitialSetupError))

        expect(ping).to be_nil
      end
    end

    context 'with a RedisClient exception' do
      let(:redis) { instance_double(Redis) }

      before do
        allow(redis).to receive(:ping).and_raise(::RedisClient::ReadTimeoutError)
      end

      it 'tracks the error and returns nil' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(a_kind_of(::RedisClient::ReadTimeoutError))

        expect(ping).to be_nil
      end
    end
  end
end
