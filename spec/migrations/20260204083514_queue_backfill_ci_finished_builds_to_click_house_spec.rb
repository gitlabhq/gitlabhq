# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillCiFinishedBuildsToClickHouse, migration: :gitlab_ci, feature_category: :fleet_visibility do
  let(:batched_migration) { described_class::MIGRATION }
  let(:builds) { table(:p_ci_builds, database: :ci, primary_key: :id) }
  let(:pipelines) { table(:p_ci_pipelines, database: :ci, primary_key: :id) }

  let(:default_attributes) { { project_id: 500, partition_id: 100 } }
  let!(:pipeline) { pipelines.create!(default_attributes) }

  describe '#up' do
    context 'when there are builds within the backfill period' do
      let!(:old_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'success',
            created_at: 200.days.ago
          )
        )
      end

      let!(:recent_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'success',
            created_at: 170.days.ago
          )
        )
      end

      let!(:newer_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'success',
            created_at: 10.days.ago
          )
        )
      end

      it 'schedules a batched migration starting from the earliest build in backfill period' do
        migrate!

        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: :p_ci_builds,
          column_name: :id,
          batch_min_value: recent_build.id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      end
    end

    context 'when there are no builds within the backfill period' do
      let!(:old_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'success',
            created_at: 200.days.ago
          )
        )
      end

      it 'does not schedule a batched migration' do
        migrate!

        expect(batched_migration).not_to have_scheduled_batched_migration
      end
    end

    context 'when builds with different finished statuses exist within the backfill period' do
      let!(:old_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'success',
            created_at: 200.days.ago
          )
        )
      end

      let!(:failed_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'failed',
            created_at: 170.days.ago
          )
        )
      end

      let!(:canceled_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'canceled',
            created_at: 160.days.ago
          )
        )
      end

      let!(:success_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'success',
            created_at: 150.days.ago
          )
        )
      end

      it 'schedules a batched migration starting from the earliest finished build' do
        migrate!

        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: :p_ci_builds,
          column_name: :id,
          batch_min_value: failed_build.id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      end
    end

    context 'when only non-finished builds exist within the backfill period' do
      let!(:running_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'running',
            created_at: 170.days.ago
          )
        )
      end

      let!(:pending_build) do
        builds.create!(
          default_attributes.merge(
            commit_id: pipeline.id,
            type: 'Ci::Build',
            status: 'pending',
            created_at: 170.days.ago
          )
        )
      end

      it 'does not schedule a batched migration' do
        migrate!

        expect(batched_migration).not_to have_scheduled_batched_migration
      end
    end
  end
end
