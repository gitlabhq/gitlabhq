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

  let(:stored_context) do
    {
      "#{Gitlab::ApplicationContext::LOG_KEY}.project" => 'gitlab-org/gitlab',
      "correlation_id" => 'context_correlation_id'
    }
  end

  let(:job) { { 'class' => worker_class_name, 'args' => [1, 2] } }

  subject(:service) { described_class.new(worker_class_name) }

  before do
    stub_const(worker_class_name, worker_class)
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
    subject(:resume_processing!) { described_class.resume_processing!(worker_class_name, limit: 10) }

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

      expect { service.resume_processing!(limit: 1) }.to change { described_class.queue_size(worker_class_name) }.by(-1)
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

  describe '.cleanup_stale_trackers' do
    subject(:cleanup_stale_trackers) { described_class.cleanup_stale_trackers(worker_class_name) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:cleanup_stale_trackers)
      end

      cleanup_stale_trackers
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

      expect { service.resume_processing!(limit: 1) }.to change { service.has_jobs_in_queue? }
        .from(true).to(false)

      expect { other_subject.resume_processing!(limit: 1) }.to change { other_subject.has_jobs_in_queue? }
        .from(true).to(false)
    end
  end
end
