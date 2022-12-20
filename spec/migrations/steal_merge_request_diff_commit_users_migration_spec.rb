# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe StealMergeRequestDiffCommitUsersMigration, :migration, feature_category: :source_code_management do
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
