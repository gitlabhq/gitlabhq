# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedProjectRepositories, feature_category: :geo_replication do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:shards) { table(:shards) }
  let(:project_repositories) { table(:project_repositories) }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }
  let!(:namespace) do
    namespaces.create!(name: 'ns', path: 'ns', type: 'Group', organization_id: organization.id)
  end

  let!(:shard) { shards.find_or_create_by!(name: 'default') }

  let!(:project) { create_project('project-1') }
  let!(:valid_repository) { create_project_repository(project.id) }

  let!(:orphaned_repository) do
    without_foreign_key { create_project_repository(projects.maximum(:id).to_i + 1) }
  end

  let(:migration) do
    described_class.new(
      start_id: project_repositories.minimum(:id),
      end_id: project_repositories.maximum(:id),
      batch_table: :project_repositories,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: connection
    )
  end

  describe '#perform' do
    it 'deletes orphaned project_repositories but keeps valid ones', :aggregate_failures do
      expect { migration.perform }.to change { project_repositories.count }.by(-1)

      expect(project_repositories.exists?(valid_repository.id)).to be(true)
      expect(project_repositories.exists?(orphaned_repository.id)).to be(false)
    end

    context 'when there are no orphaned project_repositories' do
      before do
        project_repositories.where(id: orphaned_repository.id).delete_all
      end

      it 'does not delete anything' do
        expect { migration.perform }.not_to change { project_repositories.count }
      end
    end
  end

  private

  def create_project(name)
    project_namespace = namespaces.create!(
      name: "ns-#{name}", path: "ns-#{name}", type: 'Project', organization_id: organization.id
    )

    projects.create!(
      name: name,
      path: name,
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  def create_project_repository(project_id)
    project_repositories.create!(shard_id: shard.id, disk_path: "disk-path-#{project_id}", project_id: project_id)
  end

  # fk_7a810d4121 (project_id -> projects.id) is enforced even as NOT VALID, so drop it to
  # insert an orphan, then restore it NOT VALID without validating the orphan.
  def without_foreign_key
    connection.execute('ALTER TABLE project_repositories DROP CONSTRAINT IF EXISTS fk_7a810d4121')
    yield
  ensure
    connection.execute(<<~SQL)
      ALTER TABLE project_repositories
        ADD CONSTRAINT fk_7a810d4121 FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE NOT VALID
    SQL
  end
end
