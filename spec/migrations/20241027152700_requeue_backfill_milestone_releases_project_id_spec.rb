# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillMilestoneReleasesProjectId, feature_category: :release_orchestration do
  let!(:batched_migration) { described_class::MIGRATION }
  let(:expected_job_args) { %i[project_id releases project_id release_id] }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: described_class::TABLE_NAME,
          column_name: described_class::BATCH_COLUMN,
          interval: described_class::DELAY_INTERVAL,
          max_batch_size: described_class::MAX_BATCH_SIZE,
          batch_size: described_class::GITLAB_OPTIMIZED_BATCH_SIZE,
          batch_class_name: 'LooseIndexScanBatchingStrategy',
          sub_batch_size: described_class::GITLAB_OPTIMIZED_SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_main_cell,
          job_arguments: expected_job_args
        )
      }
    end
  end
end
