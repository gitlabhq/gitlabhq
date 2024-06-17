# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestReviewLlmSummariesProjectId,
  feature_category: :code_review_workflow,
  schema: 20240613154055 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :merge_request_review_llm_summaries }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :reviews }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :review_id }
  end
end
