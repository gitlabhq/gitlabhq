# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService,
  :clean_gitlab_redis_shared_state, :clean_gitlab_redis_queues_metadata, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
    end
  end

  let(:worker_class_name) { worker_class.name }

  let(:worker_context) do
    { 'correlation_id' => 'context_correlation_id',
      'meta.project' => 'gitlab-org/gitlab' }
  end

  let(:job) { { 'class' => worker_class_name, 'args' => [1, 2] } }

  subject(:service) { described_class.new(worker_class_name) }

  before do
    stub_const(worker_class_name, worker_class)
  end

  describe '.drop_matching_jobs!' do
    let(:other_worker_class) do
      Class.new do
        def self.name
          'OtherDummyWorker'
        end

        include ApplicationWorker
      end
    end

    let(:target_user) { 'target_user' }
    let(:other_user) { 'other_user' }

    let(:matching_context) { { 'meta.user' => target_user } }
    let(:non_matching_context) { { 'meta.user' => other_user } }

    let(:worker_names) { [worker_class_name, 'OtherDummyWorker'] }

    before do
      stub_const('OtherDummyWorker', other_worker_class)
      service.add_to_queue!(job, matching_context)
      service.add_to_queue!(job.merge('jid' => 'other_jid'), non_matching_context)
      described_class.new('OtherDummyWorker').add_to_queue!(job, matching_context)
    end

    it 'removes matching jobs from the given workers, leaving non-matching jobs intact',
      :aggregate_failures do
      expect(described_class.drop_matching_jobs!(worker_names, matching_context))
        .to eq(completed: true, deleted_jobs: 2)
      expect(described_class.queue_size(worker_class_name)).to eq(1)
      expect(described_class.queue_size('OtherDummyWorker')).to eq(0)
    end

    it 'only touches the given workers' do
      described_class.drop_matching_jobs!([worker_class_name], matching_context)

      expect(described_class.queue_size(worker_class_name)).to eq(1)
      expect(described_class.queue_size('OtherDummyWorker')).to eq(1)
    end

    it 'reports completed: false when a worker queue times out' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:drop_jobs!).and_return({ completed: false, deleted_jobs: 0 })
      end

      expect(described_class.drop_matching_jobs!([worker_class_name], matching_context))
        .to eq(completed: false, deleted_jobs: 0)
    end

    it 'shares a single timeout budget across workers and skips the rest once exhausted' do
      first = instance_double(described_class, drop_jobs!: { completed: true, deleted_jobs: 1 })
      # start_time=0, first worker sees remaining=5 (runs), then elapsed jumps past the budget
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(0, 5, 100)

      # only the first worker is instantiated; the second is skipped once the budget is spent
      expect(described_class).to receive(:new).with(worker_class_name).once.and_return(first)

      expect(described_class.drop_matching_jobs!(worker_names, matching_context, timeout: 10))
        .to eq(completed: false, deleted_jobs: 1)
    end

    it 'returns zero deletions when context_metadata is empty' do
      expect(described_class.drop_matching_jobs!(worker_names, {}))
        .to eq(completed: true, deleted_jobs: 0)
    end

    it 'returns zero deletions when worker_names is empty' do
      expect(described_class.drop_matching_jobs!([], matching_context))
        .to eq(completed: true, deleted_jobs: 0)
    end
  end

  describe '.add_to_queue!' do
    subject(:add_to_queue!) { described_class.add_to_queue!(job, worker_context) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:add_to_queue!).with(job, worker_context)
      end

      add_to_queue!
    end

    it 'reports prometheus metrics' do
      deferred_job_count_double = instance_double(Prometheus::Client::Counter)
      expect(Gitlab::Metrics).to receive(:counter).with(:sidekiq_concurrency_limit_deferred_jobs_total, anything)
        .and_return(deferred_job_count_double)
      expect(deferred_job_count_double).to receive(:increment).with({ worker: worker_class_name })

      add_to_queue!
    end
  end

  describe '.has_jobs_in_queue?' do
    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:has_jobs_in_queue?)
      end

      described_class.has_jobs_in_queue?(worker_class_name)
    end
  end

  describe '.resume_processing!' do
    subject(:resume_processing!) { described_class.resume_processing!(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:resume_processing!)
      end

      resume_processing!
    end
  end

  describe '.queue_size' do
    it 'reports the queue size' do
      expect(described_class.queue_size(worker_class_name)).to eq(0)

      service.add_to_queue!(job, worker_context)

      expect(described_class.queue_size(worker_class_name)).to eq(1)

      expect { service.resume_processing! }.to change { described_class.queue_size(worker_class_name) }.by(-1)
    end
  end

  describe '.track_execution_start' do
    subject(:track_execution_start) { described_class.track_execution_start(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:track_execution_start)
      end

      track_execution_start
    end
  end

  describe '.track_execution_end' do
    subject(:track_execution_end) { described_class.track_execution_end(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:track_execution_end)
      end

      track_execution_end
    end
  end

  describe '.concurrent_worker_count' do
    subject(:concurrent_worker_count) { described_class.concurrent_worker_count(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:concurrent_worker_count)
      end

      concurrent_worker_count
    end
  end

  describe '.track_pending_resumed_jobs' do
    subject(:track_pending_resumed_jobs) { described_class.track_pending_resumed_jobs(worker_class_name, 2) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:track_pending_resumed_jobs).with(2)
      end

      track_pending_resumed_jobs
    end
  end

  describe '.untrack_pending_resumed_job' do
    subject(:untrack_pending_resumed_job) { described_class.untrack_pending_resumed_job(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:untrack_pending_resumed_job)
      end

      untrack_pending_resumed_job
    end
  end

  describe '.pending_resumed_jobs_count' do
    subject(:pending_resumed_jobs_count) { described_class.pending_resumed_jobs_count(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:pending_resumed_jobs_count)
      end

      pending_resumed_jobs_count
    end
  end

  describe '.cleanup_stale_trackers' do
    subject(:cleanup_stale_trackers) { described_class.cleanup_stale_trackers(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:cleanup_stale_trackers)
      end

      cleanup_stale_trackers
    end
  end

  describe '.current_limit' do
    subject(:current_limit) { described_class.current_limit(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:current_limit)
      end

      current_limit
    end
  end

  describe '.set_current_limit!' do
    subject(:set_current_limit!) { described_class.set_current_limit!(worker_class_name, limit: 10) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:set_current_limit!)
      end

      set_current_limit!
    end
  end

  describe '.over_the_limit?' do
    subject(:over_the_limit?) { described_class.over_the_limit?(worker_class_name) }

    it 'returns true if over the limit' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:concurrent_worker_count).and_return(10)
        expect(instance).to receive(:current_limit).and_return(10)
      end

      expect(over_the_limit?).to be(true)
    end

    it 'return false if under the limit' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:concurrent_worker_count).and_return(9)
        expect(instance).to receive(:current_limit).and_return(10)
      end

      expect(over_the_limit?).to be(false)
    end
  end

  context 'with concurrent changes to different queues' do
    let(:second_worker_class) do
      Class.new do
        def self.name
          'SecondDummyIndexingWorker'
        end

        include ApplicationWorker
      end
    end

    let(:other_subject) { described_class.new(second_worker_class.name) }

    before do
      stub_const(second_worker_class.name, second_worker_class)
    end

    it 'allows to use queues independently of each other' do
      expect { service.add_to_queue!(job, worker_context) }
        .to change { service.queue_size }
        .from(0).to(1)

      expect { other_subject.add_to_queue!(job, worker_context) }
        .to change { other_subject.queue_size }
        .from(0).to(1)

      expect { service.resume_processing! }.to change { service.has_jobs_in_queue? }
        .from(true).to(false)

      expect { other_subject.resume_processing! }.to change { other_subject.has_jobs_in_queue? }
        .from(true).to(false)
    end
  end
end
