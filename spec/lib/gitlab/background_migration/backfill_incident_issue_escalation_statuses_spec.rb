# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIncidentIssueEscalationStatuses, schema: 20211214012507 do
  let(:namespaces)                    { table(:namespaces) }
  let(:projects)                      { table(:projects) }
  let(:issues)                        { table(:issues) }
  let(:issuable_escalation_statuses)  { table(:incident_management_issuable_escalation_statuses) }

  subject(:migration) { described_class.new }

  it 'correctly backfills issuable escalation status records' do
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)

    issues.create!(project_id: project.id, title: 'issue 1', issue_type: 0)  # non-incident issue
    issues.create!(project_id: project.id, title: 'incident 1', issue_type: 1)
    issues.create!(project_id: project.id, title: 'incident 2', issue_type: 1)
    incident_issue_existing_status = issues.create!(project_id: project.id, title: 'incident 3', issue_type: 1)
    issuable_escalation_statuses.create!(issue_id: incident_issue_existing_status.id)

    migration.perform(1, incident_issue_existing_status.id)

    expect(issuable_escalation_statuses.count).to eq(3)
  end
end
