# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedOperationalVulnerabilities, :migration do
  include MigrationHelpers::VulnerabilitiesHelper

  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:users) { table(:users) }
  let!(:user) do
    users.create!(
      name: "Example User",
      email: "user@example.com",
      username: "Example User",
      projects_limit: 0,
      confirmed_at: Time.current
    )
  end

  let!(:project) do
    table(:projects).create!(
      id: 123,
      namespace_id: namespace.id,
      project_namespace_id: namespace.id
    )
  end

  let!(:scanners) { table(:vulnerability_scanners) }
  let!(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let!(:different_scanner) do
    scanners.create!(
      project_id: project.id,
      external_id: 'test 2',
      name: 'test scanner 2'
    )
  end

  let!(:vulnerabilities_findings) { table(:vulnerability_occurrences) }
  let!(:finding) do
    create_finding!(
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: primary_identifier.id
    )
  end

  let!(:vulnerabilities) { table(:vulnerabilities) }
  let!(:vulnerability_with_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      finding_id: finding.id
    )
  end

  let!(:vulnerability_without_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      finding_id: finding.id
    )
  end

  let!(:cis_vulnerability_without_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      report_type: 7,
      finding_id: finding.id
    )
  end

  let!(:custom_vulnerability_without_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      report_type: 99,
      finding_id: finding.id
    )
  end

  let!(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let!(:primary_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'uuid-v5',
      external_id: 'uuid-v5',
      fingerprint: '7e394d1b1eb461a7406d7b1e08f057a1cf11287a',
      name: 'Identifier for UUIDv5')
  end

  subject(:background_migration) do
    described_class.new(
      start_id: vulnerabilities.minimum(:id),
      end_id: vulnerabilities.maximum(:id),
      batch_table: :vulnerabilities,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    )
  end

  it 'drops Cluster Image Scanning and Custom Vulnerabilities without any Findings' do
    expect(vulnerabilities.pluck(:id)).to match_array([
                                                        vulnerability_with_finding.id,
                                                        vulnerability_without_finding.id,
                                                        cis_vulnerability_without_finding.id,
                                                        custom_vulnerability_without_finding.id
                                                      ])

    expect { background_migration.perform }.to change(vulnerabilities, :count).by(-2)

    expect(vulnerabilities.pluck(:id)).to match_array([vulnerability_with_finding.id, vulnerability_without_finding.id])
  end
end
