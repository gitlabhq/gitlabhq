# frozen_string_literal: true
require 'spec_helper'
require_migration!('schedule_remove_duplicate_vulnerabilities_findings')

RSpec.describe ScheduleRemoveDuplicateVulnerabilitiesFindings, :migration do
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user) { create_user! }
  let(:project) { table(:projects).create!(id: 123, namespace_id: namespace.id) }
  let(:scanners) { table(:vulnerability_scanners) }
  let!(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let!(:scanner2) { scanners.create!(project_id: project.id, external_id: 'test 2', name: 'test scanner 2') }
  let!(:scanner3) { scanners.create!(project_id: project.id, external_id: 'test 3', name: 'test scanner 3') }
  let!(:unrelated_scanner) { scanners.create!(project_id: project.id, external_id: 'unreleated_scanner', name: 'unrelated scanner') }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerability_findings) { table(:vulnerability_occurrences) }
  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let(:vulnerability_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'vulnerability-identifier',
      external_id: 'vulnerability-identifier',
      fingerprint: '7e394d1b1eb461a7406d7b1e08f057a1cf11287a',
      name: 'vulnerability identifier')
  end

  let!(:first_finding) do
    create_finding!(
      uuid: "test1",
      vulnerability_id: nil,
      report_type: 0,
      location_fingerprint: '2bda3014914481791847d8eca38d1a8d13b6ad76',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner.id,
      project_id: project.id
    )
  end

  let!(:first_duplicate) do
    create_finding!(
      uuid: "test2",
      vulnerability_id: nil,
      report_type: 0,
      location_fingerprint: '2bda3014914481791847d8eca38d1a8d13b6ad76',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner2.id,
      project_id: project.id
    )
  end

  let!(:second_duplicate) do
    create_finding!(
      uuid: "test3",
      vulnerability_id: nil,
      report_type: 0,
      location_fingerprint: '2bda3014914481791847d8eca38d1a8d13b6ad76',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner3.id,
      project_id: project.id
    )
  end

  let!(:unrelated_finding) do
    create_finding!(
      uuid: "unreleated_finding",
      vulnerability_id: nil,
      report_type: 1,
      location_fingerprint: 'random_location_fingerprint',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: unrelated_scanner.id,
      project_id: project.id
    )
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules background migration' do
    migrate!

    expect(BackgroundMigrationWorker.jobs.size).to eq(4)
    expect(described_class::MIGRATION).to be_scheduled_migration(first_finding.id, first_finding.id)
    expect(described_class::MIGRATION).to be_scheduled_migration(first_duplicate.id, first_duplicate.id)
    expect(described_class::MIGRATION).to be_scheduled_migration(second_duplicate.id, second_duplicate.id)
    expect(described_class::MIGRATION).to be_scheduled_migration(unrelated_finding.id, unrelated_finding.id)
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
    vulnerability_findings.create!(
      vulnerability_id: vulnerability_id,
      project_id: project_id,
      name: name,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      project_fingerprint: project_fingerprint,
      scanner_id: scanner_id,
      primary_identifier_id: vulnerability_identifier.id,
      location_fingerprint: location_fingerprint,
      metadata_version: metadata_version,
      raw_metadata: raw_metadata,
      uuid: uuid
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil, created_at: Time.now, confirmed_at: Time.now)
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
