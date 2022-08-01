# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'memory watchdog' do
  subject(:run_initializer) do
    load Rails.root.join('config/initializers/memory_watchdog.rb')
  end

  context 'when GITLAB_MEMORY_WATCHDOG_ENABLED is truthy' do
    let(:env_switch) { 'true' }

    before do
      stub_env('GITLAB_MEMORY_WATCHDOG_ENABLED', env_switch)
    end

    context 'when runtime is an application' do
      let(:watchdog) { instance_double(Gitlab::Memory::Watchdog) }
      let(:background_task) { instance_double(Gitlab::BackgroundTask) }

      before do
        allow(Gitlab::Runtime).to receive(:application?).and_return(true)
      end

      it 'registers a life-cycle hook' do
        expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start)

        run_initializer
      end

      shared_examples 'starts watchdog with handler' do |handler_class|
        it "uses the #{handler_class} and starts the watchdog" do
          expect(Gitlab::Memory::Watchdog).to receive(:new).with(
            handler: an_instance_of(handler_class),
            logger: Gitlab::AppLogger).and_return(watchdog)
          expect(Gitlab::BackgroundTask).to receive(:new).with(watchdog).and_return(background_task)
          expect(background_task).to receive(:start)
          expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_yield

          run_initializer
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

        it_behaves_like 'starts watchdog with handler', Gitlab::Memory::Watchdog::PumaHandler
      end
      # rubocop: enable RSpec/VerifiedDoubles

      context 'when sidekiq' do
        before do
          allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        end

        it_behaves_like 'starts watchdog with handler', Gitlab::Memory::Watchdog::TermProcessHandler
      end

      context 'when other runtime' do
        it_behaves_like 'starts watchdog with handler', Gitlab::Memory::Watchdog::NullHandler
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
