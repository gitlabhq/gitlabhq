# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateVulnerabilitiesOccurrencesUuid, schema: 20201110110454 do
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user) { create_user! }
  let(:project) { table(:projects).create!(id: 123, namespace_id: namespace.id) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let(:different_scanner) { scanners.create!(project_id: project.id, external_id: 'test 2', name: 'test scanner 2') }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerabilities_findings) { table(:vulnerability_occurrences) }
  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let(:vulnerability_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'uuid-v5',
      external_id: 'uuid-v5',
      fingerprint: '7e394d1b1eb461a7406d7b1e08f057a1cf11287a',
      name: 'Identifier for UUIDv5')
  end

  let(:different_vulnerability_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'uuid-v4',
      external_id: 'uuid-v4',
      fingerprint: '772da93d34a1ba010bcb5efa9fb6f8e01bafcc89',
      name: 'Identifier for UUIDv4')
  end

  let!(:vulnerability_for_uuidv4) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:vulnerability_for_uuidv5) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let(:known_uuid_v5) { "77211ed6-7dff-5f6b-8c9a-da89ad0a9b60" }
  let(:known_uuid_v4) { "b3cc2518-5446-4dea-871c-89d5e999c1ac" }
  let(:desired_uuid_v5) { "3ca8ad45-6344-508b-b5e3-306a3bd6c6ba" }

  subject { described_class.new.perform(finding.id, finding.id) }

  context "when finding has a UUIDv4" do
    before do
      @uuid_v4 = create_finding!(
        vulnerability_id: vulnerability_for_uuidv4.id,
        project_id: project.id,
        scanner_id: different_scanner.id,
        primary_identifier_id: different_vulnerability_identifier.id,
        report_type: 0, # "sast"
        location_fingerprint: "fa18f432f1d56675f4098d318739c3cd5b14eb3e",
        uuid: known_uuid_v4
      )
    end

    let(:finding) { @uuid_v4 }

    it "replaces it with UUIDv5" do
      expect(vulnerabilities_findings.pluck(:uuid)).to eq([known_uuid_v4])

      subject

      expect(vulnerabilities_findings.pluck(:uuid)).to eq([desired_uuid_v5])
    end

    it 'logs recalculation' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:info).once
      end

      subject
    end
  end

  context "when finding has a UUIDv5" do
    before do
      @uuid_v5 = create_finding!(
        vulnerability_id: vulnerability_for_uuidv5.id,
        project_id: project.id,
        scanner_id: scanner.id,
        primary_identifier_id: vulnerability_identifier.id,
        report_type: 0, # "sast"
        location_fingerprint: "838574be0210968bf6b9f569df9c2576242cbf0a",
        uuid: known_uuid_v5
      )
    end

    let(:finding) { @uuid_v5 }

    it "stays the same" do
      expect(vulnerabilities_findings.pluck(:uuid)).to eq([known_uuid_v5])

      subject

      expect(vulnerabilities_findings.pluck(:uuid)).to eq([known_uuid_v5])
    end
  end

  context 'when recalculation fails' do
    before do
      @uuid_v4 = create_finding!(
        vulnerability_id: vulnerability_for_uuidv4.id,
        project_id: project.id,
        scanner_id: different_scanner.id,
        primary_identifier_id: different_vulnerability_identifier.id,
        report_type: 0, # "sast"
        location_fingerprint: "fa18f432f1d56675f4098d318739c3cd5b14eb3e",
        uuid: known_uuid_v4
      )

      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      allow(::Gitlab::Database::BulkUpdate).to receive(:execute).and_raise(expected_error)
    end

    let(:finding) { @uuid_v4 }
    let(:expected_error) { RuntimeError.new }

    it 'captures the errors and does not crash entirely' do
      expect { subject }.not_to raise_error

      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception).with(expected_error).once
    end
  end

  private

  def create_vulnerability!(project_id:, author_id:, title: 'test', severity: 7, confidence: 7, report_type: 0)
    vulnerabilities.create!(
      project_id: project_id,
      author_id: author_id,
      title: title,
      severity: severity,
      confidence: confidence,
      report_type: report_type
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def create_finding!(
    vulnerability_id:, project_id:, scanner_id:, primary_identifier_id:,
                      name: "test", severity: 7, confidence: 7, report_type: 0,
                      project_fingerprint: '123qweasdzxc', location_fingerprint: 'test',
                      metadata_version: 'test', raw_metadata: 'test', uuid: 'test')
    vulnerabilities_findings.create!(
      vulnerability_id: vulnerability_id,
      project_id: project_id,
      name: name,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      project_fingerprint: project_fingerprint,
      scanner_id: scanner.id,
      primary_identifier_id: vulnerability_identifier.id,
      location_fingerprint: location_fingerprint,
      metadata_version: metadata_version,
      raw_metadata: raw_metadata,
      uuid: uuid
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil, created_at: Time.zone.now, confirmed_at: Time.zone.now)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: confirmed_at
    )
  end
end
