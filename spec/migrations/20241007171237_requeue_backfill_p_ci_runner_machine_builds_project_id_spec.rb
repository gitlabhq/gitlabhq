# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillPCiRunnerMachineBuildsProjectId, migration: :gitlab_ci, feature_category: :fleet_visibility do
  let!(:batched_migration) { described_class::MIGRATION }
  let(:expected_job_args) { %i[project_id p_ci_builds project_id build_id partition_id] }

  it 'does not schedule a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end

  context 'when executed on .com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: described_class::TABLE_NAME,
            column_name: :build_id,
            interval: described_class::DELAY_INTERVAL,
            max_batch_size: described_class::MAX_BATCH_SIZE,
            batch_size: described_class::GITLAB_OPTIMIZED_BATCH_SIZE,
            sub_batch_size: described_class::GITLAB_OPTIMIZED_SUB_BATCH_SIZE,
            gitlab_schema: :gitlab_ci,
            job_arguments: expected_job_args
          )
        }
      end
    end
  end
end
