# frozen_string_literal: true

RSpec.shared_examples 'backfill migration for project repositories' do |storage|
  describe '#perform' do
    let(:storage_versions) { storage == :legacy ? [nil, 0] : [1, 2] }
    let(:storage_version) { storage_versions.first }
    let(:namespaces) { table(:namespaces) }
    let(:project_repositories) { table(:project_repositories) }
    let(:projects) { table(:projects) }
    let(:shards) { table(:shards) }
    let(:group) { namespaces.create!(name: 'foo', path: 'foo') }
    let(:shard) { shards.create!(name: 'default') }

    it "creates a project_repository row for projects on #{storage} storage that needs one" do
      storage_versions.each_with_index do |storage_version, index|
        projects.create!(name: "foo-#{index}", path: "foo-#{index}", namespace_id: group.id, storage_version: storage_version)
      end

      expect { described_class.new.perform(1, projects.last.id) }.to change { project_repositories.count }.by(2)
    end

    it "does nothing for projects on #{storage} storage that have already a project_repository row" do
      projects.create!(id: 1, name: 'foo', path: 'foo', namespace_id: group.id, storage_version: storage_version)
      project_repositories.create!(project_id: 1, disk_path: 'phony/foo/bar', shard_id: shard.id)

      expect { described_class.new.perform(1, projects.last.id) }.not_to change { project_repositories.count }
    end

    it "does nothing for projects on #{storage == :legacy ? 'hashed' : 'legacy'} storage" do
      projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: storage == :legacy ? 1 : nil)

      expect { described_class.new.perform(1, projects.last.id) }.not_to change { project_repositories.count }
    end

    it 'inserts rows in a single query' do
      projects.create!(name: 'foo', path: 'foo', namespace_id: group.id, storage_version: storage_version, repository_storage: shard.name)
      group2 = namespaces.create!(name: 'gro', path: 'gro')

      control_count = ActiveRecord::QueryRecorder.new { described_class.new.perform(1, projects.last.id) }

      projects.create!(name: 'bar', path: 'bar', namespace_id: group.id, storage_version: storage_version, repository_storage: shard.name)
      projects.create!(name: 'top', path: 'top', namespace_id: group.id, storage_version: storage_version, repository_storage: shard.name)
      projects.create!(name: 'zoo', path: 'zoo', namespace_id: group2.id, storage_version: storage_version, repository_storage: shard.name)

      expect { described_class.new.perform(1, projects.last.id) }.not_to exceed_query_limit(control_count)
    end
  end
end
