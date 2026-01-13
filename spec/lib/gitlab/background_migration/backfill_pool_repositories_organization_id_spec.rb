# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPoolRepositoriesOrganizationId,
  feature_category: :source_code_management do
  let(:connection) { ApplicationRecord.connection }

  let(:namespaces_table) { table(:namespaces) }
  let(:organizations_table) { table(:organizations) }
  let(:projects_table) { table(:projects) }
  let(:pool_repositories_table) { table(:pool_repositories) }

  # Create default organization with ID 1 (this is typically the default
  #   organization in GitLab)
  #
  let!(:default_organization) do
    organizations_table.find_or_create_by!(path: 'default') do |org|
      org.id = 1
      org.name = 'default'
    end
  end

  let!(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }
  let!(:organization2) { organizations_table.create!(name: 'organization2', path: 'organization2') }

  # Create a shard for pool repositories
  #
  let!(:shard) { table(:shards).create!(name: 'default') }

  let!(:group1) do
    namespaces_table.create!(name: 'group1', path: 'group1', type: 'Group', organization_id: organization.id)
  end

  let!(:group2) do
    namespaces_table.create!(name: 'group2', path: 'group2', type: 'Group', organization_id: organization2.id)
  end

  # Create project namespaces (these are what project_namespace_id references)
  #
  let!(:project_namespace1) do
    namespaces_table.create!(
      name: 'project1',
      path: 'project1',
      type: 'Project',
      parent_id: group1.id,
      organization_id: organization.id
    )
  end

  let!(:project_namespace2) do
    namespaces_table.create!(
      name: 'project2',
      path: 'project2',
      type: 'Project',
      parent_id: group2.id,
      organization_id: organization2.id
    )
  end

  let!(:project1) do
    projects_table.create!(
      name: 'project1',
      path: 'project1',
      organization_id: organization.id,
      project_namespace_id: project_namespace1.id,
      namespace_id: group1.id
    )
  end

  let!(:project2) do
    projects_table.create!(
      name: 'project2',
      path: 'project2',
      organization_id: organization2.id,
      project_namespace_id: project_namespace2.id,
      namespace_id: group2.id
    )
  end

  let(:migration_args) do
    {
      start_id: pool_repositories_table.minimum(:id),
      end_id: pool_repositories_table.maximum(:id),
      batch_table: :pool_repositories,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  describe '#perform' do
    context 'when pool_repository has source_project_id' do
      it 'backfills organization_id from source project' do
        pool_repo = pool_repositories_table.create!(
          source_project_id: project1.id,
          organization_id: nil,
          disk_path: 'pool/path1',
          state: 'ready',
          shard_id: shard.id
        )

        described_class.new(**migration_args).perform

        pool_repo.reload
        expect(pool_repo.organization_id).to eq(organization.id)
      end
    end

    context 'when pool_repository has no source_project_id but has member projects' do
      it 'backfills organization_id from member projects' do
        # Temporarily disable the trigger for this test
        connection.execute('DROP TRIGGER IF EXISTS trigger_pool_repositories_sharding_key ON pool_repositories')

        pool_repo = pool_repositories_table.create!(
          source_project_id: nil,
          organization_id: nil,
          disk_path: 'pool/path2',
          state: 'ready',
          shard_id: shard.id
        )

        # Verify it's actually NULL
        expect(pool_repo.organization_id).to be_nil

        # Set project2 as a member of the pool
        connection.execute(
          "UPDATE projects SET pool_repository_id = #{pool_repo.id} WHERE id = #{project2.id}"
        )

        # Re-enable the trigger
        connection.execute(<<~SQL)
      CREATE TRIGGER trigger_pool_repositories_sharding_key
      BEFORE INSERT OR UPDATE ON pool_repositories
      FOR EACH ROW
      EXECUTE FUNCTION pool_repositories_sharding_key()
        SQL

        described_class.new(**migration_args).perform

        pool_repo.reload

        expect(pool_repo.organization_id).to eq(organization2.id)
      end
    end

    context 'when pool_repository has no source_project_id and no member projects' do
      it 'backfills organization_id with default value 1' do
        pool_repo = pool_repositories_table.create!(
          source_project_id: nil,
          organization_id: nil,
          disk_path: 'pool/path3',
          state: 'ready',
          shard_id: shard.id
        )

        described_class.new(**migration_args).perform

        pool_repo.reload

        expect(pool_repo.organization_id).to eq(1)
      end
    end

    context 'when pool_repository already has organization_id' do
      it 'does not change existing organization_id' do
        pool_repo = pool_repositories_table.create!(
          source_project_id: project1.id,
          organization_id: organization2.id,
          disk_path: 'pool/path4',
          state: 'ready',
          shard_id: shard.id
        )

        described_class.new(**migration_args).perform

        pool_repo.reload

        expect(pool_repo.organization_id).to eq(organization2.id)
      end
    end

    context 'with mixed scenarios' do
      it 'handles all cases correctly in priority order' do
        # Case 1b: Has source_project_id (trigger handles this correctly)
        pool_repo1 = pool_repositories_table.create!(
          source_project_id: project1.id,
          organization_id: nil,
          disk_path: 'pool/path5',
          state: 'ready',
          shard_id: shard.id
        )

        # Temporarily disable the trigger for this test
        connection.execute('DROP TRIGGER IF EXISTS trigger_pool_repositories_sharding_key ON pool_repositories')

        pool_repositories_table.create!(
          source_project_id: nil,
          organization_id: nil,
          disk_path: 'pool/path2',
          state: 'ready',
          shard_id: shard.id
        )

        # Case 2: No source_project_id but has member projects (bypass trigger)
        pool_repo2_id = connection.execute(<<~SQL).first['id']
      INSERT INTO pool_repositories (source_project_id, organization_id, disk_path, state, shard_id)
      VALUES (NULL, NULL, 'pool/path6', 'ready', #{shard.id})
      RETURNING id
        SQL
        pool_repo2 = pool_repositories_table.find(pool_repo2_id)

        connection.execute(
          "UPDATE projects SET pool_repository_id = #{pool_repo2.id} WHERE id = #{project2.id}"
        )

        # Case 3: No source_project_id and no member projects (bypass trigger)
        pool_repo3_id = connection.execute(<<~SQL).first['id']
      INSERT INTO pool_repositories (source_project_id, organization_id, disk_path, state, shard_id)
      VALUES (NULL, NULL, 'pool/path7', 'ready', #{shard.id})
      RETURNING id
        SQL
        pool_repo3 = pool_repositories_table.find(pool_repo3_id)

        # Re-enable the trigger
        connection.execute(<<~SQL)
      CREATE TRIGGER trigger_pool_repositories_sharding_key
      BEFORE INSERT OR UPDATE ON pool_repositories
      FOR EACH ROW
      EXECUTE FUNCTION pool_repositories_sharding_key()
        SQL

        described_class.new(**migration_args).perform

        pool_repo1.reload
        pool_repo2.reload
        pool_repo3.reload

        expect(pool_repo1.organization_id).to eq(organization.id)
        expect(pool_repo2.organization_id).to eq(organization2.id)
        expect(pool_repo3.organization_id).to eq(1)
      end
    end
  end
end
