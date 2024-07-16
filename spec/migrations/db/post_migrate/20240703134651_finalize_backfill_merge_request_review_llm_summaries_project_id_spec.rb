# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillMergeRequestReviewLlmSummariesProjectId, feature_category: :database do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      # enqueue the migration
      QueueBackfillMergeRequestReviewLlmSummariesProjectId.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'BackfillMergeRequestReviewLlmSummariesProjectId',
        table_name: 'merge_request_review_llm_summaries'
      ).first

      expect(migration.status).not_to eq(6) # finalized

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueBackfillMergeRequestReviewLlmSummariesProjectId.new.down
    end
  end
end
