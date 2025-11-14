# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSolutionToVulnerabilities, feature_category: :vulnerability_management do
  let(:organization) { table(:organizations).create!(name: 'org', path: 'org') }
  let(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let(:user) { table(:users).create!(projects_limit: 100, organization_id: organization.id) }
  let(:identifiers) { table(:vulnerability_identifiers, database: :sec) }
  let(:scanners) { table(:vulnerability_scanners, database: :sec) }
  let(:findings) { table(:vulnerability_occurrences, database: :sec) }
  let(:vulnerabilities) { table(:vulnerabilities, database: :sec) }
  let(:now) { Time.zone.now }
  let(:primary_identifier) do
    identifiers.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      fingerprint: SecureRandom.uuid,
      external_type: 'CWE',
      external_id: 'CWE-1',
      name: 'Injection'
    )
  end

  let(:scanner) do
    scanners.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      external_id: 'semgrep',
      name: 'Semgrep'
    )
  end

  let!(:batch) { ('1'..'3').map { |solution| create_vulnerability(finding_solution: solution) } }

  subject(:perform_migration) do
    described_class.new(
      start_id: vulnerabilities.minimum(:id),
      end_id: vulnerabilities.maximum(:id),
      batch_table: :vulnerabilities,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ::SecApplicationRecord.connection
    ).perform
  end

  it 'backfills the solution from finding to vulnerability' do
    expect { perform_migration }.to change { batch.map { |vulnerability| vulnerability.reload.solution } }
      .from([nil, nil, nil])
      .to(%w[1 2 3])
  end

  context 'when solution is already set' do
    let!(:vulnerability) { create_vulnerability(finding_solution: 'a', vulnerability_solution: 'b') }

    it 'does not change vulnerability solution' do
      expect { perform_migration }.not_to change { vulnerability.reload.solution }.from('b')
    end
  end

  context 'when finding solution is nil' do
    let!(:vulnerability) { create_vulnerability(finding_solution: nil, vulnerability_solution: 'b') }

    it 'does not change vulnerability solution' do
      expect { perform_migration }.not_to change { vulnerability.reload.solution }.from('b')
    end
  end

  def create_vulnerability(finding_solution:, vulnerability_solution: nil)
    finding = findings.create!(
      solution: finding_solution,
      created_at: now,
      updated_at: now,
      uuid: SecureRandom.uuid,
      severity: 1,
      report_type: 1,
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: primary_identifier.id,
      location_fingerprint: '0',
      name: 'Test vulnerability',
      metadata_version: '1'
    )

    vulnerability = vulnerabilities.create!(
      project_id: project.id,
      finding_id: finding.id,
      author_id: user.id,
      created_at: now,
      updated_at: now,
      title: 'Test vulnerability',
      solution: vulnerability_solution,
      severity: 1,
      report_type: 1
    )

    finding.update!(vulnerability_id: vulnerability.id)

    vulnerability
  end
end
