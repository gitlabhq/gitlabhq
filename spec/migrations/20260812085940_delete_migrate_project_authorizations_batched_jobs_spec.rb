# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteMigrateProjectAuthorizationsBatchedJobs, migration: :gitlab_main,
  feature_category: :user_management do
  let(:batched_migrations) { Gitlab::Database::BackgroundMigration::BatchedMigration }
  let(:batched_jobs) { table(:batched_background_migration_jobs) }

  let(:batch_min_delay) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_MIN_DELAY }
  let(:batch_class_name) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_CLASS_NAME }
  let(:batch_size) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_SIZE }
  let(:sub_batch_size) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::SUB_BATCH_SIZE }

  let!(:previous_run) { create_batched_migration(described_class::MIGRATION, described_class::TABLE_NAME) }
  let!(:other_migration) { create_batched_migration('OtherMigration', :users) }

  let!(:previous_run_jobs) { Array.new(2) { create_batched_job(previous_run) } }
  let!(:other_migration_job) { create_batched_job(other_migration) }

  it 'deletes only the job rows of the previous run' do
    migrate!

    expect(batched_jobs.where(batched_background_migration_id: previous_run.id)).to be_empty
    expect(batched_jobs.where(batched_background_migration_id: other_migration.id).count).to eq(1)
  end

  it 'keeps the batched migration records themselves' do
    migrate!

    expect(batched_migrations.where(id: [previous_run.id, other_migration.id]).count).to eq(2)
  end

  def create_batched_migration(job_class_name, table_name)
    batched_migrations.create!(
      gitlab_schema: :gitlab_main,
      job_class_name: job_class_name,
      job_arguments: [],
      table_name: table_name,
      column_name: :user_id,
      min_cursor: [0, 0, 0],
      max_cursor: [100, 100, 50],
      interval: batch_min_delay,
      batch_class_name: batch_class_name,
      batch_size: batch_size,
      sub_batch_size: sub_batch_size,
      status_event: :finish
    )
  end

  def create_batched_job(migration)
    batched_jobs.create!(
      batched_background_migration_id: migration.id,
      min_cursor: [0, 0, 0],
      max_cursor: [100, 100, 50],
      batch_size: batch_size,
      sub_batch_size: sub_batch_size
    )
  end
end
