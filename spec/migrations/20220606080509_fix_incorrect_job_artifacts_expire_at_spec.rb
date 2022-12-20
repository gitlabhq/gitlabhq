# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixIncorrectJobArtifactsExpireAt, migration: :gitlab_ci, feature_category: :build_artifacts do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'does not schedule background jobs when Gitlab.com is true' do
    allow(Gitlab).to receive(:com?).and_return(true)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end

  it 'schedules background job on non Gitlab.com' do
    allow(Gitlab).to receive(:com?).and_return(false)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: :ci_job_artifacts,
          column_name: :id,
          interval: described_class::INTERVAL,
          batch_size: described_class::BATCH_SIZE
        )
      }
    end
  end
end
