# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::BackfillMergeRequestDiffCommitsToPartitionedBatchingStrategy, feature_category: :code_review_workflow do
  let(:strategy) { described_class.new(connection: ApplicationRecord.connection) }
  let(:diff_commits) { table(:merge_request_diff_commits) }

  let!(:row4) { diff_commits.create!(merge_request_diff_id: 3, relative_order: 0) }
  let!(:row3) { diff_commits.create!(merge_request_diff_id: 2, relative_order: 0) }
  let!(:row2) { diff_commits.create!(merge_request_diff_id: 1, relative_order: 1) }
  let!(:row1) { diff_commits.create!(merge_request_diff_id: 1, relative_order: 0) }

  let(:job_class) do
    Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
      cursor :merge_request_diff_id, :relative_order
    end
  end

  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }

  context 'when any table_name is passed' do
    it 'always queries merge_request_diff_commits regardless of the passed table_name' do
      bounds_with_real_table = strategy.next_batch(
        :merge_request_diff_commits, :merge_request_diff_id,
        batch_min_value: [0, 0], batch_size: 10, job_arguments: [], job_class: job_class
      )

      bounds_with_view = strategy.next_batch(
        'merge_request_diff_commits_views_1', :merge_request_diff_id,
        batch_min_value: [0, 0], batch_size: 10, job_arguments: [], job_class: job_class
      )

      expect(bounds_with_real_table).to eq([[1, 0], [3, 0]])
      expect(bounds_with_view).to eq(bounds_with_real_table)
    end

    it 'returns nil when the cursor is past all rows in merge_request_diff_commits' do
      bounds = strategy.next_batch(
        'merge_request_diff_commits_views_1', :merge_request_diff_id,
        batch_min_value: [999, 0], batch_size: 2, job_arguments: [], job_class: job_class
      )

      expect(bounds).to be_nil
    end
  end

  context 'when job class does not use a cursor' do
    let(:non_cursor_job_class) { Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) }

    it 'delegates to the parent PrimaryKeyBatchingStrategy' do
      expect(Gitlab::Pagination::Keyset::Iterator).not_to receive(:new)

      bounds = strategy.next_batch(
        :merge_request_diff_commits, :merge_request_diff_id,
        batch_min_value: 1, batch_size: 2, job_arguments: [], job_class: non_cursor_job_class
      )

      expect(bounds).to eq([1, 1])
    end
  end
end
