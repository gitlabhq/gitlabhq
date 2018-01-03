require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171221154744_schedule_epic_issue_positions_migration.rb')

describe ScheduleEpicIssuePositionsMigration, :migration, :sidekiq do
  let(:groups) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:epics) { table(:epics) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    group = groups.create(name: 'group', path: 'group')
    user = users.create(username: 'User')
    epics.create(id: 1, title: 'Epic 1', title_html: 'Epic 1', group_id: group.id, author_id: user.id, iid: 1)
    epics.create(id: 2, title: 'Epic 2', title_html: 'Epic 2', group_id: group.id, author_id: user.id, iid: 2)
    epics.create(id: 3, title: 'Epic 3', title_html: 'Epic 3', group_id: group.id, author_id: user.id, iid: 3)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, 1, 2)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, 3, 3)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
