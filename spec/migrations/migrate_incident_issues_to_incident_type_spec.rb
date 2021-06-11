# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateIncidentIssuesToIncidentType do
  let(:migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:labels) { table(:labels) }
  let(:issues) { table(:issues) }
  let(:label_links) { table(:label_links) }
  let(:label_props) { IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let(:label) { labels.create!(project_id: project.id, **label_props) }
  let!(:incident_issue) { issues.create!(project_id: project.id) }
  let!(:other_issue) { issues.create!(project_id: project.id) }

  # Issue issue_type enum
  let(:issue_type) { 0 }
  let(:incident_type) { 1 }

  before do
    label_links.create!(target_id: incident_issue.id, label_id: label.id, target_type: 'Issue')
  end

  describe '#up' do
    it 'updates the incident issue type' do
      expect { migrate! }
        .to change { incident_issue.reload.issue_type }
        .from(issue_type)
        .to(incident_type)

      expect(other_issue.reload.issue_type).to eql(issue_type)
    end
  end

  describe '#down' do
    let!(:incident_issue) { issues.create!(project_id: project.id, issue_type: issue_type) }

    it 'updates the incident issue type' do
      migration.up

      expect { migration.down }
        .to change { incident_issue.reload.issue_type }
        .from(incident_type)
        .to(issue_type)

      expect(other_issue.reload.issue_type).to eql(issue_type)
    end
  end
end
