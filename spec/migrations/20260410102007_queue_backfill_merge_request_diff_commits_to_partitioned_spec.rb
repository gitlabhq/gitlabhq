# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillMergeRequestDiffCommitsToPartitioned, migration: :gitlab_main_org,
  feature_category: :code_review_workflow do
  let(:migration_name) { described_class::MIGRATION }
  let(:view_prefix) { described_class::VIEW_PREFIX }
  let(:view_lower_bounds) { described_class::VIEW_LOWER_BOUNDS }

  context 'when on GitLab.com', :aggregate_failures do
    let(:diff_commits) { table(:merge_request_diff_commits) }
    let(:last_diff_id) { view_lower_bounds.last + 100 }

    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)

      # Create the views that should exist from the previous migration
      view_lower_bounds.each_with_index do |lower, index|
        upper = view_lower_bounds[index + 1]
        create_view(index + 1, lower, upper)
      end

      # Insert a row so max_cursor_from_table returns a real value for the last (open-ended) view
      diff_commits.create!(merge_request_diff_id: last_diff_id, relative_order: 0)
    end

    describe '#up' do
      it 'schedules 4 batched migrations on views' do
        reversible_migration do |migration|
          migration.before -> {
            expect(migration_name).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            # Verify all 4 view-based migrations were scheduled
            view_lower_bounds.each_with_index do |_, index|
              expect(migration_name).to have_scheduled_batched_migration(
                gitlab_schema: :gitlab_main_org,
                table_name: "#{view_prefix}_#{index + 1}",
                column_name: :merge_request_diff_id,
                interval: described_class::DELAY_INTERVAL,
                batch_size: described_class::BATCH_SIZE,
                sub_batch_size: described_class::SUB_BATCH_SIZE,
                job_arguments: %w[merge_request_diff_commits_b5377a7a34]
              )
            end
          }
        end
      end

      it 'sets correct min and max cursors for each view' do
        migrate!

        view_lower_bounds.each_with_index do |lower, index|
          view_number = index + 1
          upper = view_lower_bounds[index + 1]

          migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_by(
            job_class_name: migration_name,
            table_name: "#{view_prefix}_#{view_number}"
          )

          expect(migration).to be_present
          expect(migration.min_cursor).to eq([lower, 0])

          if upper
            expect(migration.max_cursor).to eq([upper, 0])
          else
            # Last view is open-ended; max_cursor is derived from actual table max
            expect(migration.max_cursor).to eq([last_diff_id, 0])
          end
        end
      end
    end

    describe '#down' do
      it 'deletes all view-based migrations' do
        migrate!

        (1..4).each do |view_number|
          expect(
            Gitlab::Database::BackgroundMigration::BatchedMigration.exists?(
              job_class_name: migration_name,
              table_name: "#{view_prefix}_#{view_number}"
            )
          ).to be true
        end

        schema_migrate_down!

        (1..4).each do |view_number|
          expect(
            Gitlab::Database::BackgroundMigration::BatchedMigration.exists?(
              job_class_name: migration_name,
              table_name: "#{view_prefix}_#{view_number}"
            )
          ).to be false
        end
      end
    end
  end

  context 'when not on GitLab.com', :aggregate_failures do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    describe '#up' do
      it 'schedules a single batched migration on the full table' do
        reversible_migration do |migration|
          migration.before -> {
            expect(migration_name).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            expect(migration_name).to have_scheduled_batched_migration(
              gitlab_schema: :gitlab_main_org,
              table_name: :merge_request_diff_commits,
              column_name: :merge_request_diff_id,
              interval: described_class::DELAY_INTERVAL,
              batch_size: described_class::BATCH_SIZE,
              sub_batch_size: described_class::SUB_BATCH_SIZE,
              job_arguments: %w[merge_request_diff_commits_b5377a7a34]
            )
          }
        end
      end

      it 'does not schedule view-based migrations' do
        migrate!

        (1..4).each do |view_number|
          migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_by(
            job_class_name: migration_name,
            table_name: "#{view_prefix}_#{view_number}"
          )

          expect(migration).to be_nil
        end
      end
    end

    describe '#down' do
      it 'deletes the single table-based migration' do
        migrate!

        expect(
          Gitlab::Database::BackgroundMigration::BatchedMigration.exists?(
            job_class_name: migration_name,
            table_name: :merge_request_diff_commits
          )
        ).to be true

        schema_migrate_down!

        expect(
          Gitlab::Database::BackgroundMigration::BatchedMigration.exists?(
            job_class_name: migration_name,
            table_name: :merge_request_diff_commits
          )
        ).to be false
      end
    end
  end

  private

  def create_view(view_number, lower, upper)
    upper_clause = upper ? "AND merge_request_diff_id < #{upper}" : ""

    ApplicationRecord.connection.execute(<<~SQL.squish)
      CREATE OR REPLACE VIEW #{view_prefix}_#{view_number} AS
      SELECT merge_request_diff_id, relative_order
      FROM merge_request_diff_commits
      WHERE merge_request_diff_id >= #{lower}
      #{upper_clause}
    SQL
  end
end
