# frozen_string_literal: true

require 'spec_helper'
require_migration!

def create_background_migration_jobs(ids, status, created_at)
  proper_status = case status
                  when :pending
                    Gitlab::Database::BackgroundMigrationJob.statuses['pending']
                  when :succeeded
                    Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
                  else
                    raise ArgumentError
                  end

  background_migration_jobs.create!(
    class_name: 'RecalculateVulnerabilitiesOccurrencesUuid',
    arguments: Array(ids),
    status: proper_status,
    created_at: created_at
  )
end

RSpec.describe RemoveOldPendingJobsForRecalculateVulnerabilitiesOccurrencesUuid, :migration,
feature_category: :vulnerability_management do
  let!(:background_migration_jobs) { table(:background_migration_jobs) }
  let!(:before_target_date) { -Float::INFINITY..(DateTime.new(2021, 8, 17, 23, 59, 59)) }
  let!(:after_target_date) { (DateTime.new(2021, 8, 18, 0, 0, 0))..Float::INFINITY }

  context 'when old RecalculateVulnerabilitiesOccurrencesUuid jobs are pending' do
    before do
      create_background_migration_jobs([1, 2, 3], :succeeded, DateTime.new(2021, 5, 5, 0, 2))
      create_background_migration_jobs([4, 5, 6], :pending, DateTime.new(2021, 5, 5, 0, 4))

      create_background_migration_jobs([1, 2, 3], :succeeded, DateTime.new(2021, 8, 18, 0, 0))
      create_background_migration_jobs([4, 5, 6], :pending, DateTime.new(2021, 8, 18, 0, 2))
      create_background_migration_jobs([7, 8, 9], :pending, DateTime.new(2021, 8, 18, 0, 4))
    end

    it 'removes old, pending jobs' do
      migrate!

      expect(background_migration_jobs.where(created_at: before_target_date).count).to eq(1)
      expect(background_migration_jobs.where(created_at: after_target_date).count).to eq(3)
    end
  end
end
