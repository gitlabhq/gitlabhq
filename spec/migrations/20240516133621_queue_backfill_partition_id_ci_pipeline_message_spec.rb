# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillPartitionIdCiPipelineMessage, migration: :gitlab_ci, feature_category: :ci_scaling do
  let!(:batched_migrations) { table(:batched_background_migrations) }
  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    context 'with migration present' do
      let!(:ci_backfill_partition_id_ci_pipeline_messages) do
        batched_migrations.create!(
          job_class_name: 'BackfillPartitionIdCiPipelineMessage',
          table_name: :ci_pipeline_messages,
          column_name: :id,
          job_arguments: [],
          interval: 2.minutes,
          min_value: 1,
          max_value: 2,
          batch_size: 1000,
          sub_batch_size: 100,
          gitlab_schema: :gitlab_ci,
          status: 3 # finished
        )
      end

      context 'when migration finished successfully' do
        it 'does not raise exception' do
          expect { migrate! }.not_to raise_error
        end

        it 'schedules background jobs for each batch of ci_pipeline_messages' do
          migrate!

          expect(migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_ci,
            table_name: :ci_pipeline_messages,
            column_name: :id,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        end
      end
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
