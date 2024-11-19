# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMigrateJobs, :clean_gitlab_redis_queues,
  :clean_gitlab_redis_queues_metadata, :allow_unrouted_sidekiq_calls do
  def clear_queues
    Sidekiq::Queue.new('test').clear
    Sidekiq::Queue.new('post_receive').clear
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
  end

  around do |example|
    clear_queues
    Sidekiq::Testing.disable!(&example)
    clear_queues
  end

  describe '#migrate_set', :aggregate_failures do
    let(:worker_class) do
      Class.new do
        def self.name
          'TestWorker'
        end

        include ApplicationWorker

        def perform(*args); end
      end
    end

    before do
      stub_const('TestWorker', worker_class)
    end

    shared_examples 'processing a set' do
      let(:migrator) { described_class.new(mappings) }

      let(:set_after) do
        Sidekiq.redis { |c| c.call("ZRANGE", set_name, 0, -1, "WITHSCORES") }
          .map { |item, score| [Gitlab::Json.load(item), score] }
      end

      context 'when the set is empty' do
        let(:mappings) { { 'TestWorker' => 'new_queue' } }

        it 'returns the number of scanned and migrated jobs' do
          expect(migrator.migrate_set(set_name)).to eq(
            scanned: 0,
            migrated: 0)
        end
      end

      context 'when the set is not empty' do
        let(:mappings) { {} }

        it 'returns the number of scanned and migrated jobs' do
          create_jobs

          expect(migrator.migrate_set(set_name)).to eq(scanned: 4, migrated: 0)
        end
      end

      context 'when there are no matching jobs' do
        let(:mappings) { { 'PostReceive' => 'new_queue' } }

        it 'does not change any queue names' do
          create_jobs(include_post_receive: false)

          expect(migrator.migrate_set(set_name)).to eq(scanned: 3, migrated: 0)

          expect(set_after.length).to eq(3)
          expect(set_after.map(&:first)).to all(include('queue' => 'default', 'class' => 'TestWorker'))
        end
      end

      context 'when there are matching jobs' do
        it 'migrates only the workers matching the given worker from the set' do
          migrator = described_class.new({ 'TestWorker' => 'new_queue' })
          freeze_time do
            create_jobs

            expect(migrator.migrate_set(set_name)).to eq(
              scanned: 4,
              migrated: 3)

            set_after.each.with_index do |(item, score), i|
              if item['class'] == 'TestWorker'
                expect(item).to include('queue' => 'new_queue', 'args' => [i])
              else
                expect(item).to include('queue' => 'default', 'args' => [i])
              end

              expect(score).to be_within(schedule_jitter).of(i.succ.hours.from_now.to_i)
            end
          end
        end

        it 'allows migrating multiple workers at once' do
          migrator = described_class.new({
            'TestWorker' => 'new_queue',
            'PostReceive' => 'another_queue'
          })
          freeze_time do
            create_jobs

            expect(migrator.migrate_set(set_name)).to eq(scanned: 4, migrated: 4)

            set_after.each.with_index do |(item, score), i|
              if item['class'] == 'TestWorker'
                expect(item).to include('queue' => 'new_queue', 'args' => [i])
              else
                expect(item).to include('queue' => 'another_queue', 'args' => [i])
              end

              expect(score).to be_within(schedule_jitter).of(i.succ.hours.from_now.to_i)
            end
          end
        end

        it 'allows migrating multiple workers to the same queue' do
          migrator = described_class.new({
            'TestWorker' => 'new_queue',
            'PostReceive' => 'new_queue'
          })
          freeze_time do
            create_jobs

            expect(migrator.migrate_set(set_name)).to eq(scanned: 4, migrated: 4)

            set_after.each.with_index do |(item, score), i|
              expect(item).to include('queue' => 'new_queue', 'args' => [i])
              expect(score).to be_within(schedule_jitter).of(i.succ.hours.from_now.to_i)
            end
          end
        end

        it 'does not try to migrate jobs that are removed from the set during the migration' do
          migrator = described_class.new({ 'PostReceive' => 'new_queue' })
          freeze_time do
            create_jobs

            allow(migrator).to receive(:migrate_job_in_set).and_wrap_original do |meth, *args|
              Sidekiq.redis { |c| c.zrem(set_name, args.second) }

              meth.call(*args)
            end

            expect(migrator.migrate_set(set_name)).to eq(scanned: 4, migrated: 0)

            expect(set_after.length).to eq(3)
            expect(set_after.map(&:first)).to all(include('queue' => 'default'))
          end
        end

        it 'does not try to migrate unmatched jobs that are added to the set during the migration' do
          migrator = described_class.new({ 'PostReceive' => 'new_queue' })
          create_jobs

          calls = 0

          allow(migrator).to receive(:migrate_job_in_set).and_wrap_original do |meth, *args|
            if calls == 0
              travel_to(5.hours.from_now) { create_jobs(include_post_receive: false) }
            end

            calls += 1

            meth.call(*args)
          end

          expect(migrator.migrate_set(set_name)).to eq(scanned: 4, migrated: 1)

          expect(set_after.group_by { |job| job.first['queue'] }.transform_values(&:count))
            .to eq('default' => 6, 'new_queue' => 1)
        end

        it 'iterates through the entire set of jobs' do
          migrator = described_class.new({ 'NonExistentWorker' => 'new_queue' })
          50.times do |i|
            travel_to(i.hours.from_now) { create_jobs }
          end

          expect(migrator.migrate_set(set_name)).to eq(scanned: 200, migrated: 0)

          expect(set_after.length).to eq(200)
        end

        it 'logs output at the start, finish, and every LOG_FREQUENCY jobs' do
          freeze_time do
            create_jobs

            stub_const("#{described_class}::LOG_FREQUENCY", 2)

            logger = Logger.new(StringIO.new)
            migrator = described_class.new({
              'TestWorker' => 'new_queue',
              'PostReceive' => 'another_queue'
            }, logger: logger)

            expect(logger).to receive(:info).with(a_string_matching('Processing')).once.ordered
            expect(logger).to receive(:info).with(a_string_matching('In progress')).once.ordered
            expect(logger).to receive(:info).with(a_string_matching('Done')).once.ordered

            expect(migrator.migrate_set(set_name)).to eq(scanned: 4, migrated: 4)
          end
        end
      end
    end

    context 'scheduled jobs' do
      let(:set_name) { 'schedule' }
      let(:schedule_jitter) { 0 }

      def create_jobs(include_post_receive: true)
        TestWorker.perform_in(1.hour, 0)
        TestWorker.perform_in(2.hours, 1)
        PostReceive.perform_in(3.hours, 2) if include_post_receive
        TestWorker.perform_in(4.hours, 3)
      end

      it_behaves_like 'processing a set'
    end

    context 'retried jobs' do
      def create_jobs(include_post_receive: true)
        retry_in(TestWorker, 1.hour, 0)
        retry_in(TestWorker, 2.hours, 1)
        retry_in(PostReceive, 3.hours, 2) if include_post_receive
        retry_in(TestWorker, 4.hours, 3)
      end

      include_context 'when handling retried jobs'
      it_behaves_like 'processing a set'
    end
  end

  describe '#migrate_queues', :aggregate_failures do
    let(:migrator) { described_class.new(mappings, logger: logger) }
    let(:logger) { nil }

    def list_queues
      queues = []
      Sidekiq.redis do |conn|
        conn.scan("MATCH", "queue:*") { |key| queues << key }
      end
      queues.uniq.map { |queue| queue.split(':', 2).last }
    end

    def list_jobs(queue_name)
      Sidekiq.redis { |conn| conn.lrange("queue:#{queue_name}", 0, -1) }
             .map { |item| Gitlab::Json.load(item) }
    end

    def pre_migrate_checks; end

    before do
      queue_name_from_worker_name = Gitlab::SidekiqConfig::WorkerRouter.method(:queue_name_from_worker_name)
      EmailReceiverWorker.sidekiq_options(queue: queue_name_from_worker_name.call(EmailReceiverWorker))
      EmailReceiverWorker.perform_async('foo')
      EmailReceiverWorker.perform_async('bar')

      # test worker that has ':' inside the queue name
      AuthorizedProjectUpdate::ProjectRecalculateWorker.sidekiq_options(
        queue: queue_name_from_worker_name.call(AuthorizedProjectUpdate::ProjectRecalculateWorker)
      )
      AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async
    end

    after do
      # resets the queue name to its original
      EmailReceiverWorker.set_queue
      AuthorizedProjectUpdate::ProjectRecalculateWorker.set_queue
    end

    shared_examples 'migrating queues' do
      it 'migrates the jobs to the correct destination queue' do
        queues = list_queues
        expect(queues).to include(*queues_included_pre_migrate)
        expect(queues).not_to include(*queues_excluded_pre_migrate)
        pre_migrate_checks

        migrator.migrate_queues

        queues = list_queues
        expect(queues).not_to include(*queues_excluded_post_migrate)
        expect(queues).to include(*queues_included_post_migrate)
        post_migrate_checks
      end
    end

    context 'with all workers mapped to default queue' do
      let(:mappings) do
        { 'EmailReceiverWorker' => 'default', 'AuthorizedProjectUpdate::ProjectRecalculateWorker' => 'default' }
      end

      let(:queues_included_pre_migrate) do
        ['email_receiver',
         'authorized_project_update:authorized_project_update_project_recalculate']
      end

      let(:queues_excluded_pre_migrate) { ['default'] }
      let(:queues_excluded_post_migrate) do
        ['email_receiver',
         'authorized_project_update:authorized_project_update_project_recalculate']
      end

      let(:queues_included_post_migrate) { ['default'] }

      def post_migrate_checks
        jobs = list_jobs('default')
        expect(jobs.length).to eq(3)
        sorted = jobs.sort_by { |job| [job["class"], job["args"]] }
        expect(sorted[0]).to include('class' => 'AuthorizedProjectUpdate::ProjectRecalculateWorker',
          'queue' => 'default')
        expect(sorted[1]).to include('class' => 'EmailReceiverWorker', 'args' => ['bar'], 'queue' => 'default')
        expect(sorted[2]).to include('class' => 'EmailReceiverWorker', 'args' => ['foo'], 'queue' => 'default')
      end

      it_behaves_like 'migrating queues'
    end

    context 'with custom mapping to different queues' do
      let(:mappings) do
        { 'EmailReceiverWorker' => 'new_email',
          'AuthorizedProjectUpdate::ProjectRecalculateWorker' => 'new_authorized' }
      end

      let(:queues_included_pre_migrate) do
        ['email_receiver',
         'authorized_project_update:authorized_project_update_project_recalculate']
      end

      let(:queues_excluded_pre_migrate) { %w[new_email new_authorized] }
      let(:queues_excluded_post_migrate) do
        ['email_receiver',
         'authorized_project_update:authorized_project_update_project_recalculate']
      end

      let(:queues_included_post_migrate) { %w[new_email new_authorized] }

      def post_migrate_checks
        email_jobs = list_jobs('new_email')
        expect(email_jobs.length).to eq(2)
        expect(email_jobs[0]).to include('class' => 'EmailReceiverWorker', 'args' => ['bar'], 'queue' => 'new_email')
        expect(email_jobs[1]).to include('class' => 'EmailReceiverWorker', 'args' => ['foo'], 'queue' => 'new_email')

        export_jobs = list_jobs('new_authorized')
        expect(export_jobs.length).to eq(1)
        expect(export_jobs[0]).to include('class' => 'AuthorizedProjectUpdate::ProjectRecalculateWorker',
          'queue' => 'new_authorized')
      end

      it_behaves_like 'migrating queues'
    end

    context 'with illegal JSON payload' do
      let(:job) { '{foo: 1}' }
      let(:mappings) do
        { 'EmailReceiverWorker' => 'default', 'AuthorizedProjectUpdate::ProjectRecalculateWorker' => 'default' }
      end

      let(:queues_included_pre_migrate) do
        ['email_receiver',
         'authorized_project_update:authorized_project_update_project_recalculate']
      end

      let(:queues_excluded_pre_migrate) { ['default'] }
      let(:queues_excluded_post_migrate) do
        ['email_receiver',
         'authorized_project_update:authorized_project_update_project_recalculate']
      end

      let(:queues_included_post_migrate) { ['default'] }
      let(:logger) { Logger.new(StringIO.new) }

      before do
        Sidekiq.redis do |conn|
          conn.lpush("queue:email_receiver", job)
        end
      end

      def pre_migrate_checks
        expect(logger).to receive(:error)
                            .with(a_string_matching('Unmarshal JSON payload from SidekiqMigrateJobs failed'))
                            .once
      end

      def post_migrate_checks
        jobs = list_jobs('default')
        expect(jobs.length).to eq(3)
        sorted = jobs.sort_by { |job| [job["class"], job["args"]] }
        expect(sorted[0]).to include('class' => 'AuthorizedProjectUpdate::ProjectRecalculateWorker',
          'queue' => 'default')
        expect(sorted[1]).to include('class' => 'EmailReceiverWorker', 'args' => ['bar'], 'queue' => 'default')
        expect(sorted[2]).to include('class' => 'EmailReceiverWorker', 'args' => ['foo'], 'queue' => 'default')
      end

      it_behaves_like 'migrating queues'
    end

    context 'when multiple workers are in the same queue' do
      before do
        ExportCsvWorker.sidekiq_options(queue: 'email_receiver') # follows EmailReceiverWorker's queue
        ExportCsvWorker.perform_async('fizz')
      end

      after do
        ExportCsvWorker.set_queue
      end

      context 'when the queue exists in mappings' do
        let(:mappings) do
          { 'EmailReceiverWorker' => 'email_receiver', 'AuthorizedProjectUpdate::ProjectRecalculateWorker' => 'default',
            'ExportCsvWorker' => 'default' }
        end

        let(:queues_included_pre_migrate) do
          ['email_receiver',
           'authorized_project_update:authorized_project_update_project_recalculate']
        end

        let(:queues_excluded_pre_migrate) { ['default'] }
        let(:queues_excluded_post_migrate) do
          ['authorized_project_update:authorized_project_update_project_recalculate']
        end

        let(:queues_included_post_migrate) { %w[default email_receiver] }

        it_behaves_like 'migrating queues'
        def post_migrate_checks
          # jobs from email_receiver are not migrated at all
          jobs = list_jobs('email_receiver')
          expect(jobs.length).to eq(3)
          sorted = jobs.sort_by { |job| [job["class"], job["args"]] }
          expect(sorted[0]).to include('class' => 'EmailReceiverWorker', 'args' => ['bar'], 'queue' => 'email_receiver')
          expect(sorted[1]).to include('class' => 'EmailReceiverWorker', 'args' => ['foo'], 'queue' => 'email_receiver')
          expect(sorted[2]).to include('class' => 'ExportCsvWorker', 'args' => ['fizz'], 'queue' => 'email_receiver')
        end
      end

      context 'when the queue doesnt exist in mappings' do
        let(:mappings) do
          { 'EmailReceiverWorker' => 'default', 'AuthorizedProjectUpdate::ProjectRecalculateWorker' => 'default',
            'ExportCsvWorker' => 'default' }
        end

        let(:queues_included_pre_migrate) do
          ['email_receiver',
           'authorized_project_update:authorized_project_update_project_recalculate']
        end

        let(:queues_excluded_pre_migrate) { ['default'] }
        let(:queues_excluded_post_migrate) do
          ['email_receiver', 'authorized_project_update:authorized_project_update_project_recalculate']
        end

        let(:queues_included_post_migrate) { ['default'] }

        it_behaves_like 'migrating queues'
        def post_migrate_checks
          # jobs from email_receiver are all migrated
          jobs = list_jobs('email_receiver')
          expect(jobs.length).to eq(0)

          jobs = list_jobs('default')
          expect(jobs.length).to eq(4)
          sorted = jobs.sort_by { |job| [job["class"], job["args"]] }
          expect(sorted[0]).to include('class' => 'AuthorizedProjectUpdate::ProjectRecalculateWorker',
            'queue' => 'default')
          expect(sorted[1]).to include('class' => 'EmailReceiverWorker', 'args' => ['bar'], 'queue' => 'default')
          expect(sorted[2]).to include('class' => 'EmailReceiverWorker', 'args' => ['foo'], 'queue' => 'default')
          expect(sorted[3]).to include('class' => 'ExportCsvWorker', 'args' => ['fizz'], 'queue' => 'default')
        end
      end
    end
  end
end
