# frozen_string_literal: true

require 'spec_helper'
require_migration! 'steal_merge_request_diff_commit_users_migration'

RSpec.describe StealMergeRequestDiffCommitUsersMigration, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    it 'schedules a job if there are pending jobs' do
      Gitlab::Database::BackgroundMigrationJob.create!(
        class_name: 'MigrateMergeRequestDiffCommitUsers',
        arguments: [10, 20]
      )

      expect(migration)
        .to receive(:migrate_in)
        .with(1.hour, 'StealMigrateMergeRequestDiffCommitUsers', [10, 20])

      migration.up
    end

    it 'does not schedule any jobs when all jobs have been completed' do
      expect(migration).not_to receive(:migrate_in)

      migration.up
    end
  end
end
