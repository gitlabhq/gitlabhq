# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

RSpec.describe Gitlab::SidekiqMiddleware, feature_category: :shared do
  let(:job_args) { [0.01] }
  let(:disabled_sidekiq_middlewares) { [] }
  let(:chain) { Sidekiq::Middleware::Chain.new(Sidekiq) }
  let(:queue) { 'test' }
  let(:enabled_sidekiq_middlewares) { all_sidekiq_middlewares - disabled_sidekiq_middlewares }
  let(:worker_class) do
    Class.new do
      def self.name
        'TestWorker'
      end

      include ApplicationWorker

      def perform(*args)
        Gitlab::SafeRequestStore['gitaly_call_actual'] = 1
        Gitlab::SafeRequestStore[:gitaly_query_time] = 5
      end
    end
  end

  before do
    stub_const('TestWorker', worker_class)
  end

  shared_examples "a middleware chain" do
    before do
      configurator.call(chain)
      stub_feature_flags("drop_sidekiq_jobs_#{worker_class.name}": false) # not dropping the job
    end

    it "passes through the right middlewares", :aggregate_failures do
      enabled_sidekiq_middlewares.each do |middleware|
        expect_next_instances_of(middleware, 1, true) do |middleware_instance|
          expect(middleware_instance).to receive(:call).with(*middleware_expected_args).once.and_call_original
        end
      end

      expect { |b| chain.invoke(*worker_args, &b) }.to yield_control.once
    end
  end

  shared_examples "a middleware chain for mailer" do
    let(:worker_class) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper }

    it_behaves_like "a middleware chain"
  end

  describe 'Server.configurator' do
    let(:configurator) { described_class::Server.configurator }
    let(:worker_args) { [worker_class.new, { 'args' => job_args }, queue] }
    let(:middleware_expected_args) { [a_kind_of(worker_class), hash_including({ 'args' => job_args }), queue] }
    let(:all_sidekiq_middlewares) { ::Gitlab::SidekiqMiddleware::Server.middlewares }

    describe "server metrics" do
      around do |example|
        with_sidekiq_server_middleware do |chain|
          described_class::Server.configurator(
            metrics: true,
            arguments_logger: true,
            skip_jobs: false
          ).call(chain)

          Sidekiq::Testing.inline! { example.run }
        end
      end

      let(:gitaly_histogram) { double(:gitaly_histogram) }

      before do
        allow(Gitlab::Metrics).to receive(:histogram).and_call_original

        allow(Gitlab::Metrics).to receive(:histogram)
          .with(:sidekiq_jobs_gitaly_seconds, anything, anything, anything)
          .and_return(gitaly_histogram)
      end

      it "records correct Gitaly duration" do
        expect(gitaly_histogram).to receive(:observe).with(anything, 5.0)

        worker_class.perform_async(*job_args)
      end
    end

    context "all optional middlewares on" do
      it_behaves_like "a middleware chain"
      it_behaves_like "a middleware chain for mailer"
    end

    context "all optional middlewares off" do
      let(:configurator) do
        described_class::Server.configurator(
          metrics: false,
          arguments_logger: false,
          skip_jobs: false
        )
      end

      let(:disabled_sidekiq_middlewares) do
        [
          Gitlab::SidekiqMiddleware::ServerMetrics,
          Gitlab::SidekiqMiddleware::ArgumentsLogger,
          Gitlab::SidekiqMiddleware::SkipJobs
        ]
      end

      it_behaves_like "a middleware chain"
      it_behaves_like "a middleware chain for mailer"
    end

    context 'when a job is concurrency limited' do
      let(:concurrency_limit_middleware_index) do
        all_sidekiq_middlewares.index(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Server)
      end

      let(:disabled_sidekiq_middlewares) do
        # all middlewares after ConcurrencyLimit::Server
        all_sidekiq_middlewares[(concurrency_limit_middleware_index + 1)..]
      end

      before do
        configurator.call(chain)
        stub_feature_flags("drop_sidekiq_jobs_#{worker_class.name}": false) # not dropping the job
        stub_feature_flags("disable_sidekiq_concurrency_limit_middleware_#{worker_class.name}": false)

        # Apply concurrency limiting
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:has_jobs_in_queue?).and_return(true)
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:add_to_queue!)
      end

      it "passes through the right middlewares and clears idempotency key", :aggregate_failures do
        expect_next_instance_of(Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob) do |dj|
          expect(dj).to receive(:delete!).and_call_original
        end

        enabled_sidekiq_middlewares.each do |middleware|
          expect_next_instances_of(middleware, 1, true) do |middleware_instance|
            expect(middleware_instance).to receive(:call).with(*middleware_expected_args).once.and_call_original
          end
        end

        chain.invoke(*worker_args)
      end
    end

    context 'when REORDER_DUPLICATE_JOBS_AND_CONCURRENCY_LIMIT_MIDDLEWARE is true' do
      before do
        stub_env('REORDER_DUPLICATE_JOBS_AND_CONCURRENCY_LIMIT_MIDDLEWARE', 'true')
        configurator.call(chain)
      end

      it 'registers concurrency limit middleware before duplicate jobs middleware' do
        middlewares = chain.entries.map(&:klass)

        expect(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Server)
          .to come_before(::Gitlab::SidekiqMiddleware::DuplicateJobs::Server)
                .in(middlewares)
      end
    end
  end

  describe 'Client.configurator' do
    let(:configurator) { described_class::Client.configurator }
    let(:redis_pool) { Sidekiq.redis_pool }
    let(:middleware_expected_args) { [worker_class, hash_including({ 'args' => job_args }), queue, redis_pool] }
    let(:worker_args) { [worker_class, { 'args' => job_args }, queue, redis_pool] }
    let(:all_sidekiq_middlewares) { ::Gitlab::SidekiqMiddleware::Client.middlewares }

    it_behaves_like "a middleware chain"
    it_behaves_like "a middleware chain for mailer"

    context 'when REORDER_DUPLICATE_JOBS_AND_CONCURRENCY_LIMIT_MIDDLEWARE is true' do
      before do
        stub_env('REORDER_DUPLICATE_JOBS_AND_CONCURRENCY_LIMIT_MIDDLEWARE', 'true')
        configurator.call(chain)
      end

      it 'registers duplicate jobs middleware before concurrency limit middleware' do
        middlewares = chain.entries.map(&:klass)

        expect(::Gitlab::SidekiqMiddleware::DuplicateJobs::Client)
          .to come_before(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Client)
                .in(middlewares)
      end
    end
  end

  context 'in between DuplicateJobs::Client and DuplicateJobs::Server' do
    # Everything from DuplicateJobs::Client to DuplicateJobs::Server must yield
    # no returning or job interception as it will leave the duplicate job redis key
    # dangling and erroneously deduplicating future jobs until key expires.
    #
    # If a new middleware is added in between
    # DuplicateJobs::Client and DuplicateJobs::Server, please adjust
    # allowed_middlewares below accordingly.
    let(:allowed_middlewares_after_duplicate_jobs_client) do
      [
        ::Gitlab::SidekiqStatus::ClientMiddleware,
        ::Gitlab::SidekiqMiddleware::AdminMode::Client,
        ::Gitlab::SidekiqMiddleware::SizeLimiter::Client,
        ::Gitlab::SidekiqMiddleware::ClientMetrics,
        ::Gitlab::SidekiqMiddleware::Identity::Passthrough
      ]
    end

    let(:allowed_middlewares_before_duplicate_jobs_server) do
      [
        ::Gitlab::SidekiqMiddleware::SizeLimiter::Server,
        ::Gitlab::SidekiqMiddleware::ShardAwarenessValidator,
        ::Gitlab::SidekiqMiddleware::Monitor,
        ::Labkit::Middleware::Sidekiq::Server,
        ::Gitlab::SidekiqMiddleware::RequestStoreMiddleware,
        ::Gitlab::QueryLimiting::SidekiqMiddleware,
        ::Gitlab::SidekiqMiddleware::ServerMetrics,
        ::Gitlab::SidekiqMiddleware::ArgumentsLogger,
        ::Gitlab::SidekiqMiddleware::ExtraDoneLogMetadata,
        ::Gitlab::SidekiqMiddleware::BatchLoader,
        ::Gitlab::SidekiqMiddleware::InstrumentationLogger,
        ::Gitlab::SidekiqMiddleware::SetIpAddress,
        ::Gitlab::SidekiqMiddleware::AdminMode::Server,
        ::Gitlab::SidekiqMiddleware::QueryAnalyzer,
        ::Gitlab::SidekiqVersioning::Middleware,
        ::Gitlab::SidekiqStatus::ServerMiddleware,
        ::Gitlab::SidekiqMiddleware::WorkerContext::Server,
        ::ClickHouse::MigrationSupport::SidekiqMiddleware
      ]
    end

    shared_examples 'a middleware chain not intercepting job' do
      it 'must not have any middleware intercepting job' do
        expect { |b| chain.invoke(*worker_args, &b) }.to yield_control.once
      end
    end

    context 'after DuplicateJobs::Client' do
      before do
        allow(described_class::Client).to receive(:middlewares).and_return(middlewares_after_duplicate_jobs_client)
        configurator.call(chain)
      end

      let(:configurator) { described_class::Client.configurator }
      let(:redis_pool) { Sidekiq.redis_pool }
      let(:worker_args) { [worker_class, { 'args' => job_args }, queue, redis_pool] }
      let(:client_middlewares) { described_class::Client.middlewares }
      let(:duplicate_jobs_client_middleware_index) do
        client_middlewares.index(::Gitlab::SidekiqMiddleware::DuplicateJobs::Client)
      end

      let(:middlewares_after_duplicate_jobs_client) do
        client_middlewares[(duplicate_jobs_client_middleware_index + 1)..]
      end

      it_behaves_like 'a middleware chain not intercepting job'
      it 'only contains allowed middlewares' do
        expect(middlewares_after_duplicate_jobs_client).to contain_sidekiq_middlewares_exactly(
          allowed_middlewares_after_duplicate_jobs_client)
      end
    end

    context 'before DuplicateJobs::Server' do
      before do
        allow(described_class::Server).to receive(:middlewares).and_return(middlewares_before_duplicate_jobs_server)
        configurator.call(chain)
      end

      let(:configurator) { described_class::Server.configurator }
      let(:worker_args) { [worker_class.new, { 'args' => job_args }, queue] }
      let(:server_middlewares) { described_class::Server.middlewares }
      let(:duplicate_jobs_server_middleware_index) do
        server_middlewares.index(::Gitlab::SidekiqMiddleware::DuplicateJobs::Server)
      end

      let(:middlewares_before_duplicate_jobs_server) do
        server_middlewares[0..(duplicate_jobs_server_middleware_index - 1)]
      end

      it_behaves_like 'a middleware chain not intercepting job'
      it 'only contains allowed middlewares' do
        expect(middlewares_before_duplicate_jobs_server).to contain_sidekiq_middlewares_exactly(
          allowed_middlewares_before_duplicate_jobs_server)
      end
    end
  end

  describe 'Client.middlewares' do
    let(:middlewares) { described_class::Client.middlewares }

    context 'ConcurrencyLimit::Resume' do
      it 'is placed first' do
        expect(middlewares.first).to eq(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Resume)
      end
    end

    context 'WorkerContext::Client' do
      it 'comes before Labkit middleware' do
        expect(::Gitlab::SidekiqMiddleware::WorkerContext::Client)
          .to come_before(::Labkit::Middleware::Sidekiq::Client)
          .in(middlewares)
      end
    end

    context 'Gitlab::Database::LoadBalancing::SidekiqClientMiddleware' do
      it 'comes before DuplicateJobs::Client' do
        expect(::Gitlab::Database::LoadBalancing::SidekiqClientMiddleware)
          .to come_before(::Gitlab::SidekiqMiddleware::DuplicateJobs::Client)
          .in(middlewares)
      end
    end

    context 'SizeLimiter::Client' do
      it 'comes before ClientMetrics' do
        expect(::Gitlab::SidekiqMiddleware::SizeLimiter::Client)
          .to come_before(::Gitlab::SidekiqMiddleware::ClientMetrics)
          .in(middlewares)
      end
    end
  end

  describe 'Server.middlewares' do
    let(:middlewares) { described_class::Server.middlewares }

    context 'SizeLimiter::Server' do
      it 'is placed first' do
        expect(middlewares.first).to eq(::Gitlab::SidekiqMiddleware::SizeLimiter::Server)
      end
    end

    context 'Labkit::Middleware::Sidekiq::Server' do
      it 'comes before ServerMetrics' do
        expect(::Labkit::Middleware::Sidekiq::Server)
          .to come_before(::Gitlab::SidekiqMiddleware::ServerMetrics)
          .in(middlewares)
      end
    end

    context 'DuplicateJobs::Server' do
      it 'comes before Gitlab::Database::LoadBalancing::SidekiqServerMiddleware' do
        expect(::Gitlab::SidekiqMiddleware::DuplicateJobs::Server)
          .to come_before(::Gitlab::Database::LoadBalancing::SidekiqServerMiddleware)
          .in(middlewares)
      end
    end

    context 'PauseControl::Server' do
      it 'does not come before DuplicateJobs::Server' do
        expect(::Gitlab::SidekiqMiddleware::PauseControl::Server)
          .not_to come_before(::Gitlab::SidekiqMiddleware::DuplicateJobs::Server)
                .in(middlewares)
      end
    end
  end
end
