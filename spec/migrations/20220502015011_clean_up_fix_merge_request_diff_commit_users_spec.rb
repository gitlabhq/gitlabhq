# frozen_string_literal: true

require 'spec_helper'
require_migration! 'clean_up_fix_merge_request_diff_commit_users'

RSpec.describe CleanUpFixMergeRequestDiffCommitUsers, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_namespace) { namespaces.create!(name: 'project2', path: 'project2', type: 'Project') }
  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }

  describe '#up' do
    it 'finalizes the background migration' do
      expect(described_class).to be_finalize_background_migration_of('FixMergeRequestDiffCommitUsers')

      migrate!
    end

    it 'processes pending background jobs' do
      project = projects.create!(name: 'p1', namespace_id: namespace.id, project_namespace_id: project_namespace.id)

      Gitlab::Database::BackgroundMigrationJob.create!(
        class_name: 'FixMergeRequestDiffCommitUsers',
        arguments: [project.id]
      )

      migrate!

      background_migrations = Gitlab::Database::BackgroundMigrationJob
        .where(class_name: 'FixMergeRequestDiffCommitUsers')

      expect(background_migrations.count).to eq(0)
    end
  end
end
