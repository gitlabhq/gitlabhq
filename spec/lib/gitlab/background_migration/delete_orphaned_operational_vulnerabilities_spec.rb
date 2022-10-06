# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedOperationalVulnerabilities, :migration do
  include MigrationHelpers::VulnerabilitiesHelper

  let_it_be(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let_it_be(:users) { table(:users) }
  let_it_be(:user) do
    users.create!(
      name: "Example User",
      email: "user@example.com",
      username: "Example User",
      projects_limit: 0,
      confirmed_at: Time.current
    )
  end

  let_it_be(:project) do
    table(:projects).create!(
      id: 123,
      namespace_id: namespace.id,
      project_namespace_id: namespace.id
    )
  end

  let_it_be(:scanners) { table(:vulnerability_scanners) }
  let_it_be(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let_it_be(:different_scanner) do
    scanners.create!(
      project_id: project.id,
      external_id: 'test 2',
      name: 'test scanner 2'
    )
  end

  let_it_be(:vulnerabilities) { table(:vulnerabilities) }
  let_it_be(:vulnerability_with_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let_it_be(:vulnerability_without_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let_it_be(:cis_vulnerability_without_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      report_type: 7
    )
  end

  let_it_be(:custom_vulnerability_without_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      report_type: 99
    )
  end

  let_it_be(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let_it_be(:primary_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'uuid-v5',
      external_id: 'uuid-v5',
      fingerprint: '7e394d1b1eb461a7406d7b1e08f057a1cf11287a',
      name: 'Identifier for UUIDv5')
  end

  let_it_be(:vulnerabilities_findings) { table(:vulnerability_occurrences) }
  let_it_be(:finding) do
    create_finding!(
      vulnerability_id: vulnerability_with_finding.id,
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: primary_identifier.id
    )
  end

  subject(:background_migration) do
    described_class.new(start_id: vulnerabilities.minimum(:id),
                        end_id: vulnerabilities.maximum(:id),
                        batch_table: :vulnerabilities,
                        batch_column: :id,
                        sub_batch_size: 2,
                        pause_ms: 0,
                        connection: ActiveRecord::Base.connection)
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
