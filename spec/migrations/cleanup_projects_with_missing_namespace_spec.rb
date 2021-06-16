# frozen_string_literal: true

require 'spec_helper'

require_migration!('add_projects_foreign_key_to_namespaces')
require_migration!

# In order to test the CleanupProjectsWithMissingNamespace migration, we need
#  to first create an orphaned project (one with an invalid namespace_id)
#  and then run the migration to check that the project was properly cleaned up
#
# The problem is that the CleanupProjectsWithMissingNamespace migration comes
#  after the FK has been added with a previous migration (AddProjectsForeignKeyToNamespaces)
# That means that while testing the current class we can not insert projects with an
#  invalid namespace_id as the existing FK is correctly blocking us from doing so
#
# The approach that solves that problem is to:
# - Set the schema of this test to the one prior to AddProjectsForeignKeyToNamespaces
# - We could hardcode it to `20200508091106` (which currently is the previous
#   migration before adding the FK) but that would mean that this test depends
#   on migration 20200508091106 not being reverted or deleted
# - So, we use SchemaVersionFinder that finds the previous migration and returns
#   its schema, which we then use in the describe
#
# That means that we lock the schema version to the one returned by
#  SchemaVersionFinder.previous_migration and only test the cleanup migration
#  *without* the migration that adds the Foreign Key ever running
# That's acceptable as the cleanup script should not be affected in any way
#  by the migration that adds the Foreign Key
class SchemaVersionFinder
  def self.migrations_paths
    ActiveRecord::Migrator.migrations_paths
  end

  def self.migration_context
    ActiveRecord::MigrationContext.new(migrations_paths, ActiveRecord::SchemaMigration)
  end

  def self.migrations
    migration_context.migrations
  end

  def self.previous_migration
    migrations.each_cons(2) do |previous, migration|
      break previous.version if migration.name == AddProjectsForeignKeyToNamespaces.name
    end
  end
end

RSpec.describe CleanupProjectsWithMissingNamespace, :migration, schema: SchemaVersionFinder.previous_migration do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }

  before do
    namespace = namespaces.create!(name: 'existing_namespace', path: 'existing_namespace')

    projects.create!(
      name: 'project_with_existing_namespace',
      path: 'project_with_existing_namespace',
      visibility_level: 20,
      archived: false,
      namespace_id: namespace.id
    )

    projects.create!(
      name: 'project_with_non_existing_namespace',
      path: 'project_with_non_existing_namespace',
      visibility_level: 20,
      archived: false,
      namespace_id: non_existing_record_id
    )
  end

  it 'creates the ghost user' do
    expect(users.where(user_type: described_class::User::USER_TYPE_GHOST).count).to eq(0)

    disable_migrations_output { migrate! }

    expect(users.where(user_type: described_class::User::USER_TYPE_GHOST).count).to eq(1)
  end

  it 'creates the lost-and-found group, owned by the ghost user' do
    expect(
      described_class::Group.where(
        described_class::Group
        .arel_table[:name]
        .matches("#{described_class::User::LOST_AND_FOUND_GROUP}%")
      ).count
    ).to eq(0)

    disable_migrations_output { migrate! }

    ghost_user = users.find_by(user_type: described_class::User::USER_TYPE_GHOST)
    expect(
      described_class::Group
        .joins('INNER JOIN members ON namespaces.id = members.source_id')
        .where(namespaces: { type: 'Group' })
        .where(members: { type: 'GroupMember' })
        .where(members: { source_type: 'Namespace' })
        .where(members: { user_id: ghost_user.id })
        .where(members: { requested_at: nil })
        .where(members: { access_level: described_class::ACCESS_LEVEL_OWNER })
        .where(
          described_class::Group
          .arel_table[:name]
          .matches("#{described_class::User::LOST_AND_FOUND_GROUP}%")
        )
        .count
    ).to eq(1)
  end

  it 'moves the orphaned project to the lost-and-found group' do
    orphaned_project = projects.find_by(name: 'project_with_non_existing_namespace')
    expect(orphaned_project.visibility_level).to eq(20)
    expect(orphaned_project.archived).to eq(false)
    expect(orphaned_project.namespace_id).to eq(non_existing_record_id)

    disable_migrations_output { migrate! }

    lost_and_found_group = described_class::Group.find_by(
      described_class::Group
      .arel_table[:name]
      .matches("#{described_class::User::LOST_AND_FOUND_GROUP}%")
    )
    orphaned_project = projects.find_by(id: orphaned_project.id)

    expect(orphaned_project.visibility_level).to eq(0)
    expect(orphaned_project.namespace_id).to eq(lost_and_found_group.id)
    expect(orphaned_project.name).to eq("project_with_non_existing_namespace_#{orphaned_project.id}")
    expect(orphaned_project.path).to eq("project_with_non_existing_namespace_#{orphaned_project.id}")
    expect(orphaned_project.archived).to eq(true)

    valid_project = projects.find_by(name: 'project_with_existing_namespace')
    existing_namespace = namespaces.find_by(name: 'existing_namespace')

    expect(valid_project.visibility_level).to eq(20)
    expect(valid_project.namespace_id).to eq(existing_namespace.id)
    expect(valid_project.path).to eq('project_with_existing_namespace')
    expect(valid_project.archived).to eq(false)
  end
end
