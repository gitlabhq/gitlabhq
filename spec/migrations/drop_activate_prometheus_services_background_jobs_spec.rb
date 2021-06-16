# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropActivatePrometheusServicesBackgroundJobs, :sidekiq, :redis, schema: 2020_02_21_144534 do
  subject(:migration) { described_class.new }

  describe '#up' do
    let(:retry_set) { Sidekiq::RetrySet.new }
    let(:scheduled_set) { Sidekiq::ScheduledSet.new }

    context 'there are only affected jobs on the queue' do
      let(:payload) { { 'class' => ::BackgroundMigrationWorker, 'args' => [described_class::DROPPED_JOB_CLASS, 1] } }
      let(:queue_payload) { payload.merge('queue' => described_class::QUEUE) }

      it 'removes enqueued ActivatePrometheusServicesForSharedClusterApplications background jobs' do
        Sidekiq::Testing.disable! do # https://github.com/mperham/sidekiq/wiki/testing#api Sidekiq's API does not have a testing mode
          retry_set.schedule(1.hour.from_now, payload)
          scheduled_set.schedule(1.hour.from_now, payload)
          Sidekiq::Client.push(queue_payload)

          expect { migration.up }.to change { Sidekiq::Queue.new(described_class::QUEUE).size }.from(1).to(0)
          expect(retry_set.size).to eq(0)
          expect(scheduled_set.size).to eq(0)
        end
      end
    end

    context "there aren't any affected jobs on the queue" do
      let(:payload) { { 'class' => ::BackgroundMigrationWorker, 'args' => ['SomeOtherClass', 1] } }
      let(:queue_payload) { payload.merge('queue' => described_class::QUEUE) }

      it 'skips other enqueued jobs' do
        Sidekiq::Testing.disable! do
          retry_set.schedule(1.hour.from_now, payload)
          scheduled_set.schedule(1.hour.from_now, payload)
          Sidekiq::Client.push(queue_payload)

          expect { migration.up }.not_to change { Sidekiq::Queue.new(described_class::QUEUE).size }
          expect(retry_set.size).to eq(1)
          expect(scheduled_set.size).to eq(1)
        end
      end
    end

    context "there are multiple types of jobs on the queue" do
      let(:payload) { { 'class' => ::BackgroundMigrationWorker, 'args' => [described_class::DROPPED_JOB_CLASS, 1] } }
      let(:queue_payload) { payload.merge('queue' => described_class::QUEUE) }

      it 'skips other enqueued jobs' do
        Sidekiq::Testing.disable! do
          queue = Sidekiq::Queue.new(described_class::QUEUE)
          # these jobs will be deleted
          retry_set.schedule(1.hour.from_now, payload)
          scheduled_set.schedule(1.hour.from_now, payload)
          Sidekiq::Client.push(queue_payload)
          # this jobs will be skipped
          skipped_jobs_args = [['SomeOtherClass', 1], [described_class::DROPPED_JOB_CLASS, 'wrong id type'], [described_class::DROPPED_JOB_CLASS, 1, 'some wired argument']]
          skipped_jobs_args.each do |args|
            retry_set.schedule(1.hour.from_now, { 'class' => ::BackgroundMigrationWorker, 'args' => args })
            scheduled_set.schedule(1.hour.from_now, { 'class' => ::BackgroundMigrationWorker, 'args' => args })
            Sidekiq::Client.push('queue' => described_class::QUEUE, 'class' => ::BackgroundMigrationWorker, 'args' => args)
          end

          migration.up

          expect(retry_set.size).to be 3
          expect(scheduled_set.size).to be 3
          expect(queue.size).to be 3
          expect(queue.map(&:args)).to match_array skipped_jobs_args
          expect(retry_set.map(&:args)).to match_array skipped_jobs_args
          expect(scheduled_set.map(&:args)).to match_array skipped_jobs_args
        end
      end
    end

    context "other queues" do
      it 'does not modify them' do
        Sidekiq::Testing.disable! do
          Sidekiq::Client.push('queue' => 'other', 'class' => ::BackgroundMigrationWorker, 'args' => ['SomeOtherClass', 1])
          Sidekiq::Client.push('queue' => 'other', 'class' => ::BackgroundMigrationWorker, 'args' => [described_class::DROPPED_JOB_CLASS, 1])

          expect { migration.up }.not_to change { Sidekiq::Queue.new('other').size }
        end
      end
    end
  end
end
