# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::Client, :clean_gitlab_redis_queues, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestConcurrencyLimitWorker'
      end

      include ApplicationWorker

      concurrency_limit -> { 5 }

      def perform(*)
        self.class.work
      end

      def self.work; end
    end
  end

  before do
    stub_const('TestConcurrencyLimitWorker', worker_class)
  end

  describe '#call' do
    shared_examples 'defers or schedules the job' do
      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(sidekiq_concurrency_limit_middleware: false)
        end

        it 'schedules the job' do
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

          TestConcurrencyLimitWorker.perform_async('foo')

          expect(TestConcurrencyLimitWorker.jobs.size).to eq(1)
        end
      end

      context 'when there are jobs in the queue' do
        before do
          allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:has_jobs_in_queue?)
                                                                                             .and_return(true)
        end

        it 'defers the job' do
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:add_to_queue!).once

          TestConcurrencyLimitWorker.perform_async('foo')

          expect(TestConcurrencyLimitWorker.jobs.size).to eq(0)
        end

        it 'does not defer scheduled jobs' do
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

          TestConcurrencyLimitWorker.perform_in(10, 'foo')
        end
      end
    end

    context 'when sidekiq_concurrency_limit_middleware_v2 feature flag is disabled' do
      before do
        stub_feature_flags(sidekiq_concurrency_limit_middleware_v2: false)
      end

      context 'for calling the right middleware' do
        let(:middleware_instance) { instance_double(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware) }

        before do
          allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware)
            .to receive(:new).with(Object, kind_of(Hash)).and_return(middleware_instance)
        end

        it 'calls Middleware#schedule' do
          expect(middleware_instance).to receive(:schedule)

          TestConcurrencyLimitWorker.perform_async('foo')
        end
      end

      it_behaves_like 'defers or schedules the job'
    end

    context 'when sidekiq_concurrency_limit_middleware_v2 feature flag is enabled' do
      context 'for calling the right middleware' do
        let(:middleware_instance) { instance_double(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::MiddlewareV2) }

        before do
          allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::MiddlewareV2)
            .to receive(:new).with(TestConcurrencyLimitWorker, kind_of(Hash)).and_return(middleware_instance)
        end

        it 'calls MiddlewareV2#schedule' do
          expect(middleware_instance).to receive(:schedule)

          TestConcurrencyLimitWorker.perform_async('foo')
        end
      end

      it_behaves_like 'defers or schedules the job'
    end
  end
end
