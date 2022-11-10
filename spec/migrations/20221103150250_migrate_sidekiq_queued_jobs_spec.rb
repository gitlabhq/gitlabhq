# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateSidekiqQueuedJobs, :clean_gitlab_redis_queues do
  around do |example|
    Sidekiq::Testing.disable!(&example)
  end

  describe '#up', :aggregate_failures, :silence_stdout do
    before do
      EmailReceiverWorker.sidekiq_options queue: 'email_receiver'
      EmailReceiverWorker.perform_async('foo')
      EmailReceiverWorker.perform_async('bar')
    end

    after do
      EmailReceiverWorker.set_queue
    end

    context 'with worker_queue_mappings mocked' do
      it 'migrates the jobs to the correct destination queue' do
        allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings)
                                          .and_return({ "EmailReceiverWorker" => "default" })
        expect(queue_length('email_receiver')).to eq(2)
        expect(queue_length('default')).to eq(0)
        migrate!
        expect(queue_length('email_receiver')).to eq(0)
        expect(queue_length('default')).to eq(2)

        jobs = list_jobs('default')
        expect(jobs[0]).to include("class" => "EmailReceiverWorker", "args" => ["bar"])
        expect(jobs[1]).to include("class" => "EmailReceiverWorker", "args" => ["foo"])
      end
    end

    context 'without worker_queue_mappings mocked' do
      it 'migration still runs' do
        # Assuming Settings.sidekiq.routing_rules is [] (named queue)
        # If the default Settings.sidekiq.routing_rules or Gitlab::SidekiqConfig.worker_queue_mappings changed,
        # this spec might be failing. We'll have to adjust the migration or this spec.
        expect(queue_length('email_receiver')).to eq(2)
        expect(queue_length('default')).to eq(0)
        migrate!
        expect(queue_length('email_receiver')).to eq(2)
        expect(queue_length('default')).to eq(0)

        jobs = list_jobs('email_receiver')
        expect(jobs[0]).to include("class" => "EmailReceiverWorker", "args" => ["bar"])
        expect(jobs[1]).to include("class" => "EmailReceiverWorker", "args" => ["foo"])
      end
    end

    context 'with illegal JSON payload' do
      let(:job) { '{foo: 1}' }

      before do
        Sidekiq.redis do |conn|
          conn.lpush("queue:email_receiver", job)
        end
      end

      it 'logs an error' do
        allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings)
                                          .and_return({ "EmailReceiverWorker" => "default" })
        allow(::Gitlab::BackgroundMigration::Logger).to receive(:build).and_return(Logger.new($stdout))
        migrate!
        expect($stdout.string).to include("Unmarshal JSON payload from SidekiqMigrateJobs failed. Job: #{job}")
      end
    end

    context 'when run in GitLab.com' do
      it 'skips the migration' do
        allow(Gitlab).to receive(:com?).and_return(true)
        expect(described_class::SidekiqMigrateJobs).not_to receive(:new)
        migrate!
      end
    end

    def queue_length(queue_name)
      Sidekiq.redis do |conn|
        conn.llen("queue:#{queue_name}")
      end
    end

    def list_jobs(queue_name)
      Sidekiq.redis { |conn| conn.lrange("queue:#{queue_name}", 0, -1) }
        .map { |item| Sidekiq.load_json item }
    end
  end
end
