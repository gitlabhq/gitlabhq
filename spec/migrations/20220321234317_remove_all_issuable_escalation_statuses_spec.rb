# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveAllIssuableEscalationStatuses, feature_category: :incident_management do
  let(:namespaces)  { table(:namespaces) }
  let(:projects)    { table(:projects) }
  let(:issues)      { table(:issues) }
  let(:statuses)    { table(:incident_management_issuable_escalation_statuses) }
  let(:namespace)   { namespaces.create!(name: 'foo', path: 'foo') }
  let(:project)     { projects.create!(namespace_id: namespace.id) }

  it 'removes all escalation status records' do
    issue = issues.create!(project_id: project.id, issue_type: 1)
    statuses.create!(issue_id: issue.id)

    expect { migrate! }.to change(statuses, :count).from(1).to(0)
  end
end
