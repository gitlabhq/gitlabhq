# frozen_string_literal: true

require 'spec_helper'
require_migration! 'clean_up_migrate_merge_request_diff_commit_users'

RSpec.describe CleanUpMigrateMergeRequestDiffCommitUsers, :migration, feature_category: :code_review_workflow do
  describe '#up' do
    context 'when there are pending jobs' do
      it 'processes the jobs immediately' do
        Gitlab::Database::BackgroundMigrationJob.create!(
          class_name: 'MigrateMergeRequestDiffCommitUsers',
          status: :pending,
          arguments: [10, 20]
        )

        spy = Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers
        migration = described_class.new

        allow(Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers)
          .to receive(:new)
          .and_return(spy)

        expect(migration).to receive(:say)
        expect(spy).to receive(:perform).with(10, 20)

        migration.up
      end
    end

    context 'when all jobs are completed' do
      it 'does nothing' do
        Gitlab::Database::BackgroundMigrationJob.create!(
          class_name: 'MigrateMergeRequestDiffCommitUsers',
          status: :succeeded,
          arguments: [10, 20]
        )

        migration = described_class.new

        expect(migration).not_to receive(:say)
        expect(Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers)
          .not_to receive(:new)

        migration.up
      end
    end
  end
end
