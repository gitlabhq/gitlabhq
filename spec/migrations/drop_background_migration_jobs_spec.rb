# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropBackgroundMigrationJobs, :sidekiq, :redis, schema: 2020_01_16_051619 do
  subject(:migration) { described_class.new }

  describe '#up' do
    context 'there are only affected jobs on the queue' do
      it 'removes enqueued ActivatePrometheusServicesForSharedClusterApplications background jobs' do
        Sidekiq::Testing.disable! do # https://github.com/mperham/sidekiq/wiki/testing#api Sidekiq's API does not have a testing mode
          Sidekiq::Client.push('queue' => described_class::QUEUE, 'class' => ::BackgroundMigrationWorker, 'args' => [described_class::DROPPED_JOB_CLASS, 1])

          expect { migration.up }.to change { Sidekiq::Queue.new(described_class::QUEUE).size }.from(1).to(0)
        end
      end
    end

    context "there aren't any affected jobs on the queue" do
      it 'skips other enqueued jobs' do
        Sidekiq::Testing.disable! do
          Sidekiq::Client.push('queue' => described_class::QUEUE, 'class' => ::BackgroundMigrationWorker, 'args' => ['SomeOtherClass', 1])

          expect { migration.up }.not_to change { Sidekiq::Queue.new(described_class::QUEUE).size }
        end
      end
    end

    context "there are multiple types of jobs on the queue" do
      it 'skips other enqueued jobs' do
        Sidekiq::Testing.disable! do
          queue = Sidekiq::Queue.new(described_class::QUEUE)
          # this job will be deleted
          Sidekiq::Client.push('queue' => described_class::QUEUE, 'class' => ::BackgroundMigrationWorker, 'args' => [described_class::DROPPED_JOB_CLASS, 1])
          # this jobs will be skipped
          skipped_jobs_args = [['SomeOtherClass', 1], [described_class::DROPPED_JOB_CLASS, 'wrong id type'], [described_class::DROPPED_JOB_CLASS, 1, 'some wired argument']]
          skipped_jobs_args.each do |args|
            Sidekiq::Client.push('queue' => described_class::QUEUE, 'class' => ::BackgroundMigrationWorker, 'args' => args)
          end

          migration.up

          expect(queue.size).to be 3
          expect(queue.map(&:args)).to match_array skipped_jobs_args
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
