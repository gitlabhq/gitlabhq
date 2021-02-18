# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateIssueEmailParticipants, schema: 20201128210234 do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(id: 1, namespace_id: namespace.id) }
  let!(:issue1) { table(:issues).create!(id: 1, project_id: project.id, service_desk_reply_to: "a@gitlab.com") }
  let!(:issue2) { table(:issues).create!(id: 2, project_id: project.id, service_desk_reply_to: "b@gitlab.com") }
  let(:issue_email_participants) { table(:issue_email_participants) }

  describe '#perform' do
    it 'migrates email addresses from service desk issues', :aggregate_failures do
      expect { subject.perform(1, 2) }.to change { issue_email_participants.count }.by(2)

      expect(issue_email_participants.find_by(issue_id: 1).email).to eq("a@gitlab.com")
      expect(issue_email_participants.find_by(issue_id: 2).email).to eq("b@gitlab.com")
    end
  end
end
