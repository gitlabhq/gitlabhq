# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::DuplicateJobs::Server, :clean_gitlab_redis_queues do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestDeduplicationWorker'
      end

      include ApplicationWorker

      def perform(*args)
      end
    end
  end

  before do
    stub_const('TestDeduplicationWorker', worker_class)
  end

  around do |example|
    with_sidekiq_server_middleware do |chain|
      chain.add described_class
      Sidekiq::Testing.inline! { example.run }
    end
  end

  describe '#call' do
    it 'removes the stored job from redis' do
      bare_job = { 'class' => 'TestDeduplicationWorker', 'args' => ['hello'] }
      job_definition = Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new(bare_job.dup, 'test_deduplication')

      expect(Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob)
        .to receive(:new).with(a_hash_including(bare_job), 'test_deduplication')
              .and_return(job_definition).twice # once in client middleware
      expect(job_definition).to receive(:delete!).and_call_original

      TestDeduplicationWorker.perform_async('hello')
    end
  end
end
