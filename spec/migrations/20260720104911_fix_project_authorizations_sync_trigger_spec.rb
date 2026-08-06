# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixProjectAuthorizationsSyncTrigger, migration: :gitlab_main, feature_category: :user_management do
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:project_authorizations) { table(:project_authorizations) }
  let(:migration_table) { table(:project_authorizations_for_migration) }

  let(:organization) { organizations.create!(name: 'foo', path: 'foo') }
  let(:user) do
    users.create!(username: 'foo', email: 'foo@bar.com', projects_limit: 0, organization_id: organization.id)
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

  let!(:auth_reporter) do
    project_authorizations.create!(user_id: user.id, project_id: project.id,
      access_level: Gitlab::Access::REPORTER)
  end

  let!(:auth_developer) do
    project_authorizations.create!(user_id: user.id, project_id: project.id,
      access_level: Gitlab::Access::DEVELOPER)
  end

  def delete_authorization(access_level)
    project_authorizations
      .where(user_id: user.id, project_id: project.id, access_level: access_level)
      .delete_all
  end

  describe '#up' do
    before do
      migrate!
    end

    it 'keeps the destination row when a duplicate source row remains', :aggregate_failures do
      expect { delete_authorization(Gitlab::Access::DEVELOPER) }
        .not_to change { migration_table.count }

      destination_row = migration_table.find_by!(user_id: user.id, project_id: project.id)

      expect(destination_row.access_level).to eq(Gitlab::Access::REPORTER)
    end

    it 'removes the destination row with the last source row' do
      delete_authorization(Gitlab::Access::DEVELOPER)
      delete_authorization(Gitlab::Access::REPORTER)

      expect(migration_table.where(user_id: user.id, project_id: project.id)).to be_empty
    end

    it 'removes the destination row when all duplicates are deleted in one statement' do
      project_authorizations.where(user_id: user.id, project_id: project.id).delete_all

      expect(migration_table.where(user_id: user.id, project_id: project.id)).to be_empty
    end

    it 'syncs new source rows to the destination table' do
      other_namespace = namespaces.create!(name: 'bar', path: 'bar', organization_id: organization.id)
      other_project = projects.create!(
        name: 'bar',
        path: 'bar',
        project_namespace_id: other_namespace.id,
        namespace_id: other_namespace.id,
        organization_id: organization.id)

      project_authorizations.create!(user_id: user.id, project_id: other_project.id,
        access_level: Gitlab::Access::DEVELOPER)

      destination_row = migration_table.find_by!(user_id: user.id, project_id: other_project.id)

      expect(destination_row.access_level).to eq(Gitlab::Access::DEVELOPER)
    end

    it 'syncs access level updates to the destination table' do
      project_authorizations
        .where(user_id: user.id, project_id: project.id, access_level: Gitlab::Access::DEVELOPER)
        .update_all(access_level: Gitlab::Access::MAINTAINER)

      destination_row = migration_table.find_by!(user_id: user.id, project_id: project.id)

      expect(destination_row.access_level).to eq(Gitlab::Access::MAINTAINER)
    end
  end

  describe '#down' do
    before do
      migrate!
      schema_migrate_down!
    end

    it 'restores the previous behavior of deleting the destination row' do
      delete_authorization(Gitlab::Access::DEVELOPER)

      expect(migration_table.where(user_id: user.id, project_id: project.id)).to be_empty
    end
  end
end
