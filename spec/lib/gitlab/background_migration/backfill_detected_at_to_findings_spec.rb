# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDetectedAtToFindings, feature_category: :vulnerability_management do
  let(:tracked_contexts) { table(:security_project_tracked_contexts, database: :sec) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:identifiers) { table(:vulnerability_identifiers, database: :sec) }
  let(:scanners) { table(:vulnerability_scanners, database: :sec) }
  let(:findings) { table(:vulnerability_occurrences, database: :sec) }
  let(:vulnerabilities) { table(:vulnerabilities, database: :sec) }

  # Postgres has 6 digits of precision so we round to keep the
  # timestamp from changing on save.
  let(:now) { Time.zone.now.round(6) }
  let(:path) { 'test' }
  let(:organization) { table(:organizations).create!(name: path, path: path) }
  let(:user) { table(:users).create!(projects_limit: 1, organization_id: organization.id) }
  let(:project) { create_project }
  let(:primary_identifier) do
    identifiers.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      fingerprint: '0',
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

  let!(:finding_without_detected_at) { create_finding(finding_detected_at: nil, vulnerability_detected_at: now) }
  let!(:finding_with_detected_at) do
    create_finding(finding_detected_at: now - 1.hour, vulnerability_detected_at: now)
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: findings.minimum(:id),
      end_id: findings.maximum(:id),
      batch_table: :vulnerability_occurrences,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: SecApplicationRecord.connection
    ).perform
  end

  it 'backfills detected_at to records where it is nil' do
    expect { perform_migration }.to change { finding_without_detected_at.reload.detected_at }.from(nil).to(now)
      .and not_change { finding_with_detected_at.reload.detected_at }
  end

  def create_project
    namespace = namespaces.create!(
      name: path,
      path: path,
      organization_id: organization.id
    )

    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id,
      name: path,
      path: path
    )
  end

  def create_finding(vulnerability_detected_at:, finding_detected_at:)
    finding = findings.create!(
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
    # create! sets the database default when an explicit nil is passed in,
    # so we need to update the record in order to get a nil detected_at column.
    finding.update!(detected_at: finding_detected_at)

    vulnerability = vulnerabilities.create!(
      detected_at: vulnerability_detected_at,
      project_id: project.id,
      finding_id: finding.id,
      author_id: user.id,
      created_at: now,
      updated_at: now,
      title: 'Test vulnerability',
      severity: 1,
      report_type: 1
    )

    finding.update!(vulnerability_id: vulnerability.id)

    finding
  end
end
