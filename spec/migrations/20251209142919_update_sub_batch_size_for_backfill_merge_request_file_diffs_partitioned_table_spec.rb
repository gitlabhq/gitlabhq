# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateSubBatchSizeForBackfillMergeRequestFileDiffsPartitionedTable, migration: :gitlab_main_org,
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
      total_tuple_count: 12345
    )
  end

  describe '#up' do
    it 'updates the sub_batch_size to 2500 and batch_size to 50000' do
      expect { migrate! }.to change { migration.reload.sub_batch_size }.from(200).to(2500)
        .and change { migration.reload.batch_size }.from(1000).to(50000)
    end

    context 'when batch_size is already larger than 50000' do
      before do
        migration.update!(batch_size: 60000)
      end

      it 'updates sub_batch_size but does not change batch_size' do
        expect { migrate! }.to change { migration.reload.sub_batch_size }.from(200).to(2500)
          .and not_change { migration.reload.batch_size }
      end
    end

    context 'when migration does not exist' do
      before do
        migration.delete
      end

      it 'does not raise an error' do
        expect { migrate! }.not_to raise_error
      end
    end
  end

  describe '#down' do
    it 'reverts the sub_batch_size to 200 and leaves batch_size where it is' do
      migrate!
      expect { schema_migrate_down! }.to change { migration.reload.sub_batch_size }.from(2500).to(200)
        .and not_change { migration.reload.batch_size }
    end

    context 'when migration does not exist' do
      before do
        migration.delete
      end

      it 'does not raise an error' do
        expect { schema_migrate_down! }.not_to raise_error
      end
    end
  end
end
