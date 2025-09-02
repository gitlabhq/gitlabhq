# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Throttling::RecoveryService, feature_category: :scalability do
  let(:worker_name) { 'TestWorker' }
  let(:worker_klass) { TestWorker }
  let(:recovery_service) { described_class.new(worker_name) }

  before do
    stub_const('TestWorker', Class.new do
      def self.name
        'TestWorker'
      end
      include ApplicationWorker

      concurrency_limit -> { 20 }
    end)
  end

  describe '#execute' do
    let(:decider) { instance_double(Gitlab::SidekiqMiddleware::Throttling::Decider) }
    let(:concurrency_limit_service) { Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService }
    let(:tracker) { instance_double(Gitlab::SidekiqMiddleware::Throttling::Tracker) }

    before do
      allow(Gitlab::SidekiqMiddleware::Throttling::Decider).to receive(:new).with(worker_name).and_return(decider)
      allow(Gitlab::SidekiqMiddleware::Throttling::Tracker).to receive(:new).with(worker_name).and_return(tracker)
      allow(concurrency_limit_service).to receive(:current_limit).and_return(10)
      allow(concurrency_limit_service).to receive(:set_current_limit!)
      allow(tracker).to receive(:remove_from_throttled_list!)
    end

    context 'when worker needs throttling' do
      before do
        allow(decider).to receive(:execute).and_return(
          Gitlab::SidekiqMiddleware::Throttling::Decider::Decision.new(true,
            Gitlab::SidekiqMiddleware::Throttling::Strategy::SoftThrottle)
        )
      end

      it 'does not recover the worker' do
        expect(concurrency_limit_service).not_to receive(:set_current_limit!)
        expect(tracker).not_to receive(:remove_from_throttled_list!)

        recovery_service.execute
      end
    end

    context 'when worker does not need throttling' do
      before do
        allow(decider).to receive(:execute).and_return(
          Gitlab::SidekiqMiddleware::Throttling::Decider::Decision.new(false,
            Gitlab::SidekiqMiddleware::Throttling::Strategy::None)
        )
      end

      it 'recovers the worker' do
        expect(concurrency_limit_service).to receive(:set_current_limit!).with(worker_name, limit: 11)
        expect(Sidekiq.logger).to receive(:info).with(
          message: "Recovering concurrency limit for #{worker_name}",
          recovery_strategy: "GradualRecovery",
          class: worker_name,
          previous_concurrency_limit: 10,
          new_concurrency_limit: 11,
          max_concurrency_limit: 20
        )
        expect(tracker).not_to receive(:remove_from_throttled_list!)

        recovery_service.execute
      end

      context 'when current limit is already max limit' do
        before do
          allow(concurrency_limit_service).to receive(:current_limit).and_return(20)
        end

        it 'does not change the limit' do
          expect(concurrency_limit_service).to receive(:set_current_limit!).with(worker_name, limit: 20)
          expect(tracker).to receive(:remove_from_throttled_list!)

          recovery_service.execute
        end
      end

      context 'when new limit reaches max limit' do
        before do
          allow(concurrency_limit_service).to receive(:current_limit).and_return(19)
        end

        it 'removes the worker from throttled list' do
          expect(concurrency_limit_service).to receive(:set_current_limit!).with(worker_name, limit: 20)
          expect(tracker).to receive(:remove_from_throttled_list!)

          recovery_service.execute
        end
      end
    end
  end
end
