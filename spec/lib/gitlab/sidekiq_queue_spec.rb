# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqQueue, :clean_gitlab_redis_queues, :clean_gitlab_redis_queues_metadata,
  :clean_gitlab_redis_shared_state, feature_category: :sidekiq do
  around do |example|
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls { Sidekiq::Queue.new('foobar').clear }
    Sidekiq::Testing.disable!(&example)
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls { Sidekiq::Queue.new('foobar').clear }
  end

  def add_job(args, user:, klass: 'AuthorizedProjectsWorker')
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      Sidekiq::Client.push(
        'class' => klass,
        'queue' => 'foobar',
        'args' => args,
        'meta.user' => user.username
      )
    end
  end

  describe '#drop_jobs!' do
    shared_examples 'queue processing' do
      let(:sidekiq_queue) { described_class.new('foobar') }
      let_it_be(:sidekiq_queue_user) { create(:user) }

      before do
        add_job([1], user: create(:user))
        add_job([2], user: sidekiq_queue_user, klass: 'MergeWorker')
        add_job([3], user: sidekiq_queue_user)
      end

      context 'when the queue is not processed in time' do
        before do
          allow(sidekiq_queue).to receive(:monotonic_time).and_return(1, 2, 12)
        end

        it 'returns a non-completion flag, the number of jobs deleted, and the remaining queue size' do
          expect(sidekiq_queue.drop_jobs!(search_metadata, timeout: 10))
            .to eq(completed: false,
              deleted_jobs: timeout_deleted,
              queue_size: 3 - timeout_deleted)
        end
      end

      context 'when the queue is processed in time' do
        it 'returns a completion flag, the number of jobs deleted, and the remaining queue size' do
          expect(sidekiq_queue.drop_jobs!(search_metadata, timeout: 10))
            .to eq(completed: true,
              deleted_jobs: no_timeout_deleted,
              queue_size: 3 - no_timeout_deleted)
        end
      end
    end

    context 'when there are no matching jobs' do
      include_examples 'queue processing' do
        let(:search_metadata) { { project: 1 } }
        let(:timeout_deleted) { 0 }
        let(:no_timeout_deleted) { 0 }
      end
    end

    context 'when there are matching jobs' do
      include_examples 'queue processing' do
        let(:search_metadata) { { user: sidekiq_queue_user.username } }
        let(:timeout_deleted) { 1 }
        let(:no_timeout_deleted) { 2 }
      end
    end

    context 'when there are jobs matching the class name' do
      include_examples 'queue processing' do
        let(:search_metadata) { { user: sidekiq_queue_user.username, worker_class: 'AuthorizedProjectsWorker' } }
        let(:timeout_deleted) { 1 }
        let(:no_timeout_deleted) { 1 }
      end
    end

    context 'when there extra queue shard instances are used' do
      let(:search_metadata) { { user: sidekiq_queue_user.username } }
      let(:sidekiq_queue) { described_class.new('foobar') }
      let_it_be(:sidekiq_queue_user) { create(:user) }

      before do
        allow(Gitlab::Redis::Queues)
          .to receive(:instances).and_return({ 'main' => Gitlab::Redis::Queues, 'shard' => Gitlab::Redis::Queues })

        add_job([1], user: create(:user))
        add_job([2], user: sidekiq_queue_user, klass: 'MergeWorker')
        add_job([3], user: sidekiq_queue_user)
      end

      it 'tracks queues from both instances' do
        expect(Sidekiq::Queue).to receive(:all).twice.and_call_original

        expect(sidekiq_queue.drop_jobs!(search_metadata, timeout: 10))
          .to eq(completed: true,
            deleted_jobs: 2,
            queue_size: 2) # Note: intentional double count
      end
    end

    context 'when there are matching deferred (concurrency-limited) jobs' do
      let(:sidekiq_queue) { described_class.new('foobar') }
      let_it_be(:sidekiq_queue_user) { create(:user) }

      let(:concurrency_limit_prefix) do
        Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService::REDIS_KEY_PREFIX
      end

      let(:queue_manager) do
        Gitlab::SidekiqMiddleware::ConcurrencyLimit::QueueManager.new(
          worker_name: 'AuthorizedProjectsWorker',
          prefix: concurrency_limit_prefix
        )
      end

      before do
        # Route the 'foobar' queue to the deferred worker so the purge is scoped to it.
        allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings)
          .and_return({ 'AuthorizedProjectsWorker' => 'foobar', 'MergeWorker' => 'merge' })

        add_job([1], user: sidekiq_queue_user)
        queue_manager.add_to_queue!(
          { 'args' => [1], 'jid' => 'deferred_match' },
          { 'meta.user' => sidekiq_queue_user.username }
        )
        queue_manager.add_to_queue!(
          { 'args' => [2], 'jid' => 'deferred_no_match' },
          { 'meta.user' => 'other_user' }
        )
      end

      it 'removes matching deferred jobs and includes their count in deleted_jobs', :aggregate_failures do
        result = sidekiq_queue.drop_jobs!({ user: sidekiq_queue_user.username }, timeout: 10)

        expect(result[:deleted_jobs]).to eq(2)
        expect(queue_manager.queue_size).to eq(1)
      end

      it "removes all of the worker's deferred jobs when only worker_class metadata is provided" do
        result = sidekiq_queue.drop_jobs!({ worker_class: 'AuthorizedProjectsWorker' }, timeout: 10)

        expect(result[:deleted_jobs]).to eq(3) # 1 primary + 2 deferred
        expect(queue_manager.queue_size).to eq(0)
      end

      it "does not remove other workers' deferred jobs when worker_class metadata is provided" do
        other_manager = Gitlab::SidekiqMiddleware::ConcurrencyLimit::QueueManager.new(
          worker_name: 'MergeWorker',
          prefix: concurrency_limit_prefix
        )
        other_manager.add_to_queue!(
          { 'args' => [3], 'jid' => 'other_worker_deferred' },
          { 'meta.user' => sidekiq_queue_user.username }
        )
        allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings)
          .and_return({ 'AuthorizedProjectsWorker' => 'foobar', 'MergeWorker' => 'foobar' })

        sidekiq_queue.drop_jobs!(
          { worker_class: 'AuthorizedProjectsWorker', user: sidekiq_queue_user.username }, timeout: 10
        )

        expect(other_manager.queue_size).to eq(1)
        expect(queue_manager.queue_size).to eq(1)
      end

      it 'does not touch deferred jobs of workers routed to other queues' do
        allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings)
          .and_return({ 'AuthorizedProjectsWorker' => 'some_other_queue' })

        sidekiq_queue.drop_jobs!({ user: sidekiq_queue_user.username }, timeout: 10)

        expect(queue_manager.queue_size).to eq(2)
      end

      it 'reports completed: false when deferred processing times out' do
        allow_next_instance_of(Gitlab::SidekiqMiddleware::ConcurrencyLimit::QueueManager) do |instance|
          allow(instance).to receive(:drop_jobs!).and_return({ completed: false, deleted_jobs: 0 })
        end

        result = sidekiq_queue.drop_jobs!({ user: sidekiq_queue_user.username }, timeout: 10)

        expect(result[:completed]).to be(false)
      end
    end

    context 'when there are no valid metadata keys passed' do
      it 'raises NoMetadataError' do
        add_job([1], user: create(:user))

        expect { described_class.new('foobar').drop_jobs!({ username: 'sidekiq_queue_user' }, timeout: 1) }
          .to raise_error(described_class::NoMetadataError)
      end
    end

    context 'when the queue does not exist' do
      it 'raises InvalidQueueError' do
        expect { described_class.new('foo').drop_jobs!({ user: 'sidekiq_queue_user' }, timeout: 1) }
          .to raise_error(described_class::InvalidQueueError)
      end
    end
  end

  describe '#job_matches?' do
    it 'returns false when metadata is empty' do
      expect(described_class.new('foobar').send(:job_matches?, { 'class' => 'AuthorizedProjectsWorker' }, {}))
        .to be(false)
    end
  end
end
