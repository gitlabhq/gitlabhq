# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe Gitlab::SidekiqMiddleware do
  before do
    stub_const('TestWorker', Class.new)

    TestWorker.class_eval do
      include Sidekiq::Worker
      include ApplicationWorker

      def perform(_arg)
        Gitlab::SafeRequestStore['gitaly_call_actual'] = 1
        Gitlab::SafeRequestStore[:gitaly_query_time] = 5
      end
    end
  end

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  let(:worker_class) { TestWorker }
  let(:job_args) { [0.01] }

  # The test sets up a new server middleware stack, ensuring that the
  # appropriate middlewares, as passed into server_configurator,
  # are invoked.
  # Additionally the test ensure that each middleware is
  # 1) not failing
  # 2) yielding exactly once
  describe '.server_configurator' do
    around do |example|
      with_sidekiq_server_middleware do |chain|
        described_class.server_configurator(
          metrics: metrics,
          arguments_logger: arguments_logger,
          memory_killer: memory_killer
        ).call(chain)

        example.run
      end
    end

    let(:middleware_expected_args) { [a_kind_of(worker_class), hash_including({ 'args' => job_args }), anything] }
    let(:all_sidekiq_middlewares) do
      [
       Gitlab::SidekiqMiddleware::Monitor,
       Gitlab::SidekiqMiddleware::BatchLoader,
       Labkit::Middleware::Sidekiq::Server,
       Gitlab::SidekiqMiddleware::InstrumentationLogger,
       Gitlab::SidekiqStatus::ServerMiddleware,
       Gitlab::SidekiqMiddleware::ServerMetrics,
       Gitlab::SidekiqMiddleware::ArgumentsLogger,
       Gitlab::SidekiqMiddleware::MemoryKiller,
       Gitlab::SidekiqMiddleware::RequestStoreMiddleware,
       Gitlab::SidekiqMiddleware::ExtraDoneLogMetadata,
       Gitlab::SidekiqMiddleware::WorkerContext::Server,
       Gitlab::SidekiqMiddleware::AdminMode::Server,
       Gitlab::SidekiqMiddleware::DuplicateJobs::Server
      ]
    end
    let(:enabled_sidekiq_middlewares) { all_sidekiq_middlewares - disabled_sidekiq_middlewares }

    shared_examples "a server middleware chain" do
      it "passes through the right server middlewares" do
        enabled_sidekiq_middlewares.each do |middleware|
          expect_any_instance_of(middleware).to receive(:call).with(*middleware_expected_args).once.and_call_original
        end

        disabled_sidekiq_middlewares.each do |middleware|
          expect_any_instance_of(middleware).not_to receive(:call)
        end

        worker_class.perform_async(*job_args)
      end
    end

    context "all optional middlewares off" do
      let(:metrics) { false }
      let(:arguments_logger) { false }
      let(:memory_killer) { false }
      let(:disabled_sidekiq_middlewares) do
        [
          Gitlab::SidekiqMiddleware::ServerMetrics,
          Gitlab::SidekiqMiddleware::ArgumentsLogger,
          Gitlab::SidekiqMiddleware::MemoryKiller
        ]
      end

      it_behaves_like "a server middleware chain"
    end

    context "all optional middlewares on" do
      let(:metrics) { true }
      let(:arguments_logger) { true }
      let(:memory_killer) { true }
      let(:disabled_sidekiq_middlewares) { [] }

      it_behaves_like "a server middleware chain"

      context "server metrics" do
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
    end
  end

  # The test sets up a new client middleware stack. The test ensures
  # that each middleware is:
  # 1) not failing
  # 2) yielding exactly once
  describe '.client_configurator' do
    let(:chain) { Sidekiq::Middleware::Chain.new }
    let(:job) { { 'args' => job_args } }
    let(:queue) { 'default' }
    let(:redis_pool) { Sidekiq.redis_pool }
    let(:middleware_expected_args) { [worker_class_arg, job, queue, redis_pool] }
    let(:expected_middlewares) do
      [
         ::Gitlab::SidekiqMiddleware::WorkerContext::Client,
         ::Labkit::Middleware::Sidekiq::Client,
         ::Gitlab::SidekiqMiddleware::DuplicateJobs::Client,
         ::Gitlab::SidekiqStatus::ClientMiddleware,
         ::Gitlab::SidekiqMiddleware::AdminMode::Client,
         ::Gitlab::SidekiqMiddleware::ClientMetrics
      ]
    end

    before do
      described_class.client_configurator.call(chain)
    end

    shared_examples "a client middleware chain" do
      # Its possible that a middleware could accidentally omit a yield call
      # this will prevent the full middleware chain from being executed.
      # This test ensures that this does not happen
      it "invokes the chain" do
        expected_middlewares do |middleware|
          expect_any_instance_of(middleware).to receive(:call).with(*middleware_expected_args).once.ordered.and_call_original
        end

        expect { |b| chain.invoke(worker_class_arg, job, queue, redis_pool, &b) }.to yield_control.once
      end
    end

    # Sidekiq documentation states that the worker class could be a string
    # or a class reference. We should test for both
    context "handles string worker_class values" do
      let(:worker_class_arg) { worker_class.to_s }

      it_behaves_like "a client middleware chain"
    end

    context "handles string worker_class values" do
      let(:worker_class_arg) { worker_class }

      it_behaves_like "a client middleware chain"
    end
  end
end
