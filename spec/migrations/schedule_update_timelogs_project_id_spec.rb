# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleUpdateTimelogsProjectId do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:issue) { table(:issues).create!(project_id: project.id) }
  let!(:merge_request) { table(:merge_requests).create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature') }
  let!(:timelog1) { table(:timelogs).create!(issue_id: issue.id, time_spent: 60) }
  let!(:timelog2) { table(:timelogs).create!(merge_request_id: merge_request.id, time_spent: 600) }
  let!(:timelog3) { table(:timelogs).create!(merge_request_id: merge_request.id, time_spent: 60) }
  let!(:timelog4) { table(:timelogs).create!(issue_id: issue.id, time_spent: 600) }

  it 'correctly schedules background migrations' do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(2.minutes, timelog1.id, timelog2.id)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(4.minutes, timelog3.id, timelog4.id)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
