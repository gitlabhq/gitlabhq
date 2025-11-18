# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnqueueBackfillMergeRequestDiffFilesPartitionedTable, migration: :gitlab_main_org, feature_category: :source_code_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main_org,
          table_name: :merge_request_diff_files,
          column_name: :merge_request_diff_id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          job_arguments: %w[merge_request_diff_files_99208b8fac merge_request_diff_id relative_order]
        )
      }
    end
  end
end
