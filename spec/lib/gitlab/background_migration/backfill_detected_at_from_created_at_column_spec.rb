# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDetectedAtFromCreatedAtColumn, :migration, schema: 20241021063020, feature_category: :vulnerability_management do
  let(:migration) do
    described_class.new(
      start_id: vulnerability_without_detected_at.id,
      end_id: vulnerability_without_detected_at.id,
      batch_table: :vulnerabilities,
      batch_column: batch_column,
      sub_batch_size: sub_batch_size,
      pause_ms: pause_ms,
      connection: ApplicationRecord.connection
    )
  end

  let(:batch_column) { :id }
  let(:sub_batch_size) { 1_000 }
  let(:pause_ms) { 0 }

  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:vulnerabilities_table) { table(:vulnerabilities) }
  let(:vulnerability_identifiers_table) { table(:vulnerability_identifiers) }
  let(:vulnerability_occurrences_table) { table(:vulnerability_occurrences) }
  let(:scanners_table) { table(:vulnerability_scanners) }

  let(:namespace) { namespaces_table.create!(name: 'test', path: 'test') }
  let(:project) do
    projects_table.create!(
      namespace_id: namespace.id,
      name: 'test',
      path: 'test',
      project_namespace_id: namespace.id
    )
  end

  # Add a scanner (required for vulnerability_occurrences)
  let(:scanner) do
    scanners_table.create!(
      project_id: project.id,
      external_id: 'test_scanner',
      name: 'test_scanner'
    )
  end

  # Create vulnerability identifier (required for vulnerability_occurrences)
  let(:identifier) do
    vulnerability_identifiers_table.create!(
      project_id: project.id,
      fingerprint: 'test-identifier',
      external_type: 'test_type',
      external_id: 'test_id',
      name: 'test_name'
    )
  end

  # Create vulnerability occurrences (findings)
  let!(:finding1) do
    vulnerability_occurrences_table.create!(
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: identifier.id,
      project_fingerprint: SecureRandom.hex(20),
      location_fingerprint: SecureRandom.hex(20),
      name: 'Test finding 1',
      severity: 5,
      confidence: 5,
      report_type: 1,
      uuid: SecureRandom.uuid,
      created_at: 2.days.ago,
      metadata_version: 'something',
      raw_metadata: {}
    )
  end

  let!(:finding2) do
    vulnerability_occurrences_table.create!(
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: identifier.id,
      project_fingerprint: SecureRandom.hex(20),
      location_fingerprint: SecureRandom.hex(20),
      name: 'Test finding 2',
      severity: 5,
      confidence: 5,
      report_type: 1,
      uuid: SecureRandom.uuid,
      created_at: 4.days.ago,
      metadata_version: 'something',
      raw_metadata: {}
    )
  end

  let!(:vulnerability_without_detected_at) do
    vulnerabilities_table.create!(
      project_id: project.id,
      author_id: 1,
      title: 'Test vulnerability 1',
      severity: 5,
      confidence: 5,
      report_type: 1,
      state: 1,
      finding_id: finding1.id,
      created_at: 2.days.ago
    )
  end

  let!(:vulnerability_with_detected_at) do
    vulnerabilities_table.create!(
      project_id: project.id,
      author_id: 1,
      title: 'Test vulnerability 2',
      severity: 5,
      confidence: 5,
      report_type: 1,
      state: 1,
      finding_id: finding2.id,
      created_at: 4.days.ago,
      detected_at: 3.days.ago
    )
  end

  before do
    # detected_at default value is NOW(), so update it to NULL
    vulnerability_without_detected_at.update_column :detected_at, nil
  end

  describe '#perform' do
    it 'backfills detected_at with created_at for vulnerabilities with nil detected_at' do
      expect(vulnerabilities_table.where(detected_at: nil).count).to eq 1

      migration.perform

      expect(vulnerabilities_table.where(detected_at: nil).count).to eq 0
    end

    it 'does not modify vulnerabilities that already have detected_at' do
      expect { migration.perform }.not_to change {
        vulnerabilities_table.find(vulnerability_with_detected_at.id).detected_at
      }
    end
  end
end
