# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillHasIssuesForExternalIssueLinks, feature_category: :vulnerability_management do
  before(:all) do
    # This migration will not work if a sec database is configured. It should be finalized and removed prior to
    # sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171707 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  let(:users) { table(:users) }
  let(:user) { create_user(email: "test1@example.com", username: "test1") }

  let(:organizations) { table(:organizations) }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:namespaces) { table(:namespaces) }
  let(:namespace) do
    namespaces.create!(name: 'test-1', path: 'test-1', owner_id: user.id, organization_id: organization.id)
  end

  let(:projects) { table(:projects) }
  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:members) { table(:members) }
  let!(:membership) do
    members.create!(access_level: 50, source_id: project.id, source_type: "Project", user_id: user.id, state: 0,
      notification_level: 3, type: "ProjectMember", member_namespace_id: namespace.id)
  end

  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }

  let(:vulnerability_scanners) { table(:vulnerability_scanners) }
  let(:scanner) { create_scanner(project_id: project.id) }

  let(:vulnerability_findings) { table(:vulnerability_occurrences) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerability_reads) { table(:vulnerability_reads) }
  let(:vulnerability_external_issue_links) { table(:vulnerability_external_issue_links) }

  let(:vulnerability) do
    create_full_vulnerability(project)
  end

  let(:vulnerability_read) do
    vulnerability_reads.find_by(vulnerability_id: vulnerability.id)
  end

  let!(:external_issue_link) do
    vulnerability_external_issue_links.create!(
      author_id: user.id,
      vulnerability_id: vulnerability.id,
      external_project_key: "TEST",
      external_issue_key: "123"
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: vulnerability_reads.first.vulnerability_id,
      end_id: vulnerability_reads.last.vulnerability_id,
      batch_table: :vulnerability_reads,
      batch_column: :vulnerability_id,
      sub_batch_size: vulnerability_reads.count,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'sets has_issues of an existing record' do
    expect { perform_migration }.to change { vulnerability_read.reload.has_issues }.from(false).to(true)
  end

  context 'when there exists a record with has_issues' do
    let(:vulnerability_2) do
      create_full_vulnerability(project, read_overrides: { has_issues: true })
    end

    let(:vulnerability_read_2) { vulnerability_reads.find_by(vulnerability_id: vulnerability_2.id) }

    it 'does not modify existing records with has_issues' do
      expect { perform_migration }.not_to change { vulnerability_read_2.reload.has_merge_request }.from(false)
    end
  end

  private

  def create_full_vulnerability(project, finding_overrides: {}, vulnerability_overrides: {}, read_overrides: {})
    finding = create_finding(project, finding_overrides)
    vulnerability = create_vulnerability(vulnerability_overrides.merge(finding_id: finding.id))
    create_vulnerability_read(vulnerability, finding, read_overrides)

    vulnerability
  end

  def create_scanner(project, overrides = {})
    random_scanner_uuid = SecureRandom.uuid

    attrs = {
      project_id: project.id,
      external_id: "test_vulnerability_scanner-#{random_scanner_uuid})",
      name: "Test Vulnerabilities::Scanner #{random_scanner_uuid}"
    }.merge(overrides)

    vulnerability_scanners.create!(attrs)
  end

  def create_identifier(project, overrides = {})
    attrs = {
      project_id: project.id,
      external_id: "CVE-2018-1234",
      external_type: "CVE",
      name: "CVE-2018-1234",
      fingerprint: SecureRandom.hex(20)
    }.merge(overrides)

    vulnerability_identifiers.create!(attrs)
  end

  def create_finding(project, overrides = {})
    attrs = {
      project_id: project.id,
      scanner_id: create_scanner(project).id,
      severity: 5, # medium
      report_type: 99, # generic
      primary_identifier_id: create_identifier(project).id,
      project_fingerprint: SecureRandom.hex(20),
      location_fingerprint: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      name: "CVE-2018-1234",
      raw_metadata: "{}",
      metadata_version: "test:1.0"
    }.merge(overrides)

    vulnerability_findings.create!(attrs)
  end

  def create_vulnerability(overrides = {})
    attrs = {
      project_id: project.id,
      author_id: user.id,
      title: 'test',
      severity: 1,
      confidence: 1,
      report_type: 1,
      state: 1,
      detected_at: Time.zone.now
    }.merge(overrides)

    vulnerabilities.create!(attrs)
  end

  def create_vulnerability_read(vulnerability, finding, overrides = {})
    attrs = {
      project_id: vulnerability.project_id,
      vulnerability_id: vulnerability.id,
      scanner_id: finding.scanner_id,
      severity: vulnerability.severity,
      report_type: vulnerability.report_type,
      state: vulnerability.state,
      uuid: finding.uuid
    }.merge(overrides)

    vulnerability_reads.create!(attrs)
  end

  def create_user(overrides = {})
    attrs = {
      email: "test@example.com",
      notification_email: "test@example.com",
      name: "test",
      username: "test",
      state: "active",
      projects_limit: 10
    }.merge(overrides)

    users.create!(attrs)
  end
end
