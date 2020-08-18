# frozen_string_literal: true
require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200811130433_create_missing_vulnerabilities_issue_links.rb')

RSpec.describe CreateMissingVulnerabilitiesIssueLinks, :migration do
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user) { create_user! }
  let(:project) { table(:projects).create!(id: 123, namespace_id: namespace.id) }
  let(:scanner) { table(:vulnerability_scanners).create!(project_id: project.id, external_id: 'test', name: 'test scanner') }
  let(:issue) { table(:issues).create!(id: 123, project_id: project.id) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerabilities_findings) { table(:vulnerability_occurrences) }
  let(:vulnerability_feedback) { table(:vulnerability_feedback) }
  let(:vulnerability_issue_links) { table(:vulnerability_issue_links) }
  let(:vulnerability_identifier) { table(:vulnerability_identifiers).create!(project_id: project.id, external_type: 'test', external_id: 'test', fingerprint: 'test', name: 'test') }

  let!(:vulnerability) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  before do
    create_finding!(
      vulnerability_id: vulnerability.id,
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: vulnerability_identifier.id
    )
    create_feedback!(
      issue_id: issue.id,
      project_id: project.id,
      author_id: user.id
    )
  end

  context 'with no Vulnerabilities::IssueLinks present' do
    it 'creates missing Vulnerabilities::IssueLinks' do
      expect(vulnerability_issue_links.count).to eq(0)

      migrate!

      expect(vulnerability_issue_links.count).to eq(1)
    end
  end

  context 'when an Vulnerabilities::IssueLink already exists' do
    before do
      vulnerability_issue_links.create!(vulnerability_id: vulnerability.id, issue_id: issue.id)
    end

    it 'creates no duplicates' do
      expect(vulnerability_issue_links.count).to eq(1)

      migrate!

      expect(vulnerability_issue_links.count).to eq(1)
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

  # project_fingerprint on Vulnerabilities::Finding is a bytea and we need to match this
  def create_feedback!(issue_id:, project_id:, author_id:, feedback_type: 1, category: 0, project_fingerprint: '3132337177656173647a7863')
    vulnerability_feedback.create!(
      feedback_type: feedback_type,
      issue_id: issue.id,
      category: category,
      project_fingerprint: project_fingerprint,
      project_id: project_id,
      author_id: author_id
    )
  end

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
