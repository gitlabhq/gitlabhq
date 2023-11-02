# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::BackgroundMigration::FixIncoherentPackagesSizeOnProjectStatistics,
  feature_category: :package_registry do
  let(:project_statistics_table) { table(:project_statistics) }
  let(:packages_table) { table(:packages_packages) }
  let(:package_files_table) { table(:packages_package_files) }
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }

  let!(:group) { namespaces_table.create!(name: 'group', path: 'group', type: 'Group') }

  let!(:project_1_namespace) do
    namespaces_table.create!(name: 'project1', path: 'project1', type: 'Project', parent_id: group.id)
  end

  let!(:project_2_namespace) do
    namespaces_table.create!(name: 'project2', path: 'project2', type: 'Project', parent_id: group.id)
  end

  let!(:project_3_namespace) do
    namespaces_table.create!(name: 'project3', path: 'project3', type: 'Project', parent_id: group.id)
  end

  let!(:project_4_namespace) do
    namespaces_table.create!(name: 'project4', path: 'project4', type: 'Project', parent_id: group.id)
  end

  let!(:project_1) do
    projects_table.create!(
      namespace_id: group.id,
      name: 'project1',
      path: 'project1',
      project_namespace_id: project_1_namespace.id
    )
  end

  let!(:project_2) do
    projects_table.create!(
      namespace_id: group.id,
      name: 'project2',
      path: 'project2',
      project_namespace_id: project_2_namespace.id
    )
  end

  let!(:project_3) do
    projects_table.create!(
      namespace_id: group.id,
      name: 'project3',
      path: 'project3',
      project_namespace_id: project_3_namespace.id
    )
  end

  let!(:project_4) do
    projects_table.create!(
      namespace_id: group.id,
      name: 'project4',
      path: 'project4',
      project_namespace_id: project_4_namespace.id
    )
  end

  let!(:coherent_non_zero_statistics) do
    project_statistics_table.create!(namespace_id: group.id, project_id: project_1.id, packages_size: 200)
  end

  let!(:incoherent_non_zero_statistics) do
    project_statistics_table.create!(namespace_id: group.id, project_id: project_2.id, packages_size: 5)
  end

  let!(:coherent_zero_statistics) do
    project_statistics_table.create!(namespace_id: group.id, project_id: project_4.id, packages_size: 0)
  end

  let!(:incoherent_zero_statistics) do
    project_statistics_table.create!(namespace_id: group.id, project_id: project_3.id, packages_size: 0)
  end

  let!(:package_1) do
    packages_table.create!(project_id: project_1.id, name: 'test1', version: '1.2.3', package_type: 2)
  end

  let!(:package_2) do
    packages_table.create!(project_id: project_2.id, name: 'test2', version: '1.2.3', package_type: 2)
  end

  let!(:package_3) do
    packages_table.create!(project_id: project_2.id, name: 'test3', version: '1.2.3', package_type: 2)
  end

  let!(:package_4) do
    packages_table.create!(project_id: project_3.id, name: 'test4', version: '1.2.3', package_type: 2)
  end

  let!(:package_5) do
    packages_table.create!(project_id: project_3.id, name: 'test5', version: '1.2.3', package_type: 2)
  end

  let!(:package_file_1_1) do
    package_files_table.create!(package_id: package_1.id, file_name: 'test.txt', file: 'test', size: 100)
  end

  let!(:package_file_1_2) do
    package_files_table.create!(package_id: package_1.id, file_name: 'test.txt', file: 'test', size: 100)
  end

  let!(:package_file_2_1) do
    package_files_table.create!(package_id: package_2.id, file_name: 'test.txt', file: 'test', size: 100)
  end

  let!(:package_file_3_1) do
    package_files_table.create!(package_id: package_3.id, file_name: 'test.txt', file: 'test', size: 100)
  end

  let!(:package_file_4_1) do
    package_files_table.create!(package_id: package_4.id, file_name: 'test.txt', file: 'test', size: 100)
  end

  let!(:package_file_5_1) do
    package_files_table.create!(package_id: package_5.id, file_name: 'test.txt', file: 'test', size: 100)
  end

  let(:migration) do
    described_class.new(
      start_id: project_statistics_table.minimum(:id),
      end_id: project_statistics_table.maximum(:id),
      batch_table: :project_statistics,
      batch_column: :id,
      sub_batch_size: 1000,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#filter_batch' do
    it 'selects all package size statistics' do
      expected = project_statistics_table.pluck(:id)
      actual = migration.filter_batch(project_statistics_table).pluck(:id)

      expect(actual).to match_array(expected)
    end
  end

  describe '#perform', :aggregate_failures, :clean_gitlab_redis_cache do
    subject(:perform) { migration.perform }

    shared_examples 'not updating project statistics' do
      it 'does not change them' do
        expect(FlushCounterIncrementsWorker).not_to receive(:perform_in)
        expect { perform }
          .to not_change { incoherent_non_zero_statistics.reload.packages_size }
          .and not_change { coherent_non_zero_statistics.reload.packages_size }
          .and not_change { incoherent_zero_statistics.reload.packages_size }
          .and not_change { coherent_zero_statistics.reload.packages_size }
        expect_buffered_update(incoherent_non_zero_statistics, 0)
        expect_buffered_update(incoherent_zero_statistics, 0)
      end
    end

    shared_examples 'enqueuing a buffered updates' do |updates|
      it 'fixes the packages_size stat' do
        updates_for_stats = updates.deep_transform_keys { |k| public_send(k) }
        updates_for_stats.each do |stat, amount|
          expect(FlushCounterIncrementsWorker)
            .to receive(:perform_in).with(
              ::Gitlab::Counters::BufferedCounter::WORKER_DELAY,
              'ProjectStatistics',
              stat.id,
              :packages_size
            )

          expect(::Gitlab::BackgroundMigration::Logger)
            .to receive(:info).with(
              migrator: described_class::MIGRATOR,
              project_id: stat.project_id,
              old_size: stat.packages_size,
              new_size: stat.packages_size + amount
            )
        end

        expect { perform }
          .to not_change { incoherent_non_zero_statistics.reload.packages_size }
          .and not_change { coherent_non_zero_statistics.reload.packages_size }
          .and not_change { incoherent_zero_statistics.reload.packages_size }
          .and not_change { coherent_zero_statistics.reload.packages_size }

        updates_for_stats.each do |stat, amount|
          expect_buffered_update(stat, amount)
        end
      end
    end

    context 'with incoherent packages_size' do
      it_behaves_like 'enqueuing a buffered updates',
        incoherent_non_zero_statistics: 195,
        incoherent_zero_statistics: 200

      context 'with updates waiting on redis' do
        before do
          insert_packages_size_update(incoherent_non_zero_statistics, -50)
          insert_packages_size_update(incoherent_zero_statistics, -50)
        end

        it_behaves_like 'enqueuing a buffered updates',
          incoherent_non_zero_statistics: 195,
          incoherent_zero_statistics: 200
      end
    end

    context 'with no incoherent packages_size' do
      before do
        incoherent_non_zero_statistics.update!(packages_size: 200)
        incoherent_zero_statistics.update!(packages_size: 200)
      end

      it_behaves_like 'not updating project statistics'
    end

    def insert_packages_size_update(stat, amount)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(redis_key(stat), amount)
      end
    end

    def expect_buffered_update(stat, expected)
      amount = Gitlab::Redis::SharedState.with do |redis|
        redis.get(redis_key(stat)).to_i
      end
      expect(amount).to eq(expected)
    end

    def redis_key(stats)
      "project:{#{stats.project_id}}:counters:ProjectStatistics:#{stats.id}:packages_size"
    end
  end
end
# rubocop: enable RSpec/MultipleMemoizedHelpers
