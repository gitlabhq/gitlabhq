# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillSecurityFindingsProjectId, migration: :gitlab_sec, feature_category: :vulnerability_management do
  let!(:batched_migration) { described_class::MIGRATION }
  let(:expected_job_args) { %i[project_id vulnerability_scanners project_id scanner_id] }

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
          sub_batch_size: described_class::GITLAB_OPTIMIZED_SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_sec,
          job_arguments: expected_job_args
        )
      }
    end
  end
end
