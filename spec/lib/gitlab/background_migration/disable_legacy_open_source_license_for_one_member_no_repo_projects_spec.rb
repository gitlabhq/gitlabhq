# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DisableLegacyOpenSourceLicenseForOneMemberNoRepoProjects,
  :migration,
  schema: 20231220225325 do
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_settings_table) { table(:project_settings) }
  let(:project_statistics_table) { table(:project_statistics) }
  let(:users_table) { table(:users) }
  let(:project_authorizations_table) { table(:project_authorizations) }

  let(:organization) { organizations_table.create!(name: "organization", path: "organization") }

  subject(:perform_migration) do
    described_class.new(start_id: projects_table.minimum(:id),
      end_id: projects_table.maximum(:id),
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection)
                   .perform
  end

  it 'sets `legacy_open_source_license_available` to false only for public projects with 1 member and no repo',
    :aggregate_failures do
    project_with_no_repo_one_member = create_legacy_license_public_project('project-with-one-member-no-repo')
    project_with_repo_one_member = create_legacy_license_public_project('project-with-repo', repo_size: 1)
    project_with_no_repo_two_members = create_legacy_license_public_project('project-with-two-members', members: 2)
    project_with_repo_two_members =
      create_legacy_license_public_project('project-with-repo', repo_size: 1, members: 2)

    queries = ActiveRecord::QueryRecorder.new { perform_migration }

    expect(queries.count).to eq(7)
    expect(migrated_attribute(project_with_no_repo_one_member)).to be_falsey
    expect(migrated_attribute(project_with_repo_one_member)).to be_truthy
    expect(migrated_attribute(project_with_no_repo_two_members)).to be_truthy
    expect(migrated_attribute(project_with_repo_two_members)).to be_truthy
  end

  def create_legacy_license_public_project(path, repo_size: 0, members: 1)
    namespace = namespaces_table.create!(
      organization_id: organization.id,
      name: "namespace-#{path}",
      path: "namespace-#{path}"
    )

    project_namespace = namespaces_table.create!(
      organization_id: organization.id,
      name: "-project-namespace-#{path}",
      path: "project-namespace-#{path}",
      type: 'Project'
    )

    project = projects_table
      .create!(
        name: path, path: path, namespace_id: namespace.id, organization_id: organization.id,
        project_namespace_id: project_namespace.id, visibility_level: 20
      )

    members.times do |member_id|
      user = users_table.create!(email: "user#{member_id}-project-#{project.id}@gitlab.com", projects_limit: 100)
      project_authorizations_table.create!(project_id: project.id, user_id: user.id, access_level: 50)
    end
    project_statistics_table.create!(project_id: project.id, namespace_id: namespace.id, repository_size: repo_size)
    project_settings_table.create!(project_id: project.id, legacy_open_source_license_available: true)

    project
  end

  def migrated_attribute(project)
    project_settings_table.find(project.id).legacy_open_source_license_available
  end
end
