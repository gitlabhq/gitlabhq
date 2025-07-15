# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::LimitManager, :clean_gitlab_redis_queues_metadata,
  feature_category: :scalability do
  let(:worker_class) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
    end
  end

  let(:worker_name) { worker_class.name }
  let(:redis_key_prefix) { 'random_prefix' }
  let(:key) { "#{redis_key_prefix}:{#{worker_name.underscore}}:current_limit" }

  subject(:service) { described_class.new(worker_name: worker_name, prefix: redis_key_prefix) }

  describe '#current_limit' do
    before do
      stub_const(worker_name, worker_class)
      allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap).to receive(:limit_for)
                                                                            .with(worker: worker_name.safe_constantize)
                                                                            .and_return(10)
    end

    context 'when no value has been set before' do
      it 'returns the max limit value set in WorkersMap' do
        expect(service.current_limit).to eq(10)
      end
    end

    context 'when a value has been set before' do
      before do
        with_redis do |r|
          r.set(key, 5, ex: described_class::TTL)
        end
      end

      it 'returns the value set in Redis' do
        expect(service.current_limit).to eq(5)
      end
    end

    context 'with undefined worker' do
      before do
        hide_const(worker_name)
      end

      it 'returns 0' do
        expect(service.current_limit).to eq(0)
      end
    end
  end

  describe '#set_current_limit!' do
    it 'sets the limit in Redis' do
      with_redis do |r|
        expect(r).to receive(:set).with(key, 15, ex: described_class::TTL)
      end

      service.set_current_limit!(15)
    end
  end

  def with_redis(&block)
    Gitlab::Redis::QueuesMetadata.with(&block)
  end
end
