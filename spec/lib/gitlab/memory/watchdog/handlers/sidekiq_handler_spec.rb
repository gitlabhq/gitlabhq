# frozen_string_literal: true

require 'fast_spec_helper'
require 'sidekiq'

RSpec.describe Gitlab::Memory::Watchdog::Handlers::SidekiqHandler, feature_category: :cloud_connector do
  let(:sleep_time) { 3 }
  let(:shutdown_timeout_seconds) { 30 }
  let(:handler_iterations) { 0 }
  let(:logger) { instance_double(::Logger) }
  let(:pid) { $$ }

  before do
    allow(Gitlab::Metrics::System).to receive(:monotonic_time)
      .and_return(0, 1, shutdown_timeout_seconds, 0, 1, Sidekiq.default_configuration[:timeout] + 2)
    allow(Process).to receive(:kill)
    allow(::Sidekiq).to receive(:logger).and_return(logger)
    allow(logger).to receive(:warn)
    allow(Process).to receive(:getpgrp).and_return(pid)
  end

  subject(:handler) do
    described_class.new(shutdown_timeout_seconds, sleep_time).tap do |instance|
      # We need to defuse `sleep` and stop the  handler after n iteration
      iterations = 0
      allow(instance).to receive(:sleep) do
        if (iterations += 1) > handler_iterations
          instance.stop
        end
      end
    end
  end

  describe '#call' do
    shared_examples_for 'handler issues kill command' do
      it 'logs sending signal' do
        logs.each do |log|
          expect(::Sidekiq.logger).to receive(:warn).once.ordered.with(log)
        end

        handler.call
      end

      it 'sends TERM to the current process' do
        signal_params.each do |args|
          expect(Process).to receive(:kill).once.ordered.with(*args.first(2))
        end

        expect(handler.call).to be(true)
      end
    end

    def log(signal, pid, explanation, wait_time = nil)
      {
        pid: pid,
        worker_id: ::Prometheus::PidProvider.worker_id,
        memwd_handler_class: described_class.to_s,
        memwd_signal: signal,
        memwd_explanation: explanation,
        memwd_wait_time: wait_time,
        message: "Sending signal and waiting"
      }
    end

    let(:logs) do
      signal_params.map { |args| log(*args) }
    end

    context "when stop is received after TSTP" do
      let(:signal_params) do
        [
          [:TSTP, pid, 'stop fetching new jobs', shutdown_timeout_seconds]
        ]
      end

      it_behaves_like 'handler issues kill command'
    end

    context "when stop is received after TERM" do
      let(:handler_iterations) { 1 }
      let(:signal_params) do
        [
          [:TSTP, pid, 'stop fetching new jobs', shutdown_timeout_seconds],
          [:TERM, pid, 'gracefully shut down', Sidekiq.default_configuration[:timeout] + 2]
        ]
      end

      it_behaves_like 'handler issues kill command'
    end

    context "when stop is not received" do
      let(:handler_iterations) { 2 }
      let(:gpid) { pid + 1 }
      let(:kill_pid) { pid }
      let(:signal_params) do
        [
          [:TSTP, pid, 'stop fetching new jobs', shutdown_timeout_seconds],
          [:TERM, pid, 'gracefully shut down', Sidekiq.default_configuration[:timeout] + 2],
          [:KILL, kill_pid, 'hard shut down', nil]
        ]
      end

      before do
        allow(Process).to receive(:getpgrp).and_return(gpid)
      end

      context 'when process is not group leader' do
        it_behaves_like 'handler issues kill command'
      end

      context 'when process is a group leader' do
        let(:gpid) { pid }
        let(:kill_pid) { 0 }

        it_behaves_like 'handler issues kill command'
      end
    end
  end
end
