# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithRecentSize,
  schema: 20230823090001,
  quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/477992',
  feature_category: :consumables_cost_management do
  include MigrationHelpers::ProjectStatisticsHelper

  include_context 'when backfilling project statistics'

  let(:recent_size_enabled_at) { described_class::RECENT_OBJECTS_SIZE_ENABLED_AT }
  let(:default_stats) do
    {
      repository_size: 1,
      wiki_size: 1,
      lfs_objects_size: 1,
      build_artifacts_size: 1,
      packages_size: 1,
      snippets_size: 1,
      uploads_size: 1,
      storage_size: default_storage_size,
      updated_at: recent_size_enabled_at - 1.month
    }
  end

  describe '#filter_batch' do
    let!(:project_statistics) { generate_records(default_projects, project_statistics_table, default_stats) }
    let!(:expected) { project_statistics.map(&:id) }

    it 'filters out project_statistics with no repository_size' do
      project_statistics_table.create!(
        project_id: proj5.id,
        namespace_id: proj5.namespace_id,
        repository_size: 0,
        wiki_size: 1,
        lfs_objects_size: 1,
        build_artifacts_size: 1,
        packages_size: 1,
        snippets_size: 1,
        uploads_size: 1,
        storage_size: 6,
        updated_at: recent_size_enabled_at - 1.month
      )

      actual = migration.filter_batch(project_statistics_table).pluck(:id)

      expect(actual).to match_array(expected)
    end

    shared_examples 'filters out project_statistics updated since recent objects went live' do
      it 'filters out project_statistics updated since recent objects went live' do
        project_statistics_table.create!(
          project_id: proj5.id,
          namespace_id: proj5.namespace_id,
          repository_size: 10,
          wiki_size: 1,
          lfs_objects_size: 1,
          build_artifacts_size: 1,
          packages_size: 1,
          snippets_size: 1,
          uploads_size: 1,
          storage_size: 6,
          updated_at: recent_size_enabled_at + 1.month
        )

        actual = migration.filter_batch(project_statistics_table).pluck(:id)

        expect(actual).to match_array(expected)
      end
    end

    context 'when on GitLab.com' do
      before do
        allow(Gitlab).to receive(:org_or_com?).and_return(true)
      end

      it_behaves_like 'filters out project_statistics updated since recent objects went live'
    end

    context 'when Gitlab.dev_or_test_env? is true ' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
      end

      it_behaves_like 'filters out project_statistics updated since recent objects went live'
    end

    context 'when on self-managed' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        allow(Gitlab).to receive(:org_or_com?).and_return(false)
      end

      it 'does not filter out project_statistics updated since recent objects went live' do
        latest = project_statistics_table.create!(
          project_id: proj5.id,
          namespace_id: proj5.namespace_id,
          repository_size: 10,
          wiki_size: 1,
          lfs_objects_size: 1,
          build_artifacts_size: 1,
          packages_size: 1,
          snippets_size: 1,
          uploads_size: 1,
          storage_size: 6,
          updated_at: recent_size_enabled_at + 1.month
        )

        actual = migration.filter_batch(project_statistics_table).pluck(:id)

        expect(actual).to match_array(expected.push(latest.id))
      end
    end
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    before do
      allow_next_instance_of(Repository) do |repo|
        allow(repo).to receive(:recent_objects_size).and_return(10)
      end
    end

    context 'when project_statistics backfill runs' do
      before do
        generate_records(default_projects, project_statistics_table, default_stats)
        allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      end

      it 'uses repository#recent_objects_size for repository_size' do
        project_statistics = create_project_stats(projects, namespaces, default_stats)
        migration = create_migration(end_id: project_statistics.project_id)

        migration.perform

        project_statistics.reload
        expect(project_statistics.storage_size).to eq(6 + 10.megabytes)
      end
    end

    it 'coerces a null wiki_size to 0' do
      project_statistics = create_project_stats(projects, namespaces, default_stats, { wiki_size: nil })
      allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      migration = create_migration(end_id: project_statistics.project_id)

      migration.perform

      project_statistics.reload
      expect(project_statistics.storage_size).to eq(5 + 10.megabytes)
    end

    it 'coerces a null snippets_size to 0' do
      project_statistics = create_project_stats(projects, namespaces, default_stats, { snippets_size: nil })
      allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      migration = create_migration(end_id: project_statistics.project_id)

      migration.perform

      project_statistics.reload
      expect(project_statistics.storage_size).to eq(5 + 10.megabytes)
    end
  end
end
