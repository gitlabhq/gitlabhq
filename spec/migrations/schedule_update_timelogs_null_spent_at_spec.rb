# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleUpdateTimelogsNullSpentAt, feature_category: :team_planning do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:issue) { table(:issues).create!(project_id: project.id) }
  let!(:merge_request) { table(:merge_requests).create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature') }
  let!(:timelog1) { create_timelog!(merge_request_id: merge_request.id) }
  let!(:timelog2) { create_timelog!(merge_request_id: merge_request.id) }
  let!(:timelog3) { create_timelog!(merge_request_id: merge_request.id) }
  let!(:timelog4) { create_timelog!(issue_id: issue.id) }
  let!(:timelog5) { create_timelog!(issue_id: issue.id) }

  before do
    table(:timelogs).where.not(id: timelog3.id).update_all(spent_at: nil)
  end

  it 'correctly schedules background migrations' do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(2.minutes, timelog1.id, timelog2.id)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(4.minutes, timelog4.id, timelog5.id)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end

  private

  def create_timelog!(**args)
    table(:timelogs).create!(**args, time_spent: 1)
  end
end
