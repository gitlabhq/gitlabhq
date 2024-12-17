# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResyncHasVulnerabilities, feature_category: :vulnerability_management do
  let(:project_settings) { table(:project_settings) }
  let(:findings) { table(:vulnerability_occurrences) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:identifiers) { table(:vulnerability_identifiers) }
  let(:scanners) { table(:vulnerability_scanners) }
  let!(:user) { table(:users).create!(email: 'author@example.com', username: 'author', projects_limit: 10) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:true_without_vulnerabilities) do
    create_project_setting(
      'true-without-vulnerabilities',
      has_vulnerabilities_setting: true,
      actually_has_vulnerabilities: false
    )
  end

  let(:true_with_vulnerabilities) do
    create_project_setting(
      'true-with-vulnerabilities',
      has_vulnerabilities_setting: true,
      actually_has_vulnerabilities: true
    )
  end

  let(:false_with_vulnerabilities) do
    create_project_setting(
      'false-with-vulnerabilities',
      has_vulnerabilities_setting: false,
      actually_has_vulnerabilities: true
    )
  end

  let(:false_without_vulnerabilities) do
    create_project_setting(
      'false-without-vulnerabilities',
      has_vulnerabilities_setting: false,
      actually_has_vulnerabilities: false
    )
  end

  let(:has_vulnerabilities_on_non_default_branch) do
    create_project_setting(
      'non-default-branch',
      has_vulnerabilities_setting: false,
      actually_has_vulnerabilities: true,
      present_on_default_branch: false
    )
  end

  let(:args) do
    {
      start_id: project_settings.minimum(:project_id),
      end_id: project_settings.maximum(:project_id),
      batch_table: :project_settings,
      batch_column: :project_id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**args).perform }

  def create_project_setting(
    name,
    has_vulnerabilities_setting:,
    actually_has_vulnerabilities:,
    present_on_default_branch: true
  )
    organization = organizations.create!(name: "#{name}-organization", path: "#{name}-organization")
    group_namespace = namespaces.create!(name: name, path: name, organization_id: organization.id)
    project_namespace = namespaces.create!(name: name, path: name, organization_id: organization.id)
    project = projects.create!(
      name: name,
      path: name,
      namespace_id: group_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
    create_vulnerability(project, present_on_default_branch) if actually_has_vulnerabilities
    project_settings.create!(project_id: project.id, has_vulnerabilities: has_vulnerabilities_setting)
  end

  def create_vulnerability(project, present_on_default_branch)
    common_args = {
      project_id: project.id,
      severity: 1,
      report_type: 1
    }

    scanner = scanners.create!(project_id: project.id, external_id: 'id', name: 'name')

    primary_identifier = identifiers.create!(
      project_id: project.id,
      external_id: "CVE-2018-1234",
      external_type: "CVE",
      name: "CVE-2018-1234",
      fingerprint: SecureRandom.hex(20)
    )

    finding = findings.create!(
      scanner_id: scanner.id,
      primary_identifier_id: primary_identifier.id,
      project_fingerprint: SecureRandom.hex(20),
      location_fingerprint: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      name: 'name',
      raw_metadata: '{}',
      metadata_version: 'test:1.0',
      **common_args
    )

    vulnerabilities.create!(
      author_id: user.id,
      finding_id: finding.id,
      title: 'title',
      present_on_default_branch: present_on_default_branch,
      state: 1,
      **common_args
    )
  end

  it 'fixes only the incorrect records' do
    expect { perform_migration }.to change { true_without_vulnerabilities.reload.has_vulnerabilities }
      .from(true).to(false).and change { false_with_vulnerabilities.reload.has_vulnerabilities }.from(false).to(true)
      .and not_change { true_with_vulnerabilities.reload.has_vulnerabilities }
      .and not_change { false_without_vulnerabilities.reload.has_vulnerabilities }
      .and not_change { has_vulnerabilities_on_non_default_branch.reload.has_vulnerabilities }
  end
end
