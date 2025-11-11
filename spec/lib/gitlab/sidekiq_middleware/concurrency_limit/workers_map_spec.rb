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
    context 'with concurrency_limit attribute defined' do
      let(:expected_limit) { 60 }

      it 'accepts worker instance and return defined limit' do
        expect(described_class.limit_for(worker: worker_class.new)).to eq(expected_limit)
      end

      it 'accepts worker class and return defined limit' do
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

    context 'when concurrency_limit is set to 0' do
      before do
        worker_class.class_eval do
          concurrency_limit -> { 0 }
        end
      end

      it 'returns 0' do
        expect(described_class.limit_for(worker: worker_class)).to eq(0)
      end
    end

    context 'with concurrency_limit and max_concurrency_limit_percentage attributes defined' do
      let(:expected_limit) { 60 }

      before do
        worker_class.class_eval do
          max_concurrency_limit_percentage 0.5
        end
      end

      it 'returns the concurrency_limit value' do
        expect(described_class.limit_for(worker: worker_class)).to eq(expected_limit)
      end
    end

    context 'for worker class without concurrency_limit attribute' do
      using RSpec::Parameterized::TableSyntax

      let(:worker_class) do
        Class.new do
          def self.name
            'Gitlab::Foo::Bar::DummyWorker'
          end

          include ApplicationWorker
        end
      end

      where(:urgency, :sidekiq_max_replicas, :sidekiq_concurrency, :expected_concurrency_limit) do
        :high      | 10 | 10 | 35
        :high      | 0  | 10 | 0
        :high      | 10 | 0  | 0
        :high      | 0  | 0  | 0
        :low       | 10 | 10 | 25
        :low       | 0  | 10 | 0
        :low       | 10 | 0  | 0
        :low       | 0  | 0  | 0
        :throttled | 10 | 10 | 15
        :throttled | 0  | 10 | 0
        :throttled | 10 | 0  | 0
        :throttled | 0  | 0  | 0
      end

      with_them do
        before do
          worker_class.urgency urgency
          stub_env("GITLAB_SIDEKIQ_MAX_REPLICAS", sidekiq_max_replicas)
          stub_env("SIDEKIQ_CONCURRENCY", sidekiq_concurrency)
        end

        it 'returns expected limit' do
          expect(described_class.limit_for(worker: worker_class)).to eq(expected_concurrency_limit)
        end
      end

      context 'with max_concurrency_limit_percentage attribute' do
        let(:worker_class) do
          Class.new do
            def self.name
              'Gitlab::Foo::Bar::DummyWorker'
            end

            include ApplicationWorker
            max_concurrency_limit_percentage 0.4
          end
        end

        before do
          stub_env("GITLAB_SIDEKIQ_MAX_REPLICAS", 10)
          stub_env("SIDEKIQ_CONCURRENCY", 10)
        end

        it 'returns expected limit' do
          expect(described_class.limit_for(worker: worker_class)).to eq(40)
        end
      end

      context 'with only SIDEKIQ_CONCURRENCY environment variable defined' do
        before do
          stub_env("SIDEKIQ_CONCURRENCY", 10)
        end

        it 'returns 0' do
          expect(described_class.limit_for(worker: worker_class)).to eq(0)
        end
      end

      context 'with only GITLAB_SIDEKIQ_MAX_REPLICAS environment variable defined' do
        before do
          stub_env("GITLAB_SIDEKIQ_MAX_REPLICAS", 10)
        end

        it 'returns 0' do
          expect(described_class.limit_for(worker: worker_class)).to eq(0)
        end
      end
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
