# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ResourceUsageLimiter, feature_category: :shared do
  let(:resource_key) { 'db_duration_s' }
  let(:worker_name) { 'test_worker' }
  let(:threshold) { 100 }
  let(:interval) { 60 }

  let(:limits) do
    [
      Gitlab::SidekiqLimits::Limit.new(
        :test_limit_per_user,
        resource_key,
        %w[worker_name user_id],
        nil,
        threshold,
        interval
      ),
      Gitlab::SidekiqLimits::Limit.new(
        :test_limit,
        resource_key,
        %w[worker_name],
        nil,
        threshold,
        interval
      )
    ]
  end

  before do
    allow(Gitlab::ApplicationContext).to receive(:current).and_return({ user_id: 1 })
    allow(Gitlab::SidekiqLimits).to receive(:limits_for).and_return(limits)
  end

  describe '.exceeded_limits' do
    let(:peek) { false }

    it 'returns empty list if worker_name is missing' do
      expect(described_class.new.exceeded_limits).to eq([])
    end

    it 'checks against all limits' do
      expect(Gitlab::ApplicationRateLimiter)
          .to receive(:resource_usage_throttled?)
            .once
            .with(:test_limit, resource_key: resource_key, scope: [worker_name],
              threshold: threshold, interval: interval, peek: peek)

      expect(Gitlab::ApplicationRateLimiter)
          .to receive(:resource_usage_throttled?)
            .once
            .with(:test_limit_per_user, resource_key: resource_key, scope: [worker_name,
              1], threshold: threshold, interval: interval, peek: peek)

      described_class.new(worker_name: worker_name).exceeded_limits
    end

    context 'when scopes are missing' do
      before do
        allow(Gitlab::ApplicationContext).to receive(:current).and_return({})
      end

      it 'skips limit check if scope details missing' do
        expect(Gitlab::ApplicationRateLimiter)
          .to receive(:resource_usage_throttled?)
            .once
            .with(:test_limit, anything)

        described_class.new(worker_name: worker_name).exceeded_limits
      end
    end
  end

  describe '.exceeded_limits?' do
    let(:peek) { true }
    let(:resource_usage_limiter) { described_class.new(worker_name: worker_name) }

    subject(:exceeded_limits?) { resource_usage_limiter.exceeded_limits? }

    it 'returns false if worker_name is missing' do
      expect(described_class.new).not_to be_exceeded_limits
    end

    it 'checks against all limits with peek' do
      expect(Gitlab::ApplicationRateLimiter)
        .to receive(:resource_usage_throttled?)
              .once
              .with(:test_limit, resource_key: resource_key, scope: [worker_name],
                threshold: threshold, interval: interval, peek: peek)

      expect(Gitlab::ApplicationRateLimiter)
        .to receive(:resource_usage_throttled?)
              .once
              .with(:test_limit_per_user, resource_key: resource_key, scope: [worker_name,
                1], threshold: threshold, interval: interval, peek: peek)

      exceeded_limits?
    end

    context 'when one limit is throttled' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:resource_usage_throttled?)
                                                   .with(:test_limit_per_user, anything)
                                                   .and_return(true)
        allow(Gitlab::ApplicationRateLimiter).to receive(:resource_usage_throttled?)
                                                   .with(:test_limit, anything)
                                                   .and_return(false)
      end

      it 'returns true' do
        expect(resource_usage_limiter).to be_exceeded_limits
      end
    end

    context 'when no limit is throttled' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:resource_usage_throttled?)
                                                   .with(:test_limit_per_user, anything)
                                                   .and_return(false)
        allow(Gitlab::ApplicationRateLimiter).to receive(:resource_usage_throttled?)
                                                   .with(:test_limit, anything)
                                                   .and_return(false)
      end

      it 'returns false' do
        expect(resource_usage_limiter).not_to be_exceeded_limits
      end
    end

    context 'when scopes are missing' do
      before do
        allow(Gitlab::ApplicationContext).to receive(:current).and_return({})
      end

      it 'skips limit check' do
        expect(Gitlab::ApplicationRateLimiter)
          .to receive(:resource_usage_throttled?)
                .once
                .with(:test_limit, anything)

        exceeded_limits?
      end
    end
  end
end
