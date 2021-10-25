# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::StealMigrateMergeRequestDiffCommitUsers, schema: 20211012134316 do
  let(:migration) { described_class.new }

  describe '#perform' do
    it 'processes the background migration' do
      spy = instance_spy(
        Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers
      )

      allow(Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers)
        .to receive(:new)
        .and_return(spy)

      expect(spy).to receive(:perform).with(1, 4)
      expect(migration).to receive(:schedule_next_job)

      migration.perform(1, 4)
    end
  end

  describe '#schedule_next_job' do
    it 'schedules the next job in ascending order' do
      Gitlab::Database::BackgroundMigrationJob.create!(
        class_name: 'MigrateMergeRequestDiffCommitUsers',
        arguments: [10, 20]
      )

      Gitlab::Database::BackgroundMigrationJob.create!(
        class_name: 'MigrateMergeRequestDiffCommitUsers',
        arguments: [40, 50]
      )

      expect(BackgroundMigrationWorker)
        .to receive(:perform_in)
        .with(5.minutes, 'StealMigrateMergeRequestDiffCommitUsers', [10, 20])

      migration.schedule_next_job
    end

    it 'does not schedule any new jobs when there are none' do
      expect(BackgroundMigrationWorker).not_to receive(:perform_in)

      migration.schedule_next_job
    end
  end
end
