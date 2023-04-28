# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Server, :clean_gitlab_redis_queues do
  shared_context 'server duplicate job' do |strategy|
    let(:worker_class) do
      Class.new do
        def self.name
          'TestDeduplicationWorker'
        end

        include ApplicationWorker

        deduplicate strategy

        def perform(*args)
          self.class.work
        end

        def self.work; end
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
  end

  context 'with until_executing strategy' do
    include_context 'server duplicate job', :until_executing

    describe '#call' do
      it 'removes the stored job from redis before execution' do
        bare_job = { 'class' => 'TestDeduplicationWorker', 'args' => ['hello'] }
        job_definition = Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new(bare_job.dup, 'default')

        expect(Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob)
          .to receive(:new).with(a_hash_including(bare_job), 'default')
                .and_return(job_definition).twice # once in client middleware

        expect(job_definition).to receive(:delete!).ordered.and_call_original
        expect(TestDeduplicationWorker).to receive(:work).ordered.and_call_original

        TestDeduplicationWorker.perform_async('hello')
      end
    end
  end

  context 'with until_executed strategy' do
    include_context 'server duplicate job', :until_executed

    it 'removes the stored job from redis after execution' do
      bare_job = { 'class' => 'TestDeduplicationWorker', 'args' => ['hello'] }
      job_definition = Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new(bare_job.dup, 'default')

      expect(Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob)
        .to receive(:new).with(a_hash_including(bare_job), 'default')
              .and_return(job_definition).twice # once in client middleware

      expect(TestDeduplicationWorker).to receive(:work).ordered.and_call_original
      expect(job_definition).to receive(:delete!).ordered.and_call_original

      TestDeduplicationWorker.perform_async('hello')
    end
  end
end
