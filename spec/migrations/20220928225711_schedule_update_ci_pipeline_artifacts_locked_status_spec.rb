# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleUpdateCiPipelineArtifactsLockedStatus,
  migration: :gitlab_ci, feature_category: :build_artifacts do
  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of ci_pipeline_artifacts' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        gitlab_schema: :gitlab_ci,
        table_name: :ci_pipeline_artifacts,
        column_name: :id,
        batch_size: described_class::BATCH_SIZE,
        sub_batch_size: described_class::SUB_BATCH_SIZE
      )
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
