# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillMergeRequestFileDiffsPartitionedTable, migration: :gitlab_main_org, feature_category: :source_code_management do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'BackfillMergeRequestFileDiffsPartitionedTable',
      table_name: :merge_request_diff_files,
      column_name: :merge_request_diff_id,
      job_arguments: [:merge_request_diff_files_99208b8fac, :merge_request_diff_id, :relative_order],
      finalize: true
    )

    migrate!
  end
end
