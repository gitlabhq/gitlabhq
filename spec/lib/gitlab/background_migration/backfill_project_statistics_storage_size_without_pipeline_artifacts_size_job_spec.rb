# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob,
  schema: 20230719083202,
  feature_category: :consumables_cost_management do
  include MigrationHelpers::ProjectStatisticsHelper

  include_context 'when backfilling project statistics'

  let(:default_pipeline_artifacts_size) { 5 }
  let(:default_stats) do
    {
      repository_size: 1,
      wiki_size: 1,
      lfs_objects_size: 1,
      build_artifacts_size: 1,
      packages_size: 1,
      snippets_size: 1,
      uploads_size: 1,
      pipeline_artifacts_size: default_pipeline_artifacts_size,
      storage_size: default_storage_size
    }
  end

  describe '#filter_batch' do
    it 'filters out project_statistics with no artifacts size' do
      project_statistics = generate_records(default_projects, project_statistics_table, default_stats)
      project_statistics_table.create!(
        project_id: proj5.id,
        namespace_id: proj5.namespace_id,
        repository_size: 1,
        wiki_size: 1,
        lfs_objects_size: 1,
        build_artifacts_size: 1,
        packages_size: 1,
        snippets_size: 1,
        pipeline_artifacts_size: 0,
        uploads_size: 1,
        storage_size: 7
      )

      expected = project_statistics.map(&:id)
      actual = migration.filter_batch(project_statistics_table).pluck(:id)

      expect(actual).to match_array(expected)
    end
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    context 'when project_statistics backfill runs' do
      before do
        generate_records(default_projects, project_statistics_table, default_stats)
      end

      context 'when storage_size includes pipeline_artifacts_size' do
        it 'removes pipeline_artifacts_size from storage_size' do
          allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
          expect(project_statistics_table.pluck(:storage_size).uniq).to match_array([default_storage_size])

          perform_migration

          expect(project_statistics_table.pluck(:storage_size).uniq).to match_array(
            [default_storage_size - default_pipeline_artifacts_size]
          )
          expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(4).times
        end
      end

      context 'when storage_size does not include default_pipeline_artifacts_size' do
        it 'does not update the record' do
          allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
          proj_stat = project_statistics_table.last
          expect(proj_stat.storage_size).to eq(default_storage_size)
          proj_stat.storage_size = default_storage_size - default_pipeline_artifacts_size
          proj_stat.save!

          perform_migration

          expect(project_statistics_table.pluck(:storage_size).uniq).to match_array(
            [default_storage_size - default_pipeline_artifacts_size]
          )
          expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(3).times
        end
      end
    end

    it 'coerces a null wiki_size to 0' do
      project_statistics = create_project_stats(projects, namespaces, default_stats, { wiki_size: nil })
      allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      migration = create_migration(end_id: project_statistics.project_id)

      migration.perform

      project_statistics.reload
      expect(project_statistics.storage_size).to eq(6)
    end

    it 'coerces a null snippets_size to 0' do
      project_statistics = create_project_stats(projects, namespaces, default_stats, { snippets_size: nil })
      allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      migration = create_migration(end_id: project_statistics.project_id)

      migration.perform

      project_statistics.reload
      expect(project_statistics.storage_size).to eq(6)
    end
  end
end
