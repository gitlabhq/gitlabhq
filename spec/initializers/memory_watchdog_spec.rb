# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'memory watchdog' do
  subject(:run_initializer) do
    load rails_root_join('config/initializers/memory_watchdog.rb')
  end

  context 'when GITLAB_MEMORY_WATCHDOG_ENABLED is truthy' do
    let(:env_switch) { 'true' }

    before do
      stub_env('GITLAB_MEMORY_WATCHDOG_ENABLED', env_switch)
    end

    context 'when runtime is an application' do
      let(:watchdog) { instance_double(Gitlab::Memory::Watchdog) }
      let(:background_task) { instance_double(Gitlab::BackgroundTask) }
      let(:logger) { Gitlab::AppLogger }

      before do
        allow(Gitlab::Runtime).to receive(:application?).and_return(true)
      end

      it 'registers a life-cycle hook' do
        expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start)

        run_initializer
      end

      shared_examples 'starts configured watchdog' do |handler_class|
        let(:configuration) { Gitlab::Memory::Watchdog::Configuration.new }
        let(:watchdog_monitors_params) do
          {
            Gitlab::Memory::Watchdog::Monitor::HeapFragmentation => {
              max_heap_fragmentation: max_heap_fragmentation,
              max_strikes: max_strikes
            },
            Gitlab::Memory::Watchdog::Monitor::UniqueMemoryGrowth => {
              max_mem_growth: max_mem_growth,
              max_strikes: max_strikes
            }
          }
        end

        shared_examples 'configures and starts watchdog' do
          it "correctly configures and starts watchdog", :aggregate_failures do
            expect(watchdog).to receive(:configure).and_yield(configuration)

            watchdog_monitors_params.each do |monitor_class, params|
              expect(configuration.monitors).to receive(:use).with(monitor_class, **params)
            end

            expect(Gitlab::Memory::Watchdog).to receive(:new).and_return(watchdog)
            expect(Gitlab::BackgroundTask).to receive(:new).with(watchdog).and_return(background_task)
            expect(background_task).to receive(:start)
            expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_yield

            run_initializer

            expect(configuration.handler).to be_an_instance_of(handler_class)
            expect(configuration.logger).to eq(logger)
            expect(configuration.sleep_time_seconds).to eq(sleep_time_seconds)
          end
        end

        context 'when settings are not passed through the environment' do
          let(:max_strikes) { 5 }
          let(:max_heap_fragmentation) { 0.5 }
          let(:max_mem_growth) { 3.0 }
          let(:sleep_time_seconds) { 60 }

          include_examples 'configures and starts watchdog'
        end

        context 'when settings are passed through the environment' do
          let(:max_strikes) { 6 }
          let(:max_heap_fragmentation) { 0.4 }
          let(:max_mem_growth) { 2.0 }
          let(:sleep_time_seconds) { 50 }

          before do
            stub_env('GITLAB_MEMWD_MAX_STRIKES', 6)
            stub_env('GITLAB_MEMWD_SLEEP_TIME_SEC', 50)
            stub_env('GITLAB_MEMWD_MAX_MEM_GROWTH', 2.0)
            stub_env('GITLAB_MEMWD_MAX_HEAP_FRAG', 0.4)
          end

          include_examples 'configures and starts watchdog'
        end
      end

      # In tests, the Puma constant does not exist so we cannot use a verified double.
      # rubocop: disable RSpec/VerifiedDoubles
      context 'when puma' do
        let(:puma) do
          Class.new do
            def self.cli_config
              Struct.new(:options).new
            end
          end
        end

        before do
          stub_const('Puma', puma)
          stub_const('Puma::Cluster::WorkerHandle', double.as_null_object)

          allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
        end

        it_behaves_like 'starts configured watchdog', Gitlab::Memory::Watchdog::PumaHandler
      end
      # rubocop: enable RSpec/VerifiedDoubles

      context 'when sidekiq' do
        before do
          allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        end

        it_behaves_like 'starts configured watchdog', Gitlab::Memory::Watchdog::TermProcessHandler
      end

      context 'when other runtime' do
        it_behaves_like 'starts configured watchdog', Gitlab::Memory::Watchdog::NullHandler
      end
    end

    context 'when runtime is unsupported' do
      it 'does not register life-cycle hook' do
        expect(Gitlab::Cluster::LifecycleEvents).not_to receive(:on_worker_start)

        run_initializer
      end
    end
  end

  context 'when GITLAB_MEMORY_WATCHDOG_ENABLED is false' do
    let(:env_switch) { 'false' }

    before do
      stub_env('GITLAB_MEMORY_WATCHDOG_ENABLED', env_switch)
      # To rule out we return early due to this being false.
      allow(Gitlab::Runtime).to receive(:application?).and_return(true)
    end

    it 'does not register life-cycle hook' do
      expect(Gitlab::Cluster::LifecycleEvents).not_to receive(:on_worker_start)

      run_initializer
    end
  end

  context 'when GITLAB_MEMORY_WATCHDOG_ENABLED is not set' do
    before do
      # To rule out we return early due to this being false.
      allow(Gitlab::Runtime).to receive(:application?).and_return(true)
    end

    it 'does not register life-cycle hook' do
      expect(Gitlab::Cluster::LifecycleEvents).not_to receive(:on_worker_start)

      run_initializer
    end
  end
end
