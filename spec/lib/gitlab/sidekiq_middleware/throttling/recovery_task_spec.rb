# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Throttling::RecoveryTask, :clean_gitlab_redis_shared_state,
  feature_category: :scalability do
  include ExclusiveLeaseHelpers
  let(:lease_key) { 'gitlab/sidekiq_middleware/throttling/recovery_task:queues:default' }

  subject(:recovery_task) do
    described_class.new.tap do |instance|
      # We need to defuse `sleep` and stop the internal loop after 1 iteration
      iterations = 0
      allow(instance).to receive(:sleep) do
        instance.stop if (iterations += 1) > 0
      end
    end
  end

  describe '#call' do
    it 'sleeps for a randomized interval between MIN_SLEEP_INTERVAL and MAX_SLEEP_INTERVAL' do
      expect(recovery_task).to receive(:sleep)
                                 .with(a_value_between(
                                   described_class::MIN_SLEEP_INTERVAL,
                                   described_class::MAX_SLEEP_INTERVAL))

      recovery_task.call
    end

    context 'when lease cannot be obtained' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::LEASE_TTL)
      end

      it 'does not recover workers' do
        expect(recovery_task).not_to receive(:recover_workers)

        recovery_task.call
      end
    end

    context 'when lease can be obtained' do
      let(:worker_a) do
        Class.new do
          def self.name
            'WorkerA'
          end
        end
      end

      let(:worker_b) do
        Class.new do
          def self.name
            'WorkerB'
          end
        end
      end

      before do
        stub_exclusive_lease(lease_key, timeout: described_class::LEASE_TTL)
        allow(Gitlab::SidekiqMiddleware::Throttling::Tracker).to receive(:throttled_workers)
                                                                   .and_return(throttled_worker_names)
      end

      context 'when there are throttled workers' do
        let(:throttled_worker_names) { %w[WorkerA WorkerB] }
        let(:recovery_service_double) { instance_double(Gitlab::SidekiqMiddleware::Throttling::RecoveryService) }
        let(:current_sidekiq_queue) { Sidekiq.default_configuration.queues.first }

        before do
          allow(Gitlab::SidekiqMiddleware::Throttling::RecoveryService).to receive(:new)
                                                                             .and_return(recovery_service_double)
          stub_const('WorkerA', worker_a)
          stub_const('WorkerB', worker_b)
          allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route)
                                                                   .and_return(current_sidekiq_queue)
        end

        it 'calls RecoveryService for each throttled worker' do
          throttled_worker_names.each do |worker_name|
            expect(Gitlab::SidekiqMiddleware::Throttling::RecoveryService).to receive(:new)
                                                                                .with(worker_name)
          end
          expect(recovery_service_double).to receive(:execute).exactly(throttled_worker_names.size).times

          recovery_task.call
        end

        context 'with throttled workers outside of current queue' do
          before do
            allow(Sidekiq.default_configuration).to receive(:queues).and_return(['current_queue'])

            allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route).with(WorkerA)
                                                                                  .and_return('current_queue')
            allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route).with(WorkerB)
                                                                                  .and_return('another_queue')
          end

          it 'calls RecoveryService for workers routed to current queue only' do
            expect(Gitlab::SidekiqMiddleware::Throttling::RecoveryService).to receive(:new)
                                                                                .with('WorkerA')
            expect(recovery_service_double).to receive(:execute).once

            recovery_task.call
          end
        end
      end

      context 'when no workers are throttled' do
        let(:throttled_worker_names) { [] }

        it 'does not call RecoveryService' do
          expect(Gitlab::SidekiqMiddleware::Throttling::RecoveryService).not_to receive(:new)

          recovery_task.call
        end
      end
    end

    context 'when sidekiq throttling middleware FF is disabled' do
      before do
        stub_feature_flags(sidekiq_throttling_middleware: false)
      end

      it 'does not recover workers' do
        expect(recovery_task).not_to receive(:try_obtain_lease)
        expect(recovery_task).not_to receive(:recover_workers)

        recovery_task.call
      end
    end
  end

  describe '#stop' do
    it 'sets the alive flag to false' do
      expect { recovery_task.stop }.to change { recovery_task.instance_variable_get(:@alive) }.from(true).to(false)
    end
  end
end
