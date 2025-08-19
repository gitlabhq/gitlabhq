# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Throttling::Middleware, feature_category: :scalability do
  include ExclusiveLeaseHelpers

  let(:worker_class) { TestWorker }
  let(:middleware) { described_class.new(worker_class.new) }

  before do
    stub_const('TestWorker', Class.new do
      def self.name
        'TestWorker'
      end

      def perform(*args); end

      include ApplicationWorker
      feature_category :scalability
    end)
  end

  describe '#perform' do
    subject(:perform) { middleware.perform { break } }

    let(:tracker) { instance_double(Gitlab::SidekiqMiddleware::Throttling::Tracker) }
    let(:decider) { instance_double(Gitlab::SidekiqMiddleware::Throttling::Decider) }
    let(:concurrency_limit_service) { Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService }
    let(:lease_key) { "gitlab/sidekiq_middleware/throttling/middleware:test_worker" }
    let(:timeout) { described_class::LEASE_TIMEOUT }

    before do
      allow(Gitlab::SidekiqMiddleware::Throttling::Tracker).to receive(:new).and_return(tracker)
      allow(Gitlab::SidekiqMiddleware::Throttling::Decider).to receive(:new).and_return(decider)
      allow(tracker).to receive(:currently_throttled?).and_return(false)
      allow(tracker).to receive(:record)
      stub_exclusive_lease(lease_key, timeout: timeout)
      stub_feature_flags(disable_sidekiq_throttling_middleware_TestWorker: false)
    end

    shared_examples 'yields control' do
      it 'yields control' do
        expect { |b| middleware.perform(&b) }.to yield_control
      end
    end

    shared_examples 'skips throttling checks' do
      it 'does not check if already throttled' do
        expect(tracker).not_to receive(:currently_throttled?)

        perform
      end

      it 'does not make a throttling decision' do
        expect(decider).not_to receive(:execute)

        perform
      end
    end

    shared_examples 'skips throttling actions' do
      it 'does not record throttling' do
        expect(tracker).not_to receive(:record)

        perform
      end

      it 'does not change the concurrency limit' do
        expect(concurrency_limit_service).not_to receive(:set_current_limit!)

        perform
      end
    end

    shared_examples 'performs throttling' do |limit_reduction_factor|
      it 'records throttling' do
        expect(tracker).to receive(:record)

        perform
      end

      it "decreases the concurrency limit by #{limit_reduction_factor}" do
        new_limit = (current_limit * limit_reduction_factor).to_i
        expect(concurrency_limit_service).to receive(:set_current_limit!).with('TestWorker', limit: new_limit)

        perform
      end

      it 'logs the throttling decision' do
        new_limit = (current_limit * limit_reduction_factor).to_i
        expect(Sidekiq.logger).to receive(:info).with(
          class: 'TestWorker',
          throttling_decision: strategy.name,
          message: "TestWorker is throttled with strategy #{strategy.name}.",
          new_concurrency_limit: new_limit,
          previous_concurrency_limit: current_limit
        )

        perform
      end

      it 'reports prometheus metrics' do
        counter_double = instance_double(Prometheus::Client::Counter)
        allow(Gitlab::Metrics).to receive(:counter).and_call_original
        expect(Gitlab::Metrics).to receive(:counter).with(:sidekiq_throttling_events_total, anything)
                                                    .and_return(counter_double)
        expect(counter_double).to receive(:increment).with({ worker: 'TestWorker', strategy: strategy.name,
                                                             feature_category: :scalability })

        perform
      end
    end

    context 'when feature flag :sidekiq_throttling_middleware is disabled' do
      before do
        stub_feature_flags(sidekiq_throttling_middleware: false)
      end

      include_examples 'yields control'
      include_examples 'skips throttling checks'
      include_examples 'skips throttling actions'
    end

    context 'when already throttled' do
      before do
        allow(tracker).to receive(:currently_throttled?).and_return(true)
      end

      include_examples 'yields control'
      include_examples 'skips throttling actions'

      it 'does not make a throttling decision' do
        expect(decider).not_to receive(:execute)

        perform
      end
    end

    context 'when not already throttled' do
      let(:current_limit) { 10 }

      before do
        allow(concurrency_limit_service).to receive(:current_limit).and_return(current_limit)
      end

      context 'when throttling is not needed' do
        let(:decision) do
          Gitlab::SidekiqMiddleware::Throttling::Decider::Decision.new(
            false, Gitlab::SidekiqMiddleware::Throttling::Strategy::None)
        end

        before do
          allow(decider).to receive(:execute).and_return(decision)
        end

        include_examples 'yields control'
        include_examples 'skips throttling actions'
      end

      context 'when throttling is needed' do
        let(:decision) { Gitlab::SidekiqMiddleware::Throttling::Decider::Decision.new(true, strategy) }

        before do
          allow(decider).to receive(:execute).and_return(decision)
        end

        context 'with SoftThrottle strategy' do
          let(:strategy) { Gitlab::SidekiqMiddleware::Throttling::Strategy::SoftThrottle }

          include_examples 'performs throttling', 0.8
        end

        context 'with HardThrottle strategy' do
          let(:strategy) { Gitlab::SidekiqMiddleware::Throttling::Strategy::HardThrottle }

          include_examples 'performs throttling', 0.5
        end

        context 'when current limit is 0' do
          let(:current_limit) { 0 }
          let(:decision) do
            Gitlab::SidekiqMiddleware::Throttling::Decider::Decision.new(
              false, Gitlab::SidekiqMiddleware::Throttling::Strategy::SoftThrottle)
          end

          include_examples 'yields control'
          include_examples 'skips throttling actions'
        end
      end
    end

    context 'when lease cannot be obtained' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: timeout)
      end

      include_examples 'yields control'
      include_examples 'skips throttling checks'
      include_examples 'skips throttling actions'
    end

    context 'when disable_sidekiq_throttling_middleware FF is enabled' do
      before do
        stub_feature_flags(disable_sidekiq_throttling_middleware_TestWorker: true)
      end

      include_examples 'yields control'
      include_examples 'skips throttling checks'
      include_examples 'skips throttling actions'
    end
  end
end
