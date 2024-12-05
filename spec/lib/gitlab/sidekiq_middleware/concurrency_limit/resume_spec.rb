# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::Resume, :request_store, feature_category: :scalability do
  let(:resumed_worker_class) do
    Class.new do
      def self.name
        'TestResumedWorker'
      end

      include ApplicationWorker

      feature_category :scalability
      def perform(*args); end
    end
  end

  let(:normal_worker_class) do
    Class.new do
      def self.name
        'TestNormalWorker'
      end

      include ApplicationWorker

      feature_category :scalability
      def perform(*args); end
    end
  end

  let(:buffered_at) { 1.minute.ago.utc }

  let(:stored_jobs_metadata) do
    [
      { 'concurrency_limit_buffered_at' => buffered_at.to_f, 'concurrency_limit_resume' => true }.merge(context),
      { 'concurrency_limit_buffered_at' => (buffered_at + 1.second).to_f, 'concurrency_limit_resume' => true }
        .merge(context)
    ]
  end

  let(:context) do
    {
      "#{Gitlab::ApplicationContext::LOG_KEY}.project" => 'gitlab-org/gitlab',
      "correlation_id" => 'context_correlation_id'
    }
  end

  let(:metadata_key) do
    Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.metadata_key(TestResumedWorker.name)
  end

  before do
    stub_const(resumed_worker_class.name, resumed_worker_class)
    stub_const(normal_worker_class.name, normal_worker_class)

    queue = Queue.new
    stored_jobs_metadata.each { |jm| queue.push(jm) }
    Gitlab::SafeRequestStore.write(metadata_key, queue)
  end

  describe '#call' do
    context 'with normal worker' do
      it 'does not contain any metadata from request store' do
        TestNormalWorker.perform_async

        job = TestNormalWorker.jobs.last
        expect(job).not_to include(
          "#{Gitlab::ApplicationContext::LOG_KEY}.project",
          'concurrency_limit_resume',
          'concurrency_limit_buffered_at'
        )
        expect(job['correlation_id']).not_to eq('context_correlation_id')
      end
    end

    context 'with resumed worker' do
      it 'contains metadata from request store' do
        TestResumedWorker.perform_async

        job = TestResumedWorker.jobs.last
        expect(job['correlation_id']).to eq('context_correlation_id')
        expect(job["#{Gitlab::ApplicationContext::LOG_KEY}.project"]).to eq('gitlab-org/gitlab')
        expect(job['concurrency_limit_resume']).to be(true)
        expect(job['concurrency_limit_buffered_at']).to eq(buffered_at.to_f)
      end

      it 'pops the metadata from request store' do
        expect { TestResumedWorker.perform_async }.to change { Gitlab::SafeRequestStore.read(metadata_key).size }
                                                 .from(2).to(1)
      end

      context 'when metadata queue is empty' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:track_exception)
        end

        it 'tracks an exception with missing metadata' do
          3.times { TestResumedWorker.perform_async }

          expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
            described_class::EmptyJobMetadataError
          )
        end
      end
    end
  end

  context 'as integration test with QueueManager#resume_processing!' do
    let(:queue_manager) do
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::QueueManager.new(worker_name: resumed_worker_class.name,
        prefix: 'sidekiq:concurrency_limit')
    end

    before do
      2.times { queue_manager.add_to_queue!({ 'args' => ['foo'] }, context) }
    end

    it 'enqueued jobs containing the correct payload' do
      TestNormalWorker.perform_async
      queue_manager.resume_processing!(limit: 2)
      TestNormalWorker.perform_async

      rw_jobs = TestResumedWorker.jobs
      expect(rw_jobs.length).to be(2)
      rw_jobs.each do |job|
        expect(job['correlation_id']).to eq('context_correlation_id')
        expect(job["#{Gitlab::ApplicationContext::LOG_KEY}.project"]).to eq('gitlab-org/gitlab')
        expect(job['concurrency_limit_resume']).to be(true)
        expect(job['concurrency_limit_buffered_at']).not_to be_nil
      end

      nw_jobs = TestNormalWorker.jobs
      expect(nw_jobs.length).to be(2)
      nw_jobs.each do |job|
        expect(job).not_to include(
          "#{Gitlab::ApplicationContext::LOG_KEY}.project",
          'concurrency_limit_resume',
          'concurrency_limit_buffered_at'
        )
        expect(job['correlation_id']).not_to eq('context_correlation_id')
      end
    end
  end
end
