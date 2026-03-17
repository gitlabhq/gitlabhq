# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissingProjectRepositories, feature_category: :geo_replication do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:shards) { table(:shards) }
  let(:project_repositories) { table(:project_repositories) }

  let!(:organization) { organizations.create!(name: 'Org', path: 'org') }
  let!(:shard) { shards.find_by(name: 'default') || shards.create!(name: 'default') }
  let!(:project) { create_project(name: 'missing-repo') }
  let!(:group) do
    namespaces.create!(
      name: 'group',
      path: 'group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let(:migration_attrs) do
    {
      start_cursor: [projects.minimum(:id)],
      end_cursor: [projects.maximum(:id)],
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_attrs).perform }

  def create_project(name:, repository_storage: 'default', pending_delete: false)
    project_namespace = namespaces.create!(
      name: name,
      path: name,
      type: 'Project',
      organization_id: organization.id
    )

    projects.create!(
      name: name,
      path: name,
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id,
      repository_storage: repository_storage,
      pending_delete: pending_delete
    )
  end

  def expected_disk_path(project_id)
    hash = Digest::SHA2.hexdigest(project_id.to_s)
    "@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}"
  end

  describe '#perform' do
    context 'when project is missing a project_repository record' do
      it 'creates a project_repository record' do
        expect { perform_migration }.to change { project_repositories.count }.by(1)

        record = project_repositories.find_by(project_id: project.id)
        expect(record).to have_attributes(
          shard_id: shard.id,
          disk_path: expected_disk_path(project.id)
        )
      end
    end

    context 'when project already has a project_repository record' do
      before do
        project_repositories.create!(
          project_id: project.id,
          shard_id: shard.id,
          disk_path: 'existing/path'
        )
      end

      it 'does not create a duplicate record' do
        expect { perform_migration }.not_to change { project_repositories.count }
      end

      it 'does not modify the existing record' do
        perform_migration

        record = project_repositories.find_by(project_id: project.id)
        expect(record.disk_path).to eq('existing/path')
      end
    end

    context 'when project is pending deletion' do
      let!(:project) { create_project(name: 'pending-delete', pending_delete: true) }

      it 'does not create a project_repository record' do
        expect { perform_migration }.not_to change { project_repositories.count }
      end
    end

    context 'when multiple projects have mixed states' do
      let!(:project_existing) { create_project(name: 'existing') }
      let!(:project_deleted) { create_project(name: 'deleted', pending_delete: true) }

      before do
        project_repositories.create!(
          project_id: project_existing.id,
          shard_id: shard.id,
          disk_path: 'existing/disk/path'
        )
      end

      it 'only creates records for projects missing them' do
        expect { perform_migration }.to change { project_repositories.count }.by(1)

        expect(project_repositories.find_by(project_id: project.id)).to be_present
        expect(project_repositories.find_by(project_id: project_deleted.id)).to be_nil
      end
    end

    context 'when project is on a different shard' do
      let!(:other_shard) { shards.create!(name: 'other-storage') }
      let!(:project) { create_project(name: 'other-shard', repository_storage: 'other-storage') }

      it 'creates a record with the correct shard_id' do
        perform_migration

        record = project_repositories.find_by(project_id: project.id)
        expect(record.shard_id).to eq(other_shard.id)
      end
    end

    context 'when the disk_path is computed correctly' do
      let!(:project) { create_project(name: 'hash-check') }

      it 'matches the Ruby Digest::SHA2.hexdigest computation' do
        perform_migration

        record = project_repositories.find_by(project_id: project.id)
        hash = Digest::SHA2.hexdigest(project.id.to_s)

        expect(record.disk_path).to eq("@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}")
      end
    end
  end
end
