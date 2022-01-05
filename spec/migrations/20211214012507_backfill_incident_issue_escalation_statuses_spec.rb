# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillIncidentIssueEscalationStatuses do
  let(:namespaces)  { table(:namespaces) }
  let(:projects)    { table(:projects) }
  let(:issues)      { table(:issues) }
  let(:namespace)   { namespaces.create!(name: 'foo', path: 'foo') }
  let(:project)     { projects.create!(namespace_id: namespace.id) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it 'schedules jobs for incident issues' do
    issue_1 = issues.create!(project_id: project.id) # non-incident issue
    incident_1 = issues.create!(project_id: project.id, issue_type: 1)
    incident_2 = issues.create!(project_id: project.id, issue_type: 1)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          2.minutes, issue_1.id, issue_1.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          4.minutes, incident_1.id, incident_1.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          6.minutes, incident_2.id, incident_2.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(3)
      end
    end
  end
end
