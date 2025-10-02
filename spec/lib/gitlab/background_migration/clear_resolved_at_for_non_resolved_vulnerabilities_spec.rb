# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ClearResolvedAtForNonResolvedVulnerabilities,
  feature_category: :vulnerability_management do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user', organization_id: organization.id) }
  let(:user) do
    table(:users).create!(name: 'user', email: 'user@example.com', username: 'user', projects_limit: 10,
      organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:vulnerabilities) { table(:vulnerabilities, database: :sec) }
  let(:scanners) { table(:vulnerability_scanners, database: :sec) }
  let(:identifiers) { table(:vulnerability_identifiers, database: :sec) }
  let(:findings) { table(:vulnerability_occurrences, database: :sec) }

  let(:scanner) do
    scanners.create!(
      project_id: project.id,
      external_id: 'test_scanner',
      name: 'test_scanner'
    )
  end

  let(:identifier) do
    identifiers.create!(
      project_id: project.id,
      fingerprint: 'test-identifier',
      external_type: 'test_type',
      external_id: 'test_id',
      name: 'test_name'
    )
  end

  # Vulnerability states
  let(:detected_state) { 1 }
  let(:resolved_state) { 3 }

  let(:resolved_at_time) { Time.zone.now }

  let!(:detected_with_resolved_at) do
    create_vulnerability(
      title: 'test',
      state: detected_state,
      resolved_at: resolved_at_time,
      resolved_by_id: user.id
    )
  end

  let!(:resolved_with_resolved_at) do
    create_vulnerability(
      title: 'test2',
      state: resolved_state,
      resolved_at: resolved_at_time,
      resolved_by_id: user.id
    )
  end

  let!(:detected_without_resolved_at) do
    create_vulnerability(
      title: 'test3',
      state: detected_state,
      resolved_at: nil
    )
  end

  let!(:detected_with_incomplete_resolution) do
    create_vulnerability(
      title: 'test4',
      state: detected_state,
      resolved_at: resolved_at_time,
      resolved_by_id: nil
    )
  end

  let!(:detected_with_only_resolved_by) do
    create_vulnerability(
      title: 'test5',
      state: detected_state,
      resolved_at: nil,
      resolved_by_id: user.id
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: detected_with_resolved_at.id,
      end_id: detected_with_only_resolved_by.id,
      batch_table: :vulnerabilities,
      batch_column: :id,
      sub_batch_size: 5,
      pause_ms: 0,
      connection: SecApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'clears resolved_at and resolved_by_id for non-resolved vulnerabilities that have both fields set' do
      expect { migration.perform }
        .to change { detected_with_resolved_at.reload.resolved_at }.from(be_present).to(nil)
        .and change { detected_with_resolved_at.resolved_by_id }.from(user.id).to(nil)
    end

    it 'does not change resolved_at for resolved vulnerabilities' do
      expect { migration.perform }.not_to change { resolved_with_resolved_at.reload.resolved_at }
    end

    it 'does not change vulnerabilities that already have resolved_at as nil' do
      expect { migration.perform }.not_to change { detected_without_resolved_at.reload.resolved_at }
    end

    it 'clears resolved_at for vulnerabilities with incomplete resolution data' do
      expect { migration.perform }
        .to change { detected_with_incomplete_resolution.reload.resolved_at }.from(be_present).to(nil)
        .and not_change { detected_with_incomplete_resolution.reload.resolved_by_id }
    end

    it 'clears resolved_by_id for vulnerabilities that only have resolved_by_id set' do
      expect { migration.perform }
        .to not_change { detected_with_only_resolved_by.reload.resolved_at }
        .and change { detected_with_only_resolved_by.reload.resolved_by_id }.from(user.id).to(nil)
    end
  end

  private

  def create_vulnerability(overrides = {})
    finding = create_finding
    vulnerabilities.create!({
      project_id: project.id,
      author_id: user.id,
      finding_id: finding.id,
      severity: 1,
      report_type: 1
    }.merge(overrides))
  end

  def create_finding
    findings.create!(
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: identifier.id,
      location_fingerprint: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      name: 'test',
      raw_metadata: '{}',
      metadata_version: 'test:1.0',
      severity: 1,
      report_type: 1
    )
  end
end
