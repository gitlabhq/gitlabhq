# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillIncidentIssueEscalationStatuses, feature_category: :incident_management do
  let(:namespaces)  { table(:namespaces) }
  let(:projects)    { table(:projects) }
  let(:issues)      { table(:issues) }
  let(:namespace)   { namespaces.create!(name: 'foo', path: 'foo') }
  let(:project)     { projects.create!(namespace_id: namespace.id) }

  # Backfill removed - see db/migrate/20220321234317_remove_all_issuable_escalation_statuses.rb.
  it 'does nothing' do
    issues.create!(project_id: project.id, issue_type: 1)

    expect { migrate! }.not_to change { BackgroundMigrationWorker.jobs.size }
  end
end
