# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateIssueEmailParticipants do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(id: 1, namespace_id: namespace.id) }
  let!(:issue1) { table(:issues).create!(id: 1, project_id: project.id, service_desk_reply_to: "a@gitlab.com") }
  let!(:issue2) { table(:issues).create!(id: 2, project_id: project.id) }
  let!(:issue3) { table(:issues).create!(id: 3, project_id: project.id, service_desk_reply_to: "b@gitlab.com") }
  let!(:issue4) { table(:issues).create!(id: 4, project_id: project.id, service_desk_reply_to: "c@gitlab.com") }
  let!(:issue5) { table(:issues).create!(id: 5, project_id: project.id, service_desk_reply_to: "d@gitlab.com") }
  let(:issue_email_participants) { table(:issue_email_participants) }

  it 'correctly schedules background migrations' do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(2.minutes, 1, 3)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(4.minutes, 4, 5)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
