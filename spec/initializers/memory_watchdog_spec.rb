# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'memory watchdog', feature_category: :cloud_connector do
  shared_examples 'starts configured watchdog' do |configure_monitor_method|
    shared_examples 'configures and starts watchdog' do
      it "correctly configures and starts watchdog", :aggregate_failures do
        expect(Gitlab::Memory::Watchdog::Configurator).to receive(configure_monitor_method)

        expect(Gitlab::Memory::Watchdog).to receive(:new).and_return(watchdog)
        expect(Gitlab::BackgroundTask).to receive(:new).with(watchdog).and_return(background_task)
        expect(background_task).to receive(:start)
        expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_yield

        run_initializer
      end
    end
  end

  let(:watchdog) { instance_double(Gitlab::Memory::Watchdog) }
  let(:background_task) { instance_double(Gitlab::BackgroundTask) }

  subject(:run_initializer) do
    load rails_root_join('config/initializers/memory_watchdog.rb')
  end

  context 'when GITLAB_MEMORY_WATCHDOG_ENABLED is truthy' do
    let(:env_switch) { 'true' }

    before do
      stub_env('GITLAB_MEMORY_WATCHDOG_ENABLED', env_switch)
    end

    context 'when runtime is an application' do
      before do
        allow(Gitlab::Runtime).to receive(:application?).and_return(true)
      end

      it 'registers a life-cycle hook' do
        expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start)

        run_initializer
      end

      context 'when puma' do
        before do
          allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
        end

        it_behaves_like 'starts configured watchdog', :configure_for_puma
      end

      context 'when sidekiq' do
        before do
          allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        end

        it_behaves_like 'starts configured watchdog', :configure_for_sidekiq
      end
    end

    context 'when runtime is unsupported' do
      it 'does not register life-cycle hook', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/468232' do
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

    context 'when puma' do
      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
      end

      it_behaves_like 'starts configured watchdog', :configure_for_puma
    end

    context 'when sidekiq' do
      before do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
      end

      it_behaves_like 'starts configured watchdog', :configure_for_sidekiq
    end
  end
end
