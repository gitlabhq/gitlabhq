# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateMrDiffCommitsBackfill,
  migration: :gitlab_main_org,
  feature_category: :code_review_workflow do
  let(:migration_name) { described_class::MIGRATION }
  let(:view_prefix) { described_class::VIEW_PREFIX }
  let(:mr_diff_commits) { table(:merge_request_diff_commits) }

  def create_bbm(table_name:, min_cursor:, max_cursor:, batch_size: 500_000, sub_batch_size: 10_000)
    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      job_class_name: migration_name,
      table_name: table_name,
      column_name: 'merge_request_diff_id',
      job_arguments: %w[merge_request_diff_commits_b5377a7a34],
      interval: 120,
      min_cursor: min_cursor,
      max_cursor: max_cursor,
      batch_size: batch_size,
      sub_batch_size: sub_batch_size,
      pause_ms: 100,
      gitlab_schema: :gitlab_main_org,
      status: 1
    )
  end

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'does not create any BBM records' do
      expect { migrate! }
        .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
    end
  end

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    context 'when view 4 BBM exists' do
      # Use a large value so it is the clear max in the commits table.
      let(:max_diff_id) { 1_999_999_999 }

      let!(:latest_commit) do
        mr_diff_commits.create!(merge_request_diff_id: max_diff_id, relative_order: 3)
      end

      let!(:view4) do
        create_bbm(
          table_name: "#{view_prefix}_4",
          min_cursor: [1_224_788_900, 0],
          max_cursor: [1_766_967_341, 5]
        )
      end

      it 'extends view 4 max_cursor and does not create new BBM records', :aggregate_failures do
        expect { migrate! }
          .to change { view4.reload.max_cursor }.to([max_diff_id, 3])
          .and not_change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end

    context 'when view 4 BBM exists but merge_request_diff_commits is empty' do
      let!(:view4) do
        create_bbm(
          table_name: "#{view_prefix}_4",
          min_cursor: [1_224_788_900, 0],
          max_cursor: [1_766_967_341, 5]
        )
      end

      it 'does not update max_cursor' do
        expect { migrate! }.not_to change { view4.reload.max_cursor }
      end

      it 'does not raise' do
        expect { migrate! }.not_to raise_error
      end
    end

    context 'when view 4 BBM does not exist' do
      it 'does not raise' do
        expect { migrate! }.not_to raise_error
      end
    end

    describe '#down' do
      it 'is a no-op' do
        migrate!

        expect { schema_migrate_down! }
          .not_to raise_error
      end
    end
  end
end
