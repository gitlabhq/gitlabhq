# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::BackfillProjectRepositories, feature_category: :groups_and_projects do
  let(:group) { create(:group, name: 'foo', path: 'foo') }

  describe described_class::ShardFinder do
    let(:shard) { create(:shard, name: 'default') }

    describe '#find_shard_id' do
      it 'creates a new shard when it does not exist yet' do
        expect { subject.find_shard_id('other') }.to change(Shard, :count).by(1)
      end

      it 'returns the shard when it exists' do
        other_shard = create(:shard, name: 'other')

        shard_id = subject.find_shard_id('other')

        expect(shard_id).to eq(other_shard.id)
      end

      it 'only queries the database once to retrieve shards' do
        subject.find_shard_id('default')

        expect { subject.find_shard_id('default') }.not_to exceed_query_limit(0)
      end
    end
  end

  describe described_class::Project do
    let!(:project_hashed_storage_1) { create(:project, name: 'foo', path: 'foo', namespace: group, storage_version: 1) }
    let!(:project_hashed_storage_2) { create(:project, name: 'bar', path: 'bar', namespace: group, storage_version: 2) }
    let!(:project_legacy_storage_3) { create(:project, name: 'baz', path: 'baz', namespace: group, storage_version: 0) }
    let!(:project_legacy_storage_4) { create(:project, name: 'zoo', path: 'zoo', namespace: group, storage_version: nil) }
    let!(:project_legacy_storage_5) { create(:project, name: 'test', path: 'test', namespace: group, storage_version: nil) }

    describe '.on_hashed_storage' do
      it 'finds projects with repository on hashed storage' do
        projects = described_class.on_hashed_storage.pluck(:id)

        expect(projects).to match_array([project_hashed_storage_1.id, project_hashed_storage_2.id])
      end
    end

    describe '.on_legacy_storage' do
      it 'finds projects with repository on legacy storage' do
        projects = described_class.on_legacy_storage.pluck(:id)

        expect(projects).to match_array([project_legacy_storage_3.id, project_legacy_storage_4.id, project_legacy_storage_5.id])
      end
    end

    describe '.without_project_repository' do
      it 'finds projects which do not have a projects_repositories entry' do
        create(:project_repository, project: project_hashed_storage_1)
        create(:project_repository, project: project_legacy_storage_3)

        projects = described_class.without_project_repository.pluck(:id)

        expect(projects).to contain_exactly(project_hashed_storage_2.id, project_legacy_storage_4.id, project_legacy_storage_5.id)
      end
    end

    describe '#disk_path' do
      context 'for projects on hashed storage' do
        it 'returns the correct disk_path' do
          project = described_class.find(project_hashed_storage_1.id)

          expect(project.disk_path).to eq(project_hashed_storage_1.disk_path)
        end
      end

      context 'for projects on legacy storage' do
        it 'returns the correct disk_path' do
          project = described_class.find(project_legacy_storage_3.id)

          expect(project.disk_path).to eq(project_legacy_storage_3.disk_path)
        end

        it 'returns the correct disk_path using the route entry' do
          project_legacy_storage_5.route.update!(path: 'zoo/new-test')
          project = described_class.find(project_legacy_storage_5.id)

          expect(project.disk_path).to eq('zoo/new-test')
        end
      end
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
