# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SliceMergeRequestDiffCommitMigrations, :migration, feature_category: :code_review_workflow do
  let(:migration) { described_class.new }

  describe '#up' do
    context 'when there are no jobs to process' do
      it 'does nothing' do
        expect(migration).not_to receive(:migrate_in)
        expect(Gitlab::Database::BackgroundMigrationJob).not_to receive(:create!)

        migration.up
      end
    end

    context 'when there are pending jobs' do
      let!(:job1) do
        Gitlab::Database::BackgroundMigrationJob.create!(
          class_name: described_class::MIGRATION_CLASS,
          arguments: [1, 10_001]
        )
      end

      let!(:job2) do
        Gitlab::Database::BackgroundMigrationJob.create!(
          class_name: described_class::MIGRATION_CLASS,
          arguments: [10_001, 20_001]
        )
      end

      it 'marks the old jobs as finished' do
        migration.up

        job1.reload
        job2.reload

        expect(job1).to be_succeeded
        expect(job2).to be_succeeded
      end

      it 'the jobs are slices into smaller ranges' do
        migration.up

        new_jobs = Gitlab::Database::BackgroundMigrationJob
          .for_migration_class(described_class::MIGRATION_CLASS)
          .pending
          .to_a

        expect(new_jobs.map(&:arguments)).to eq(
          [
            [1, 5_001],
            [5_001, 10_001],
            [10_001, 15_001],
            [15_001, 20_001]
          ])
      end

      it 'schedules a background migration for the first job' do
        expect(migration)
          .to receive(:migrate_in)
          .with(1.hour, described_class::STEAL_MIGRATION_CLASS, [1, 5_001])

        migration.up
      end
    end
  end
end
