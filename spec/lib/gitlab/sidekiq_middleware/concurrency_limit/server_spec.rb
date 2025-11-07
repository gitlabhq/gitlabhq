# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::Server, feature_category: :global_search do
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

  let(:worker_class_without_concurrency_limit) do
    Class.new do
      def self.name
        'TestWithoutConcurrencyLimitWorker'
      end

      include ApplicationWorker

      def perform(*)
        self.class.work
      end

      def self.work; end
    end
  end

  let(:worker_klass) { TestConcurrencyLimitWorker }

  before do
    Thread.current[:sidekiq_capsule] = Sidekiq::Capsule.new('test', Sidekiq.default_configuration)
    stub_const('TestConcurrencyLimitWorker', worker_class)
    stub_const('TestWithoutConcurrencyLimitWorker', worker_class_without_concurrency_limit)
    stub_feature_flags(disable_sidekiq_concurrency_limit_middleware_TestConcurrencyLimitWorker: false)
    stub_feature_flags(disable_sidekiq_concurrency_limit_middleware_TestWithoutConcurrencyLimitWorker: false)
  end

  after do
    Thread.current[:sidekiq_capsule] = nil
  end

  around do |example|
    with_sidekiq_server_middleware do |chain|
      chain.add described_class
      Sidekiq::Testing.inline! { example.run }
    end
  end

  shared_examples 'track execution' do
    it do
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .to receive(:track_execution_start)
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .to receive(:track_execution_end)
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .to receive(:cleanup_stale_trackers)

      worker_klass.perform_async('foo')
    end
  end

  shared_examples 'skip execution tracking' do
    it do
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .not_to receive(:track_execution_start)
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .not_to receive(:track_execution_end)
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .not_to receive(:cleanup_stale_trackers)

      worker_klass.perform_async('foo')
    end
  end

  describe '#call' do
    context 'when sidekiq_concurrency_limit_middleware feature flag is disabled' do
      before do
        stub_feature_flags(sidekiq_concurrency_limit_middleware: false)
      end

      it 'executes the job' do
        expect(TestConcurrencyLimitWorker).to receive(:work)
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

        TestConcurrencyLimitWorker.perform_async('foo')
      end

      it_behaves_like 'skip execution tracking'
    end

    context 'when per worker feature flag is enabled' do
      before do
        stub_feature_flags(disable_sidekiq_concurrency_limit_middleware_TestConcurrencyLimitWorker: true)
      end

      it 'executes the job' do
        expect(TestConcurrencyLimitWorker).to receive(:work)
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

        TestConcurrencyLimitWorker.perform_async('foo')
      end

      it_behaves_like 'track execution'
    end

    context 'when there are jobs in the queue' do
      before do
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:has_jobs_in_queue?)
                                                                                           .and_return(true)
      end

      it 'defers the job' do
        expect(TestConcurrencyLimitWorker).not_to receive(:work)
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).to receive(:deferred_log).and_call_original
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:add_to_queue!)

        TestConcurrencyLimitWorker.perform_async('foo')
      end

      context 'when only the related_class is set in the context' do
        it 'defers the job' do
          expect(TestConcurrencyLimitWorker).not_to receive(:work)
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).to receive(:deferred_log).and_call_original
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:add_to_queue!)

          related_class = 'Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService'
          Gitlab::ApplicationContext.with_raw_context(related_class: related_class) do
            TestConcurrencyLimitWorker.perform_async('foo')
          end
        end
      end

      context 'when concurrency_limit_resume setter is used' do
        it 'executes the job if resumed' do
          expect(TestConcurrencyLimitWorker).to receive(:work)
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

          Gitlab::ApplicationContext.with_raw_context do
            TestConcurrencyLimitWorker.concurrency_limit_resume(Time.now.utc.tv_sec).perform_async('foo')
          end
        end
      end

      context 'when both related class and concurrency_limit_resume setter is used' do
        it 'executes the job if resumed' do
          expect(TestConcurrencyLimitWorker).to receive(:work)
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

          related_class = 'Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService'
          Gitlab::ApplicationContext.with_raw_context(related_class: related_class) do
            TestConcurrencyLimitWorker.concurrency_limit_resume(Time.now.utc.tv_sec).perform_async('foo')
          end
        end
      end
    end

    context 'when sidekiq_workers are stubbed' do
      before do
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:over_the_limit?)
                                                                                           .and_return(over_the_limit)
      end

      context 'when under the limit' do
        let(:over_the_limit) { false }

        it 'executes the job' do
          expect(TestConcurrencyLimitWorker).to receive(:work)
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

          TestConcurrencyLimitWorker.perform_async('foo')
        end

        it_behaves_like 'track execution'

        context 'when limit is set to zero' do
          before do
            allow_next_instance_of(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware) do |instance|
              allow(instance).to receive(:limit_for).and_return(0)
            end
          end

          it_behaves_like 'track execution'
        end

        context 'when limit is not defined' do
          it_behaves_like 'track execution'
        end
      end

      context 'when over the limit' do
        let(:over_the_limit) { true }

        it 'defers the job' do
          expect(TestConcurrencyLimitWorker).not_to receive(:work)
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).to receive(:deferred_log).and_call_original
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:add_to_queue!)

          TestConcurrencyLimitWorker.perform_async('foo')
        end
      end

      context 'when concurrency_limit_current_limit_from_redis FF is disabled' do
        before do
          stub_feature_flags(concurrency_limit_current_limit_from_redis: false)

          if over_the_limit
            allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
              .to receive(:concurrent_worker_count)
                    .with(TestConcurrencyLimitWorker.name)
                    .and_return(TestConcurrencyLimitWorker.get_concurrency_limit)
          end
        end

        context 'when under the limit' do
          let(:over_the_limit) { false }

          it 'executes the job' do
            expect(TestConcurrencyLimitWorker).to receive(:work)
            expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
            expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
              .not_to receive(:add_to_queue!)

            TestConcurrencyLimitWorker.perform_async('foo')
          end

          it_behaves_like 'track execution'

          context 'when limit is set to zero' do
            before do
              allow_next_instance_of(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware) do |instance|
                allow(instance).to receive(:limit_for).and_return(0)
              end
            end

            it_behaves_like 'track execution'
          end

          context 'when limit is not defined' do
            it_behaves_like 'track execution'
          end
        end

        context 'when over the limit' do
          let(:over_the_limit) { true }

          it 'defers the job' do
            expect(TestConcurrencyLimitWorker).not_to receive(:work)
            expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).to receive(:deferred_log)
                                                                                 .and_call_original
            expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:add_to_queue!)

            TestConcurrencyLimitWorker.perform_async('foo')
          end
        end
      end
    end

    context 'with worker class without concurrency limit' do
      let(:worker_klass) { TestWithoutConcurrencyLimitWorker }

      it 'executes the job' do
        expect(worker_klass).to receive(:work)
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

        worker_klass.perform_async('foo')
      end

      it_behaves_like 'track execution'
    end
  end
end
