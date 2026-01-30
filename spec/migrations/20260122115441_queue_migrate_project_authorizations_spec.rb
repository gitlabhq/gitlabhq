# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueMigrateProjectAuthorizations, migration: :gitlab_main, feature_category: :user_management do
  let!(:batched_migration) { described_class::MIGRATION }

  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:project_authorizations) { table(:project_authorizations) }

  let(:organization) { organizations.create!(name: 'foo', path: 'foo') }
  let(:user_a) do
    users.create!(username: 'foo', email: 'foo@bar.com', projects_limit: 0, organization_id: organization.id)
  end

  let(:user_b) do
    users.create!(username: 'bar', email: 'bar@qux.com', projects_limit: 0, organization_id: organization.id)
  end

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo', organization_id: organization.id) }

  let(:project) do
    projects.create!(
      name: 'foo',
      path: 'foo',
      project_namespace_id: namespace.id,
      namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let(:access_level) { Gitlab::Access::DEVELOPER }

  let!(:auth_a) do
    project_authorizations.create!(user_id: user_a.id, project_id: project.id, access_level: access_level)
  end

  let!(:auth_b) do
    project_authorizations.create!(user_id: user_b.id, project_id: project.id, access_level: access_level)
  end

  let(:batch_min_delay) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_MIN_DELAY }
  let(:batch_class_name) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_CLASS_NAME }
  let(:batch_size) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_SIZE }
  let(:sub_batch_size) { Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::SUB_BATCH_SIZE }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: "gitlab_main",
          job_class_name: described_class::MIGRATION,
          job_arguments: [],
          table_name: described_class::TABLE_NAME,
          column_name: :user_id,
          min_cursor: [0, 0, 0],
          max_cursor: [user_b.id, project.id, access_level],
          interval: batch_min_delay,
          pause_ms: 100,
          batch_class_name: batch_class_name,
          batch_size: batch_size,
          sub_batch_size: sub_batch_size,
          status: 1
        )
      }
    end
  end
end
