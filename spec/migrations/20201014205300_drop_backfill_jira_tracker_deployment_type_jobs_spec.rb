# frozen_string_literal: true

require 'spec_helper'
require_migration!('drop_backfill_jira_tracker_deployment_type_jobs')

RSpec.describe DropBackfillJiraTrackerDeploymentTypeJobs, :sidekiq, :redis, schema: 2020_10_14_205300 do
  subject(:migration) { described_class.new }

  describe '#up' do
    let(:retry_set) { Sidekiq::RetrySet.new }
    let(:scheduled_set) { Sidekiq::ScheduledSet.new }

    context 'there are only affected jobs on the queue' do
      let(:payload) { { 'class' => ::BackgroundMigrationWorker, 'args' => [described_class::DROPPED_JOB_CLASS, 1] } }
      let(:queue_payload) { payload.merge('queue' => described_class::QUEUE) }

      it 'removes enqueued BackfillJiraTrackerDeploymentType background jobs' do
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

    context 'there are not any affected jobs on the queue' do
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

    context 'other queues' do
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
