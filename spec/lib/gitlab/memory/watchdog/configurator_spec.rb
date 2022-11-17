# frozen_string_literal: true

require 'fast_spec_helper'
require 'prometheus/client'
require 'sidekiq'
require_dependency 'gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog::Configurator do
  shared_examples 'as configurator' do |handler_class, sleep_time_env, sleep_time|
    it 'configures the correct handler' do
      configurator.call(configuration)

      expect(configuration.handler).to be_an_instance_of(handler_class)
    end

    it 'configures the correct logger' do
      configurator.call(configuration)

      expect(configuration.logger).to eq(logger)
    end

    context 'when sleep_time_seconds is not passed through the environment' do
      let(:sleep_time_seconds) { sleep_time }

      it 'configures the correct sleep time' do
        configurator.call(configuration)

        expect(configuration.sleep_time_seconds).to eq(sleep_time_seconds)
      end
    end

    context 'when sleep_time_seconds is passed through the environment' do
      let(:sleep_time_seconds) { sleep_time - 1 }

      before do
        stub_env(sleep_time_env, sleep_time - 1)
      end

      it 'configures the correct sleep time' do
        configurator.call(configuration)

        expect(configuration.sleep_time_seconds).to eq(sleep_time_seconds)
      end
    end
  end

  shared_examples 'as monitor configurator' do
    it 'executes monitors and returns correct results' do
      configurator.call(configuration)

      payloads = {}
      configuration.monitors.call_each do |result|
        payloads[result.monitor_name] = result.payload
      end

      expect(payloads).to eq(expected_payloads)
    end
  end

  let(:configuration) { Gitlab::Memory::Watchdog::Configuration.new }

  # In tests, the Puma constant does not exist so we cannot use a verified double.
  # rubocop: disable RSpec/VerifiedDoubles
  describe '.configure_for_puma' do
    let(:logger) { Gitlab::AppLogger }
    let(:puma) do
      Class.new do
        def self.cli_config
          Struct.new(:options).new
        end
      end
    end

    subject(:configurator) { described_class.configure_for_puma }

    def stub_prometheus_metrics
      gauge = instance_double(::Prometheus::Client::Gauge)
      allow(Gitlab::Metrics).to receive(:gauge).and_return(gauge)
      allow(gauge).to receive(:set)
    end

    before do
      stub_const('Puma', puma)
      stub_const('Puma::Cluster::WorkerHandle', double.as_null_object)
      stub_prometheus_metrics
    end

    it_behaves_like 'as configurator',
                    Gitlab::Memory::Watchdog::PumaHandler,
                    'GITLAB_MEMWD_SLEEP_TIME_SEC',
                    60

    context 'with DISABLE_PUMA_WORKER_KILLER set to true' do
      let(:primary_memory) { 2048 }
      let(:worker_memory) { max_mem_growth * primary_memory + 1 }
      let(:expected_payloads) do
        {
          heap_fragmentation: {
            message: 'heap fragmentation limit exceeded',
            memwd_cur_heap_frag: max_heap_fragmentation + 0.1,
            memwd_max_heap_frag: max_heap_fragmentation,
            memwd_max_strikes: max_strikes,
            memwd_cur_strikes: 1

          },
          unique_memory_growth: {
            message: 'memory limit exceeded',
            memwd_uss_bytes: worker_memory,
            memwd_ref_uss_bytes: primary_memory,
            memwd_max_uss_bytes: max_mem_growth * primary_memory,
            memwd_max_strikes: max_strikes,
            memwd_cur_strikes: 1
          }
        }
      end

      before do
        stub_env('DISABLE_PUMA_WORKER_KILLER', true)
        allow(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation).and_return(max_heap_fragmentation + 0.1)
        allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).and_return({ uss: worker_memory })
        allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(
          pid: Gitlab::Cluster::PRIMARY_PID
        ).and_return({ uss: primary_memory })
      end

      context 'when settings are set via environment variables' do
        let(:max_heap_fragmentation) { 0.4 }
        let(:max_mem_growth) { 4.0 }
        let(:max_strikes) { 4 }

        before do
          stub_env('GITLAB_MEMWD_MAX_HEAP_FRAG', 0.4)
          stub_env('GITLAB_MEMWD_MAX_MEM_GROWTH', 4.0)
          stub_env('GITLAB_MEMWD_MAX_STRIKES', 4)
        end

        it_behaves_like 'as monitor configurator'
      end

      context 'when settings are not set via environment variables' do
        let(:max_heap_fragmentation) { 0.5 }
        let(:max_mem_growth) { 3.0 }
        let(:max_strikes) { 5 }

        it_behaves_like 'as monitor configurator'
      end
    end

    context 'with DISABLE_PUMA_WORKER_KILLER set to false' do
      let(:expected_payloads) do
        {
          rss_memory_limit: {
            message: 'rss memory limit exceeded',
            memwd_rss_bytes: memory_limit + 1,
            memwd_max_rss_bytes: memory_limit,
            memwd_max_strikes: max_strikes,
            memwd_cur_strikes: 1
          }
        }
      end

      before do
        stub_env('DISABLE_PUMA_WORKER_KILLER', false)
        allow(Gitlab::Metrics::System).to receive(:memory_usage_rss).and_return({ total: memory_limit + 1 })
      end

      context 'when settings are set via environment variables' do
        let(:memory_limit) { 1300 }
        let(:max_strikes) { 4 }

        before do
          stub_env('PUMA_WORKER_MAX_MEMORY', 1300)
          stub_env('GITLAB_MEMWD_MAX_STRIKES', 4)
        end

        it_behaves_like 'as monitor configurator'
      end

      context 'when settings are not set via environment variables' do
        let(:memory_limit) { 1200 }
        let(:max_strikes) { 5 }

        it_behaves_like 'as monitor configurator'
      end
    end
  end
  # rubocop: enable RSpec/VerifiedDoubles

  describe '.configure_for_sidekiq' do
    let(:logger) { ::Sidekiq.logger }

    subject(:configurator) { described_class.configure_for_sidekiq }

    it_behaves_like 'as configurator',
                    Gitlab::Memory::Watchdog::TermProcessHandler,
                    'SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL',
                    3
  end
end
