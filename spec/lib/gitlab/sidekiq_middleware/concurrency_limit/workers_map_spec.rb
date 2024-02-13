# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestConcurrencyLimitWorker'
      end

      include ApplicationWorker

      concurrency_limit -> { 60 }

      def perform(*); end
    end
  end

  before do
    stub_const('TestConcurrencyLimitWorker', worker_class)
  end

  describe '.limit_for' do
    let(:expected_limit) { 60 }

    it 'accepts worker instance' do
      expect(described_class.limit_for(worker: worker_class.new).call).to eq(expected_limit)
    end

    it 'accepts worker class' do
      expect(described_class.limit_for(worker: worker_class).call).to eq(expected_limit)
    end

    it 'returns nil for unknown worker' do
      expect(described_class.limit_for(worker: described_class)).to be_nil
    end

    it 'returns nil if the feature flag is disabled' do
      stub_feature_flags(sidekiq_concurrency_limit_middleware: false)

      expect(described_class.limit_for(worker: worker_class)).to be_nil
    end
  end

  describe '.over_the_limit?' do
    subject(:over_the_limit?) { described_class.over_the_limit?(worker: worker_class) }

    it 'returns false if no limit is set' do
      expect(described_class).to receive(:limit_for).and_return(nil)

      expect(over_the_limit?).to be_falsey
    end

    it 'returns false if under the limit' do
      allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersConcurrency).to receive(:current_for).and_return(50)

      expect(over_the_limit?).to be_falsey
    end

    it 'returns true if over the limit' do
      allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersConcurrency).to receive(:current_for).and_return(100)

      expect(over_the_limit?).to be_truthy
    end
  end

  describe '.workers' do
    subject(:workers) { described_class.workers }

    it 'includes the worker' do
      expect(workers).to include(worker_class)
    end
  end
end
