# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMigrateJobs, :clean_gitlab_redis_queues do
  def clear_queues
    Sidekiq::Queue.new('authorized_projects').clear
    Sidekiq::Queue.new('post_receive').clear
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
  end

  around do |example|
    clear_queues
    Sidekiq::Testing.disable!(&example)
    clear_queues
  end

  describe '#execute', :aggregate_failures do
    shared_examples 'processing a set' do
      let(:migrator) { described_class.new(set_name) }

      let(:set_after) do
        Sidekiq.redis { |c| c.zrange(set_name, 0, -1, with_scores: true) }
          .map { |item, score| [Sidekiq.load_json(item), score] }
      end

      context 'when the set is empty' do
        it 'returns the number of scanned and migrated jobs' do
          expect(migrator.execute('AuthorizedProjectsWorker' => 'new_queue')).to eq(scanned: 0, migrated: 0)
        end
      end

      context 'when the set is not empty' do
        it 'returns the number of scanned and migrated jobs' do
          create_jobs

          expect(migrator.execute({})).to eq(scanned: 4, migrated: 0)
        end
      end

      context 'when there are no matching jobs' do
        it 'does not change any queue names' do
          create_jobs(include_post_receive: false)

          expect(migrator.execute('PostReceive' => 'new_queue')).to eq(scanned: 3, migrated: 0)

          expect(set_after.length).to eq(3)
          expect(set_after.map(&:first)).to all(include('queue' => 'authorized_projects',
                                                        'class' => 'AuthorizedProjectsWorker'))
        end
      end

      context 'when there are matching jobs' do
        it 'migrates only the workers matching the given worker from the set' do
          freeze_time do
            create_jobs

            expect(migrator.execute('AuthorizedProjectsWorker' => 'new_queue')).to eq(scanned: 4, migrated: 3)

            set_after.each.with_index do |(item, score), i|
              if item['class'] == 'AuthorizedProjectsWorker'
                expect(item).to include('queue' => 'new_queue', 'args' => [i])
              else
                expect(item).to include('queue' => 'post_receive', 'args' => [i])
              end

              expect(score).to eq(i.succ.hours.from_now.to_i)
            end
          end
        end

        it 'allows migrating multiple workers at once' do
          freeze_time do
            create_jobs

            expect(migrator.execute('AuthorizedProjectsWorker' => 'new_queue', 'PostReceive' => 'another_queue'))
              .to eq(scanned: 4, migrated: 4)

            set_after.each.with_index do |(item, score), i|
              if item['class'] == 'AuthorizedProjectsWorker'
                expect(item).to include('queue' => 'new_queue', 'args' => [i])
              else
                expect(item).to include('queue' => 'another_queue', 'args' => [i])
              end

              expect(score).to eq(i.succ.hours.from_now.to_i)
            end
          end
        end

        it 'allows migrating multiple workers to the same queue' do
          freeze_time do
            create_jobs

            expect(migrator.execute('AuthorizedProjectsWorker' => 'new_queue', 'PostReceive' => 'new_queue'))
              .to eq(scanned: 4, migrated: 4)

            set_after.each.with_index do |(item, score), i|
              expect(item).to include('queue' => 'new_queue', 'args' => [i])
              expect(score).to eq(i.succ.hours.from_now.to_i)
            end
          end
        end

        it 'does not try to migrate jobs that are removed from the set during the migration' do
          freeze_time do
            create_jobs

            allow(migrator).to receive(:migrate_job).and_wrap_original do |meth, *args|
              Sidekiq.redis { |c| c.zrem(set_name, args.first) }

              meth.call(*args)
            end

            expect(migrator.execute('PostReceive' => 'new_queue')).to eq(scanned: 4, migrated: 0)

            expect(set_after.length).to eq(3)
            expect(set_after.map(&:first)).to all(include('queue' => 'authorized_projects'))
          end
        end

        it 'does not try to migrate unmatched jobs that are added to the set during the migration' do
          create_jobs

          calls = 0

          allow(migrator).to receive(:migrate_job).and_wrap_original do |meth, *args|
            if calls == 0
              travel_to(5.hours.from_now) { create_jobs(include_post_receive: false) }
            end

            calls += 1

            meth.call(*args)
          end

          expect(migrator.execute('PostReceive' => 'new_queue')).to eq(scanned: 4, migrated: 1)

          expect(set_after.group_by { |job| job.first['queue'] }.transform_values(&:count))
            .to eq('authorized_projects' => 6, 'new_queue' => 1)
        end

        it 'iterates through the entire set of jobs' do
          50.times do |i|
            travel_to(i.hours.from_now) { create_jobs }
          end

          expect(migrator.execute('NonExistentWorker' => 'new_queue')).to eq(scanned: 200, migrated: 0)

          expect(set_after.length).to eq(200)
        end

        it 'logs output at the start, finish, and every LOG_FREQUENCY jobs' do
          freeze_time do
            create_jobs

            stub_const("#{described_class}::LOG_FREQUENCY", 2)

            logger = Logger.new(StringIO.new)
            migrator = described_class.new(set_name, logger: logger)

            expect(logger).to receive(:info).with(a_string_matching('Processing')).once.ordered
            expect(logger).to receive(:info).with(a_string_matching('In progress')).once.ordered
            expect(logger).to receive(:info).with(a_string_matching('Done')).once.ordered

            expect(migrator.execute('AuthorizedProjectsWorker' => 'new_queue', 'PostReceive' => 'new_queue'))
              .to eq(scanned: 4, migrated: 4)
          end
        end
      end
    end

    context 'scheduled jobs' do
      let(:set_name) { 'schedule' }

      def create_jobs(include_post_receive: true)
        AuthorizedProjectsWorker.perform_in(1.hour, 0)
        AuthorizedProjectsWorker.perform_in(2.hours, 1)
        PostReceive.perform_in(3.hours, 2) if include_post_receive
        AuthorizedProjectsWorker.perform_in(4.hours, 3)
      end

      it_behaves_like 'processing a set'
    end

    context 'retried jobs' do
      let(:set_name) { 'retry' }

      # Try to mimic as closely as possible what Sidekiq will actually
      # do to retry a job.
      def retry_in(klass, time, args)
        # In Sidekiq 6, this argument will become a JSON string
        message = { 'class' => klass, 'args' => [args], 'retry' => true }

        allow(klass).to receive(:sidekiq_retry_in_block).and_return(proc { time })

        begin
          Sidekiq::JobRetry.new.local(klass, message, klass.queue) { raise 'boom' }
        rescue Sidekiq::JobRetry::Skip
          # Sidekiq scheduled the retry
        end
      end

      def create_jobs(include_post_receive: true)
        retry_in(AuthorizedProjectsWorker, 1.hour, 0)
        retry_in(AuthorizedProjectsWorker, 2.hours, 1)
        retry_in(PostReceive, 3.hours, 2) if include_post_receive
        retry_in(AuthorizedProjectsWorker, 4.hours, 3)
      end

      it_behaves_like 'processing a set'
    end
  end
end
