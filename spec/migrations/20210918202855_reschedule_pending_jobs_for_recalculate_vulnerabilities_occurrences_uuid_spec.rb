# frozen_string_literal: true
require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20210918202855_reschedule_pending_jobs_for_recalculate_vulnerabilities_occurrences_uuid.rb')

RSpec.describe ReschedulePendingJobsForRecalculateVulnerabilitiesOccurrencesUuid, :migration do
  let_it_be(:background_migration_jobs) { table(:background_migration_jobs) }

  context 'when RecalculateVulnerabilitiesOccurrencesUuid jobs are pending' do
    before do
      background_migration_jobs.create!(
        class_name: 'RecalculateVulnerabilitiesOccurrencesUuid',
        arguments: [1, 2, 3],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']
      )
      background_migration_jobs.create!(
        class_name: 'RecalculateVulnerabilitiesOccurrencesUuid',
        arguments: [4, 5, 6],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
      )
    end

    it 'queues pending jobs' do
      migrate!

      expect(BackgroundMigrationWorker.jobs.length).to eq(1)
      expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['RecalculateVulnerabilitiesOccurrencesUuid', [1, 2, 3]])
      expect(BackgroundMigrationWorker.jobs[0]['at']).to be_nil
    end
  end
end
