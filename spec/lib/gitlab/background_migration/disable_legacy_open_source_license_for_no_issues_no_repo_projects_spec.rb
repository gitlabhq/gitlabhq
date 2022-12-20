# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DisableLegacyOpenSourceLicenseForNoIssuesNoRepoProjects,
               :migration,
               schema: 20220722084543 do
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_settings_table) { table(:project_settings) }
  let(:project_statistics_table) { table(:project_statistics) }
  let(:issues_table) { table(:issues) }

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

  it 'sets `legacy_open_source_license_available` to false only for public projects with no issues and no repo',
     :aggregate_failures do
    project_with_no_issues_no_repo = create_legacy_license_public_project('project-with-no-issues-no-repo')
    project_with_repo = create_legacy_license_public_project('project-with-repo', repo_size: 1)
    project_with_issues = create_legacy_license_public_project('project-with-issues', with_issue: true)
    project_with_issues_and_repo =
      create_legacy_license_public_project('project-with-issues-and-repo', repo_size: 1, with_issue: true)

    queries = ActiveRecord::QueryRecorder.new { perform_migration }

    expect(queries.count).to eq(7)
    expect(migrated_attribute(project_with_no_issues_no_repo)).to be_falsey
    expect(migrated_attribute(project_with_repo)).to be_truthy
    expect(migrated_attribute(project_with_issues)).to be_truthy
    expect(migrated_attribute(project_with_issues_and_repo)).to be_truthy
  end

  def create_legacy_license_public_project(path, repo_size: 0, with_issue: false)
    namespace = namespaces_table.create!(name: "namespace-#{path}", path: "namespace-#{path}")
    project_namespace =
      namespaces_table.create!(name: "-project-namespace-#{path}", path: "project-namespace-#{path}", type: 'Project')
    project = projects_table
                .create!(
                  name: path, path: path, namespace_id: namespace.id,
                  project_namespace_id: project_namespace.id, visibility_level: 20
                )

    project_statistics_table.create!(project_id: project.id, namespace_id: namespace.id, repository_size: repo_size)
    issues_table.create!(project_id: project.id, namespace_id: project.project_namespace_id) if with_issue
    project_settings_table.create!(project_id: project.id, legacy_open_source_license_available: true)

    project
  end

  def migrated_attribute(project)
    project_settings_table.find(project.id).legacy_open_source_license_available
  end
end
