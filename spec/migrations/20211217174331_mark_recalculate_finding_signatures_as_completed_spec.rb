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

RSpec.describe MarkRecalculateFindingSignaturesAsCompleted, :migration, feature_category: :vulnerability_management do
  let!(:background_migration_jobs) { table(:background_migration_jobs) }

  context 'when RecalculateVulnerabilitiesOccurrencesUuid jobs are present' do
    before do
      create_background_migration_jobs([1, 2, 3], :succeeded, DateTime.new(2021, 5, 5, 0, 2))
      create_background_migration_jobs([4, 5, 6], :pending, DateTime.new(2021, 5, 5, 0, 4))

      create_background_migration_jobs([1, 2, 3], :succeeded, DateTime.new(2021, 8, 18, 0, 0))
      create_background_migration_jobs([4, 5, 6], :pending, DateTime.new(2021, 8, 18, 0, 2))
      create_background_migration_jobs([7, 8, 9], :pending, DateTime.new(2021, 8, 18, 0, 4))
    end

    describe 'gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      it 'marks all jobs as succeeded' do
        expect(background_migration_jobs.where(status: 1).count).to eq(2)

        migrate!

        expect(background_migration_jobs.where(status: 1).count).to eq(5)
      end
    end

    describe 'self managed' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not change job status' do
        expect(background_migration_jobs.where(status: 1).count).to eq(2)

        migrate!

        expect(background_migration_jobs.where(status: 1).count).to eq(2)
      end
    end
  end
end
