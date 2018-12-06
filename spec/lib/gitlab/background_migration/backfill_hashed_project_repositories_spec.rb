# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillHashedProjectRepositories, :migration, schema: 20181130102132 do
  let(:namespaces) { table(:namespaces) }
  let(:project_repositories) { table(:project_repositories) }
  let(:projects) { table(:projects) }
  let(:shards) { table(:shards) }
  let(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:shard) { shards.create!(name: 'default') }

  describe described_class::ShardFinder do
    describe '#find_shard_id' do
      it 'creates a new shard when it does not exist yet' do
        expect { subject.find_shard_id('other') }.to change(shards, :count).by(1)
      end

      it 'returns the shard when it exists' do
        shards.create(id: 5, name: 'other')

        shard_id = subject.find_shard_id('other')

        expect(shard_id).to eq(5)
      end

      it 'only queries the database once to retrieve shards' do
        subject.find_shard_id('default')

        expect { subject.find_shard_id('default') }.not_to exceed_query_limit(0)
      end
    end
  end

  describe described_class::Project do
    describe '.on_hashed_storage' do
      it 'finds projects with repository on hashed storage' do
        projects.create!(id: 1, name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1)
        projects.create!(id: 2, name: 'bar', path: 'bar', namespace_id: group.id, storage_version: 2)
        projects.create!(id: 3, name: 'baz', path: 'baz', namespace_id: group.id, storage_version: 0)
        projects.create!(id: 4, name: 'zoo', path: 'zoo', namespace_id: group.id, storage_version: nil)

        expect(described_class.on_hashed_storage.pluck(:id)).to match_array([1, 2])
      end
    end

    describe '.without_project_repository' do
      it 'finds projects which do not have a projects_repositories entry' do
        projects.create!(id: 1, name: 'foo', path: 'foo', namespace_id: group.id)
        projects.create!(id: 2, name: 'bar', path: 'bar', namespace_id: group.id)
        project_repositories.create!(project_id: 2, disk_path: '@phony/foo/bar', shard_id: shard.id)

        expect(described_class.without_project_repository.pluck(:id)).to contain_exactly(1)
      end
    end
  end

  describe '#perform' do
    it 'creates a project_repository row for projects on hashed storage that need one' do
      projects.create!(id: 1, name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1)
      projects.create!(id: 2, name: 'bar', path: 'bar', namespace_id: group.id, storage_version: 2)

      expect { described_class.new.perform(1, projects.last.id) }.to change(project_repositories, :count).by(2)
    end

    it 'does nothing for projects on hashed storage that have already a project_repository row' do
      projects.create!(id: 1, name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1)
      project_repositories.create!(project_id: 1, disk_path: '@phony/foo/bar', shard_id: shard.id)

      expect { described_class.new.perform(1, projects.last.id) }.not_to change(project_repositories, :count)
    end

    it 'does nothing for projects on legacy storage' do
      projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 0)

      expect { described_class.new.perform(1, projects.last.id) }.not_to change(project_repositories, :count)
    end

    it 'inserts rows in a single query' do
      projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1, repository_storage: shard.name)

      control_count = ActiveRecord::QueryRecorder.new { described_class.new.perform(1, projects.last.id) }

      projects.create!(name: 'bar', path: 'bar', namespace_id: group.id, storage_version: 1, repository_storage: shard.name)
      projects.create!(name: 'zoo', path: 'zoo', namespace_id: group.id, storage_version: 1, repository_storage: shard.name)

      expect { described_class.new.perform(1, projects.last.id) }.not_to exceed_query_limit(control_count)
    end
  end
end
