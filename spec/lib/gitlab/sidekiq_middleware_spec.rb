# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe Gitlab::SidekiqMiddleware do
  class TestWorker
    include Sidekiq::Worker

    def perform(_arg)
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
      original = Sidekiq::Testing.server_middleware.dup

      example.run

      Sidekiq::Testing.instance_variable_set :@server_chain, original
    end

    let(:middleware_expected_args) { [a_kind_of(worker_class), hash_including({ 'args' => job_args }), anything] }
    let(:all_sidekiq_middlewares) do
      [
       Gitlab::SidekiqMiddleware::Monitor,
       Gitlab::SidekiqMiddleware::BatchLoader,
       Labkit::Middleware::Sidekiq::Server,
       Gitlab::SidekiqMiddleware::InstrumentationLogger,
       Gitlab::SidekiqStatus::ServerMiddleware,
       Gitlab::SidekiqMiddleware::Metrics,
       Gitlab::SidekiqMiddleware::ArgumentsLogger,
       Gitlab::SidekiqMiddleware::MemoryKiller,
       Gitlab::SidekiqMiddleware::RequestStoreMiddleware
      ]
    end
    let(:enabled_sidekiq_middlewares) { all_sidekiq_middlewares - disabled_sidekiq_middlewares }

    before do
      Sidekiq::Testing.server_middleware.clear
      Sidekiq::Testing.server_middleware(&described_class.server_configurator(
        metrics: metrics,
        arguments_logger: arguments_logger,
        memory_killer: memory_killer,
        request_store: request_store
      ))

      enabled_sidekiq_middlewares.each do |middleware|
        expect_any_instance_of(middleware).to receive(:call).with(*middleware_expected_args).once.and_call_original
      end

      disabled_sidekiq_middlewares.each do |middleware|
        expect_any_instance_of(Gitlab::SidekiqMiddleware::ArgumentsLogger).not_to receive(:call)
      end
    end

    context "all optional middlewares off" do
      let(:metrics) { false }
      let(:arguments_logger) { false }
      let(:memory_killer) { false }
      let(:request_store) { false }
      let(:disabled_sidekiq_middlewares) do
        [
          Gitlab::SidekiqMiddleware::Metrics,
          Gitlab::SidekiqMiddleware::ArgumentsLogger,
          Gitlab::SidekiqMiddleware::MemoryKiller,
          Gitlab::SidekiqMiddleware::RequestStoreMiddleware
        ]
      end

      it "passes through server middlewares" do
        worker_class.perform_async(*job_args)
      end
    end

    context "all optional middlewares on" do
      let(:metrics) { true }
      let(:arguments_logger) { true }
      let(:memory_killer) { true }
      let(:request_store) { true }
      let(:disabled_sidekiq_middlewares) { [] }

      it "passes through server middlewares" do
        worker_class.perform_async(*job_args)
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

    before do
      described_class.client_configurator.call(chain)
    end

    shared_examples "a client middleware chain" do
      # Its possible that a middleware could accidentally omit a yield call
      # this will prevent the full middleware chain from being executed.
      # This test ensures that this does not happen
      it "invokes the chain" do
        expect_any_instance_of(Gitlab::SidekiqStatus::ClientMiddleware).to receive(:call).with(*middleware_expected_args).once.and_call_original
        expect_any_instance_of(Labkit::Middleware::Sidekiq::Client).to receive(:call).with(*middleware_expected_args).once.and_call_original

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
