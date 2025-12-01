# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixTotalTupleCountForBackfillMergeRequestFileDiffsPartitionedTable, migration: :gitlab_main_org,
  feature_category: :source_code_management do
  let!(:migration) do
    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      job_class_name: 'BackfillMergeRequestFileDiffsPartitionedTable',
      table_name: :merge_request_diff_files,
      column_name: :merge_request_diff_id,
      job_arguments: %w[merge_request_diff_files_99208b8fac merge_request_diff_id relative_order],
      interval: 120,
      min_value: 1,
      max_value: 2,
      batch_size: 1000,
      sub_batch_size: 200,
      pause_ms: 100,
      gitlab_schema: :gitlab_main_org,
      status: 1,
      total_tuple_count: nil
    )
  end

  describe '#up' do
    it 'updates the total_tuple_count for the batched migration' do
      # Mock the cardinality estimate
      pg_class = instance_double(Gitlab::Database::PgClass, cardinality_estimate: 12345)
      allow(Gitlab::Database::PgClass).to receive(:for_table)
                                            .with(:merge_request_diff_files)
                                            .and_return(pg_class)

      expect { migrate! }.to change { migration.reload.total_tuple_count }.from(nil).to(12345)
    end

    context 'when cardinality_estimate returns nil' do
      it 'does not update total_tuple_count' do
        pg_class = instance_double(Gitlab::Database::PgClass, cardinality_estimate: nil)
        allow(Gitlab::Database::PgClass).to receive(:for_table)
                                              .with(:merge_request_diff_files)
                                              .and_return(pg_class)

        expect { migrate! }.not_to change { migration.reload.total_tuple_count }
      end
    end

    context 'when PgClass.for_table returns nil' do
      it 'does not update total_tuple_count' do
        allow(Gitlab::Database::PgClass).to receive(:for_table)
                                              .with(:merge_request_diff_files)
                                              .and_return(nil)

        expect { migrate! }.not_to change { migration.reload.total_tuple_count }
      end
    end

    context 'when migration already has total_tuple_count' do
      before do
        migration.update!(total_tuple_count: 5000)
      end

      it 'updates the total_tuple_count with new value' do
        pg_class = instance_double(Gitlab::Database::PgClass, cardinality_estimate: 10000)
        allow(Gitlab::Database::PgClass).to receive(:for_table)
                                              .with(:merge_request_diff_files)
                                              .and_return(pg_class)

        expect { migrate! }.to change { migration.reload.total_tuple_count }.from(5000).to(10000)
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      migration.update!(total_tuple_count: 12345)

      expect { schema_migrate_down! }.not_to change { migration.reload.total_tuple_count }
    end
  end
end
