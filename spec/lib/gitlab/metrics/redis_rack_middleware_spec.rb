# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::RedisRackMiddleware do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  before do
    allow(app).to receive(:call).with(env).and_return('wub wub')
  end

  describe '#call' do
    let(:redis_query_time) { 0.1 }
    let(:redis_requests_count) { 2 }

    before do
      allow(Gitlab::Instrumentation::Redis).to receive(:query_time) { redis_query_time }
      allow(Gitlab::Instrumentation::Redis).to receive(:get_request_count) { redis_requests_count }
      allow(Gitlab::Metrics).to receive(:current_transaction).and_return(transaction)
    end

    it 'calls the app' do
      expect(middleware.call(env)).to eq('wub wub')
    end

    it 'records redis metrics' do
      expect(transaction).to receive(:increment).with(:http_redis_requests_total, redis_requests_count)
      expect(transaction).to receive(:observe).with(:http_redis_requests_duration_seconds, redis_query_time)

      middleware.call(env)
    end

    it 'records redis metrics if an error is raised' do
      expect(transaction).to receive(:increment).with(:http_redis_requests_total, redis_requests_count)
      expect(transaction).to receive(:observe).with(:http_redis_requests_duration_seconds, redis_query_time)

      allow(app).to receive(:call).with(env).and_raise(StandardError)

      expect { middleware.call(env) }.to raise_error(StandardError)
    end
  end
end
