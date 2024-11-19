# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap, feature_category: :global_search do
  using RSpec::Parameterized::TableSyntax

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
      expect(described_class.limit_for(worker: worker_class.new)).to eq(expected_limit)
    end

    it 'accepts worker class' do
      expect(described_class.limit_for(worker: worker_class)).to eq(expected_limit)
    end

    it 'returns 0 for unknown worker' do
      expect(described_class.limit_for(worker: described_class)).to eq(0)
    end

    it 'returns 0 if the feature flag is disabled' do
      stub_feature_flags(sidekiq_concurrency_limit_middleware: false)

      expect(described_class.limit_for(worker: worker_class)).to eq(0)
    end
  end

  describe '.over_the_limit?' do
    subject(:over_the_limit?) { described_class.over_the_limit?(worker: worker_class) }

    where(:limit, :current, :result) do
      0   | 0   | false
      0   | 10  | false
      5   | 10  | true
      10  | 0   | false
      10  | 5   | false
      -1  | 0   | true
      -1  | 1   | true
      -10 | 10  | true
    end

    with_them do
      before do
        allow(described_class).to receive(:limit_for).and_return(limit)
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:concurrent_worker_count)
          .and_return(current)
      end

      it 'returns correct result' do
        expect(over_the_limit?).to eq(result)
      end
    end
  end

  describe '.workers' do
    subject(:workers) { described_class.workers }

    it 'includes the worker' do
      expect(workers).to include(worker_class)
    end
  end
end
