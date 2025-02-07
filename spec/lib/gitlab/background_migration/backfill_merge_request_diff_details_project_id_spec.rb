# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestDiffDetailsProjectId,
  feature_category: :geo_replication,
  schema: 20250205193727 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :merge_request_diff_details }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :merge_request_diff_id }
    let(:backfill_via_table) { :merge_request_diffs }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :merge_request_diff_id }
  end
end
