# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

RSpec.describe Gitlab::SidekiqMiddleware do
  let(:job_args) { [0.01] }
  let(:disabled_sidekiq_middlewares) { [] }
  let(:chain) { Sidekiq::Middleware::Chain.new }
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

  shared_examples "a middleware chain" do |load_balancing_enabled|
    before do
      allow(::Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(load_balancing_enabled)
      configurator.call(chain)
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

  shared_examples "a middleware chain for mailer" do |load_balancing_enabled|
    let(:worker_class) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper }

    it_behaves_like "a middleware chain", load_balancing_enabled
  end

  describe '.server_configurator' do
    let(:configurator) { described_class.server_configurator }
    let(:worker_args) { [worker_class.new, { 'args' => job_args }, queue] }
    let(:middleware_expected_args) { [a_kind_of(worker_class), hash_including({ 'args' => job_args }), queue] }
    let(:all_sidekiq_middlewares) do
      [
        ::Gitlab::SidekiqMiddleware::Monitor,
        ::Gitlab::SidekiqMiddleware::ServerMetrics,
        ::Gitlab::SidekiqMiddleware::ArgumentsLogger,
        ::Gitlab::SidekiqMiddleware::MemoryKiller,
        ::Gitlab::SidekiqMiddleware::RequestStoreMiddleware,
        ::Gitlab::SidekiqMiddleware::ExtraDoneLogMetadata,
        ::Gitlab::SidekiqMiddleware::BatchLoader,
        ::Labkit::Middleware::Sidekiq::Server,
        ::Gitlab::SidekiqMiddleware::InstrumentationLogger,
        ::Gitlab::Database::LoadBalancing::SidekiqServerMiddleware,
        ::Gitlab::SidekiqMiddleware::AdminMode::Server,
        ::Gitlab::SidekiqVersioning::Middleware,
        ::Gitlab::SidekiqStatus::ServerMiddleware,
        ::Gitlab::SidekiqMiddleware::WorkerContext::Server,
        ::Gitlab::SidekiqMiddleware::DuplicateJobs::Server
      ]
    end

    describe "server metrics" do
      around do |example|
        with_sidekiq_server_middleware do |chain|
          described_class.server_configurator(
            metrics: true,
            arguments_logger: true,
            memory_killer: true
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
      context "when load balancing is enabled" do
        before do
          allow(::Gitlab::Database::LoadBalancing).to receive_message_chain(:proxy, :load_balancer, :release_host)
        end

        it_behaves_like "a middleware chain", true
        it_behaves_like "a middleware chain for mailer", true
      end

      context "when load balancing is disabled" do
        let(:disabled_sidekiq_middlewares) do
          [
            Gitlab::Database::LoadBalancing::SidekiqServerMiddleware
          ]
        end

        it_behaves_like "a middleware chain", false
        it_behaves_like "a middleware chain for mailer", false
      end
    end

    context "all optional middlewares off" do
      let(:configurator) do
        described_class.server_configurator(
          metrics: false,
          arguments_logger: false,
          memory_killer: false
        )
      end

      context "when load balancing is enabled" do
        let(:disabled_sidekiq_middlewares) do
          [
            Gitlab::SidekiqMiddleware::ServerMetrics,
            Gitlab::SidekiqMiddleware::ArgumentsLogger,
            Gitlab::SidekiqMiddleware::MemoryKiller
          ]
        end

        before do
          allow(::Gitlab::Database::LoadBalancing).to receive_message_chain(:proxy, :load_balancer, :release_host)
        end

        it_behaves_like "a middleware chain", true
        it_behaves_like "a middleware chain for mailer", true
      end

      context "when load balancing is disabled" do
        let(:disabled_sidekiq_middlewares) do
          [
            Gitlab::SidekiqMiddleware::ServerMetrics,
            Gitlab::SidekiqMiddleware::ArgumentsLogger,
            Gitlab::SidekiqMiddleware::MemoryKiller,
            Gitlab::Database::LoadBalancing::SidekiqServerMiddleware
          ]
        end

        it_behaves_like "a middleware chain", false
        it_behaves_like "a middleware chain for mailer", false
      end
    end
  end

  describe '.client_configurator' do
    let(:configurator) { described_class.client_configurator }
    let(:redis_pool) { Sidekiq.redis_pool }
    let(:middleware_expected_args) { [worker_class, hash_including({ 'args' => job_args }), queue, redis_pool] }
    let(:worker_args) { [worker_class, { 'args' => job_args }, queue, redis_pool] }
    let(:all_sidekiq_middlewares) do
      [
        ::Gitlab::SidekiqMiddleware::WorkerContext::Client,
        ::Labkit::Middleware::Sidekiq::Client,
        ::Gitlab::SidekiqMiddleware::DuplicateJobs::Client,
        ::Gitlab::SidekiqStatus::ClientMiddleware,
        ::Gitlab::SidekiqMiddleware::AdminMode::Client,
        ::Gitlab::SidekiqMiddleware::SizeLimiter::Client,
        ::Gitlab::SidekiqMiddleware::ClientMetrics,
        ::Gitlab::Database::LoadBalancing::SidekiqClientMiddleware
      ]
    end

    context "when load balancing is disabled" do
      let(:disabled_sidekiq_middlewares) do
        [
          Gitlab::Database::LoadBalancing::SidekiqClientMiddleware
        ]
      end

      it_behaves_like "a middleware chain", false
      it_behaves_like "a middleware chain for mailer", false

      # Sidekiq documentation states that the worker class could be a string
      # or a class reference. We should test for both
      context "worker_class as string value" do
        let(:worker_args) { [worker_class.to_s, { 'args' => job_args }, queue, redis_pool] }
        let(:middleware_expected_args) { [worker_class.to_s, hash_including({ 'args' => job_args }), queue, redis_pool] }

        it_behaves_like "a middleware chain", false
        it_behaves_like "a middleware chain for mailer", false
      end
    end

    context "when load balancing is enabled" do
      it_behaves_like "a middleware chain", true
      it_behaves_like "a middleware chain for mailer", true
    end
  end
end
