# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateSidekiqQueuedAndFutureJobs, :clean_gitlab_redis_queues, feature_category: :scalability do
  let(:email_receiver_queue) { 'email_receiver' }
  let(:mappings_mocked) { true }
  let(:mappings) { { "EmailReceiverWorker" => "default" } }

  around do |example|
    EmailReceiverWorker.sidekiq_options queue: email_receiver_queue
    Sidekiq::Testing.disable!(&example)
    EmailReceiverWorker.set_queue
  end

  describe '#up', :aggregate_failures, :silence_stdout do
    context 'when migrating queued jobs' do
      let(:email_receiver_jobs_count_pre) { 2 }
      let(:default_jobs_count_pre) { 0 }

      let(:email_receiver_jobs_count_post) { 0 }
      let(:default_jobs_count_post) { 2 }

      before do
        EmailReceiverWorker.perform_async('foo')
        EmailReceiverWorker.perform_async('bar')
      end

      shared_examples 'migrates queued jobs' do
        it 'migrates the jobs to the correct destination queue' do
          allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings).and_return(mappings) if mappings_mocked

          expect(queue_length('email_receiver')).to eq(email_receiver_jobs_count_pre)
          expect(queue_length('default')).to eq(default_jobs_count_pre)
          migrate!
          expect(queue_length('email_receiver')).to eq(email_receiver_jobs_count_post)
          expect(queue_length('default')).to eq(default_jobs_count_post)

          jobs = list_jobs('default')
          expect(jobs[0]).to include("class" => "EmailReceiverWorker", "queue" => "default", "args" => ["bar"])
          expect(jobs[1]).to include("class" => "EmailReceiverWorker", "queue" => "default", "args" => ["foo"])
        end
      end

      context 'with worker_queue_mappings mocked' do
        let(:mappings_mocked) { true }

        it_behaves_like 'migrates queued jobs'

        context 'when jobs are already in the correct queue' do
          let(:email_receiver_queue) { 'default' }
          let(:email_receiver_jobs_count_pre) { 0 }
          let(:default_jobs_count_pre) { 2 }

          let(:email_receiver_jobs_count_post) { 0 }
          let(:default_jobs_count_post) { 2 }

          it_behaves_like 'migrates queued jobs'
        end
      end

      context 'without worker_queue_mappings mocked' do
        # Assuming Settings.sidekiq.routing_rules is [['*', 'default']]
        # If routing_rules or Gitlab::SidekiqConfig.worker_queue_mappings changed,
        # this spec might be failing. We'll have to adjust the migration or this spec.
        let(:mappings_mocked) { false }

        it_behaves_like 'migrates queued jobs'
      end

      context 'with illegal JSON payload' do
        let(:job) { '{foo: 1}' }

        before do
          Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
            Sidekiq.redis { |conn| conn.lpush("queue:email_receiver", job) }
          end
        end

        it 'logs an error' do
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
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq.redis { |conn| conn.llen("queue:#{queue_name}") }
        end
      end

      def list_jobs(queue_name)
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq.redis { |conn| conn.lrange("queue:#{queue_name}", 0, -1) }
                 .map { |item| Sidekiq.load_json item }
        end
      end
    end

    context 'when migrating future jobs' do
      include_context 'when handling retried jobs'
      let(:schedule_jobs_count_in_email_receiver_pre) { 3 }
      let(:retry_jobs_count_in_email_receiver_pre) { 2 }
      let(:schedule_jobs_count_in_default_pre) { 0 }
      let(:retry_jobs_count_in_default_pre) { 0 }

      let(:schedule_jobs_count_in_email_receiver_post) { 0 }
      let(:retry_jobs_count_in_email_receiver_post) { 0 }
      let(:schedule_jobs_count_in_default_post) { 3 }
      let(:retry_jobs_count_in_default_post) { 2 }

      before do
        allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings).and_return(mappings) if mappings_mocked
        EmailReceiverWorker.perform_in(1.hour, 'foo')
        EmailReceiverWorker.perform_in(2.hours, 'bar')
        EmailReceiverWorker.perform_in(3.hours, 'baz')
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          retry_in(EmailReceiverWorker, 1.hour, 0)
          retry_in(EmailReceiverWorker, 2.hours, 0)
        end
      end

      shared_examples 'migrates scheduled and retried jobs' do
        it 'migrates to correct destination queue' do
          queues = %w[email_receiver default]
          job_types = %w[schedule retry]
          worker = EmailReceiverWorker.to_s
          queues.each do |queue|
            job_types.each do |job_type|
              jobs_pre = scan_jobs(job_type, queue, worker)
              expect(jobs_pre.length).to eq(send("#{job_type}_jobs_count_in_#{queue}_pre"))
            end
          end

          migrate!

          queues.each do |queue|
            job_types.each do |job_type|
              jobs_post = scan_jobs(job_type, queue, worker)
              expect(jobs_post.length).to eq(send("#{job_type}_jobs_count_in_#{queue}_post"))
            end
          end
        end

        it 'logs output at the start, finish, and in between set' do
          stub_const("#{described_class}::SidekiqMigrateJobs::LOG_FREQUENCY", 1)
          allow(::Gitlab::BackgroundMigration::Logger).to receive(:build).and_return(Logger.new($stdout))

          migrate!

          expect($stdout.string).to include('Processing schedule set')
          expect($stdout.string).to include('Processing retry set')
          expect($stdout.string).to include('In progress')
          expect($stdout.string).to include('Done')
        end
      end

      context 'with worker_queue_mappings mocked', :allow_unrouted_sidekiq_calls do
        let(:mappings_mocked) { true }

        it_behaves_like 'migrates scheduled and retried jobs'

        context 'when jobs are already in the correct queue' do
          let(:email_receiver_queue) { 'default' }
          let(:schedule_jobs_count_in_email_receiver_pre) { 0 }
          let(:retry_jobs_count_in_email_receiver_pre) { 0 }
          let(:schedule_jobs_count_in_default_pre) { 3 }
          let(:retry_jobs_count_in_default_pre) { 2 }

          let(:schedule_jobs_count_in_email_receiver_post) { 0 }
          let(:retry_jobs_count_in_email_receiver_post) { 0 }
          let(:schedule_jobs_count_in_default_post) { 3 }
          let(:retry_jobs_count_in_default_post) { 2 }

          it_behaves_like 'migrates scheduled and retried jobs'
        end

        context 'when job doesnt match mappings' do
          let(:mappings) { { "AuthorizedProjectsWorker" => "default" } }

          it 'logs skipping the job' do
            allow(::Gitlab::BackgroundMigration::Logger).to receive(:build).and_return(Logger.new($stdout))

            migrate!

            expect($stdout.string).to include('Skipping job from EmailReceiverWorker. No destination queue found.')
          end
        end
      end

      context 'without worker_queue_mappings mocked', :allow_unrouted_sidekiq_calls do
        let(:mappings_mocked) { false }

        it_behaves_like 'migrates scheduled and retried jobs'
      end

      context 'when there are matching jobs that got removed during migration' do
        it 'does not try to migrate jobs' do
          allow(::Gitlab::BackgroundMigration::Logger).to receive(:build).and_return(Logger.new($stdout))

          freeze_time do
            allow_next_instance_of(described_class::SidekiqMigrateJobs) do |migrator|
              allow(migrator).to receive(:migrate_job_in_set).and_wrap_original do |meth, *args|
                Sidekiq.redis { |c| c.zrem('schedule', args.third) }
                Sidekiq.redis { |c| c.zrem('retry', args.third) }

                meth.call(*args)
              end
            end

            migrate!
            # schedule jobs
            expect($stdout.string).to include("Done. Scanned records: 3. Migrated records: 0.")
            # retry jobs
            expect($stdout.string).to include("Done. Scanned records: 2. Migrated records: 0.")
          end
        end
      end

      context 'when run in GitLab.com' do
        it 'skips the migration' do
          allow(Gitlab).to receive(:com?).and_return(true)
          expect(described_class::SidekiqMigrateJobs).not_to receive(:new)
          migrate!
        end
      end

      def set_length(set)
        Sidekiq.redis { |c| c.zcard(set) }
      end

      def scan_jobs(set_name, queue_name, class_name)
        Sidekiq.redis { |c| c.zrange(set_name, 0, -1) }
               .map { |item| Gitlab::Json.load(item) }
               .select { |job| job['queue'] == queue_name && job['class'] == class_name }
      end
    end
  end
end
