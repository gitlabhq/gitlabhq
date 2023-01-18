# frozen_string_literal: true

require 'spec_helper'
require_migration! 'schedule_fix_merge_request_diff_commit_users_migration'

RSpec.describe ScheduleFixMergeRequestDiffCommitUsersMigration, :migration, feature_category: :code_review_workflow do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }

  describe '#up' do
    it 'does nothing when there are no projects to correct' do
      migration.up

      expect(Gitlab::Database::BackgroundMigrationJob.count).to be_zero
    end

    it 'schedules imported projects created after July' do
      project = projects.create!(
        namespace_id: namespace.id,
        import_type: 'gitlab_project',
        created_at: '2021-08-01'
      )

      expect(migration)
        .to receive(:migrate_in)
        .with(2.minutes, 'FixMergeRequestDiffCommitUsers', [project.id])

      migration.up

      expect(Gitlab::Database::BackgroundMigrationJob.count).to eq(1)

      job = Gitlab::Database::BackgroundMigrationJob.first

      expect(job.class_name).to eq('FixMergeRequestDiffCommitUsers')
      expect(job.arguments).to eq([project.id])
    end

    it 'ignores projects imported before July' do
      projects.create!(
        namespace_id: namespace.id,
        import_type: 'gitlab_project',
        created_at: '2020-08-01'
      )

      migration.up

      expect(Gitlab::Database::BackgroundMigrationJob.count).to be_zero
    end

    it 'ignores projects that are not imported' do
      projects.create!(
        namespace_id: namespace.id,
        created_at: '2021-08-01'
      )

      migration.up

      expect(Gitlab::Database::BackgroundMigrationJob.count).to be_zero
    end
  end
end
