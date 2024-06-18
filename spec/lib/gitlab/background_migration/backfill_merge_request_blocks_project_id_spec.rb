# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestBlocksProjectId,
  feature_category: :source_code_management,
  schema: 20240612072327 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :merge_request_blocks }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :merge_requests }
    let(:backfill_via_column) { :target_project_id }
    let(:backfill_via_foreign_key) { :blocking_merge_request_id }
  end
end
