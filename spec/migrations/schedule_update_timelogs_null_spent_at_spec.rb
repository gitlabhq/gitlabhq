# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleUpdateTimelogsNullSpentAt do
  let_it_be(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let_it_be(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let_it_be(:issue) { table(:issues).create!(project_id: project.id) }
  let_it_be(:merge_request) { table(:merge_requests).create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature') }
  let_it_be(:timelog1) { create_timelog!(merge_request_id: merge_request.id) }
  let_it_be(:timelog2) { create_timelog!(merge_request_id: merge_request.id) }
  let_it_be(:timelog3) { create_timelog!(merge_request_id: merge_request.id) }
  let_it_be(:timelog4) { create_timelog!(issue_id: issue.id) }
  let_it_be(:timelog5) { create_timelog!(issue_id: issue.id) }

  before_all do
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
