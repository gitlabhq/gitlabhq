# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillHashedProjectRepositories, :migration, schema: 20181130102132 do
  let(:shards) { table(:shards) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_repositories) { table(:project_repositories) }
  let(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:default_shard) { shards.create!(name: 'default') }

  describe described_class::ShardFinder do
    describe '#find' do
      subject(:finder) { described_class.new }

      it 'creates the shard by name' do
        expect(finder).to receive(:create!).and_call_original

        expect(finder.find('default')).to be_present
      end

      it 'does not try to create existing shards' do
        shards.create(name: 'default')

        expect(finder).not_to receive(:create!)

        finder.find('default')
      end

      it 'only queries the database once for shards' do
        finder.find('default')

        expect do
          finder.find('default')
        end.not_to exceed_query_limit(0)
      end

      it 'creates a new shard when it does not exist yet' do
        expect do
          finder.find('other')
        end.to change(shards, :count).by(1)
      end

      it 'only creates a new shard once' do
        finder.find('other')

        expect do
          finder.find('other')
        end.not_to change(shards, :count)
      end

      it 'is not vulnerable to race conditions' do
        finder.find('default')

        other_shard = shards.create(name: 'other')

        expect(finder.find('other').id).to eq(other_shard.id)
      end
    end
  end

  describe described_class::Project do
    describe '.on_hashed_storage' do
      it 'finds projects with repository on hashed storage' do
        hashed_projects = [
          projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1),
          projects.create!(name: 'bar', path: 'bar', namespace_id: group.id, storage_version: 2)
        ]

        projects.create!(name: 'baz', path: 'baz', namespace_id: group.id, storage_version: 0)
        projects.create!(name: 'quz', path: 'quz', namespace_id: group.id, storage_version: nil)

        expect(described_class.on_hashed_storage.pluck(:id)).to match_array(hashed_projects.map(&:id))
      end
    end

    describe '.without_project_repository' do
      it 'finds projects which do not have a projects_repositories row' do
        without_project = projects.create!(name: 'foo', path: 'foo', namespace_id: group.id)
        with_project = projects.create!(name: 'bar', path: 'bar', namespace_id: group.id)
        project_repositories.create!(project_id: with_project.id, disk_path: '@phony/foo/bar', shard_id: default_shard.id)

        expect(described_class.without_project_repository.pluck(:id)).to contain_exactly(without_project.id)
      end
    end

    describe '#project_repository_attributes' do
      let(:shard_finder) { Gitlab::BackgroundMigration::BackfillHashedProjectRepositories::ShardFinder.new }

      it 'composes the correct attributes for project_repository' do
        shiny_shard = shards.create!(name: 'shiny')
        project = projects.create!(id: 5, name: 'foo', path: 'foo', namespace_id: group.id, repository_storage: shiny_shard.name, storage_version: 1)

        expected_attributes = {
          project_id: project.id,
          shard_id: shiny_shard.id,
          disk_path: '@hashed/ef/2d/ef2d127de37b942baad06145e54b0c619a1f22327b2ebbcfbec78f5564afe39d'
        }

        expect(described_class.find(project.id).project_repository_attributes(shard_finder)).to eq(expected_attributes)
      end

      it 'returns nil for a project not on hashed storage' do
        project = projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 0)

        expect(described_class.find(project.id).project_repository_attributes(shard_finder)).to be_nil
      end
    end
  end

  describe '#perform' do
    def perform!
      described_class.new.perform(1, projects.last.id)
    end

    it 'create project_repository row for hashed storage project' do
      projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1)

      expect do
        perform!
      end.to change(project_repositories, :count).by(1)
    end

    it 'does nothing for projects that have already a project_repository' do
      project = projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1)
      project_repositories.create!(project_id: project.id, disk_path: '@phony/foo/bar', shard_id: default_shard.id)

      expect do
        perform!
      end.not_to change(project_repositories, :count)
    end

    it 'does nothing for projects on legacy storage' do
      projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 0)

      expect do
        perform!
      end.not_to change(project_repositories, :count)
    end

    it 'inserts rows in a single query' do
      projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: 1, repository_storage: default_shard.name)

      control_count = ActiveRecord::QueryRecorder.new do
        perform!
      end

      projects.create!(name: 'bar', path: 'bar', namespace_id: group.id, storage_version: 1, repository_storage: default_shard.name)
      projects.create!(name: 'quz', path: 'quz', namespace_id: group.id, storage_version: 1, repository_storage: default_shard.name)

      expect { perform! }.not_to exceed_query_limit(control_count)
    end
  end
end
