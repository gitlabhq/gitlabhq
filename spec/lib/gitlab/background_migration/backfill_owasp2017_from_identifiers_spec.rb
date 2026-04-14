# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOwasp2017FromIdentifiers, feature_category: :vulnerability_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:identifiers) { table(:vulnerability_identifiers, database: :sec) }
  let(:vulnerability_reads) { table(:vulnerability_reads, database: :sec) }
  let(:scanners) { table(:vulnerability_scanners, database: :sec) }
  let(:findings) { table(:vulnerability_occurrences, database: :sec) }
  let(:users) { table(:users) }
  let(:vulnerabilities) { table(:vulnerabilities, database: :sec) }

  let(:now) { Time.zone.now.round(6) }
  let(:path) { 'gitlab' }
  let(:organization) { table(:organizations).create!(name: path, path: path) }
  let(:project) { create_project }
  let(:user) { table(:users).create!(projects_limit: 1, organization_id: organization.id) }

  let(:scanner) do
    scanners.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      external_id: 'semgrep',
      name: 'Semgrep'
    )
  end

  let(:owasp_2017_injection_identifier) do
    identifiers.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      fingerprint: '0',
      external_type: 'owasp',
      external_id: 'A1:2017',
      name: 'A1:2017 - Injection'
    )
  end

  let(:owasp_2021_injection_identifier) do
    identifiers.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      fingerprint: '1',
      external_type: 'owasp',
      external_id: 'A03:2021',
      name: 'A03:2021 - Injection'
    )
  end

  let(:non_owasp_identifier) do
    identifiers.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      fingerprint: '2',
      external_type: 'CWE',
      external_id: 'CWE-1',
      name: 'Injection'
    )
  end

  let!(:vulnerability_with_2017_owasp) do
    create_vulnerability_read(
      owasp_top_10: 1, # A1:2017-Injection
      identifier_names: ["A03:2021 - Injection", "A1:2017 - Injection"],
      primary_identifier: owasp_2017_injection_identifier
    )
  end

  let!(:vulnerability_with_2021_owasp) do
    create_vulnerability_read(
      owasp_top_10: 13, # A3:2021-Injection,
      identifier_names: ["A03:2021 - Injection", "A1:2017 - Injection"],
      primary_identifier: owasp_2021_injection_identifier
    )
  end

  let(:vulnerability_with_no_2017_identifier) do
    create_vulnerability_read(
      owasp_top_10: 13, # A3:2021-Injection,
      identifier_names: ["A03:2021 - Injection"],
      primary_identifier: owasp_2021_injection_identifier
    )
  end

  let!(:vulnerability_with_2021_owasp_alt) do
    create_vulnerability_read(
      owasp_top_10: 13, # A3:2021-Injection,
      identifier_names: ["A03:2021 - Injection", "A1:2017 - Injection"],
      primary_identifier: owasp_2021_injection_identifier
    )
  end

  let!(:vulnerability_with_undefined_owasp) do
    create_vulnerability_read(
      owasp_top_10: -1, # Undefined
      identifier_names: ["CVE-2018-1234"],
      primary_identifier: non_owasp_identifier
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: vulnerability_reads.minimum(:vulnerability_id),
      end_id: vulnerability_reads.maximum(:vulnerability_id),
      batch_table: :vulnerability_reads,
      batch_column: :vulnerability_id,
      sub_batch_size: vulnerability_reads.count,
      pause_ms: 0,
      connection: SecApplicationRecord.connection
    ).perform
  end

  context 'when owasp_top_10 column is present' do
    it "preserves already present 2017 owasp enum" do
      expect { perform_migration }.not_to change { vulnerability_with_2017_owasp.reload.owasp_top_10 }
    end

    it "updates 2021 owasp enum to 2017" do
      expect { perform_migration }.to change {
        vulnerability_with_2021_owasp.reload.owasp_top_10
      }.from(13).to(1) # From A3:2021-Injection to A1:2017-Injection
    end

    it "updates 2021 owasp enum to 2017 (alternative format)" do
      expect { perform_migration }.to change {
        vulnerability_with_2021_owasp_alt.reload.owasp_top_10
      }.from(13).to(1) # From A3:2021-Injection to A1:2017-Injection
    end

    it "set 2021 values to undefined when no 2017 identifiers present" do
      expect { perform_migration }.to change {
        vulnerability_with_no_2017_identifier.reload.owasp_top_10
      }.from(13).to(-1) # From A3:2021-Injection to undefined
    end

    it "preserves undefined owasp_top_10 column" do
      expect { perform_migration }.not_to change { vulnerability_with_undefined_owasp.reload.owasp_top_10 }
    end
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

  def create_finding(identifier:)
    findings.create!(
      project_id: project.id,
      scanner_id: scanner.id,
      severity: 5,
      report_type: 99,
      primary_identifier_id: identifier.id,
      location_fingerprint: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      name: "CVE-2018-1234",
      raw_metadata: "{}",
      metadata_version: "test:1.0"
    )
  end

  def create_vulnerability_read(owasp_top_10:, identifier_names:, primary_identifier:)
    finding = create_finding(identifier: primary_identifier)

    vulnerability = vulnerabilities.create!(
      detected_at: nil,
      project_id: project.id,
      finding_id: finding.id,
      author_id: user.id,
      created_at: now,
      updated_at: now,
      title: 'Test vulnerability',
      severity: 1,
      report_type: 1
    )

    vulnerability_reads.create!(
      owasp_top_10: owasp_top_10,
      identifier_names: identifier_names,
      vulnerability_id: vulnerability.id,
      project_id: project.id,
      scanner_id: scanner.id,
      report_type: "sast",
      severity: "low",
      state: "detected",
      uuid: SecureRandom.uuid
    )
  end
end
