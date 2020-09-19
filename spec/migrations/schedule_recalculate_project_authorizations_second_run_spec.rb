# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200204113224_schedule_recalculate_project_authorizations_second_run.rb')

RSpec.describe ScheduleRecalculateProjectAuthorizationsSecondRun do
  let(:users_table) { table(:users) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    1.upto(4) do |i|
      users_table.create!(id: i, name: "user#{i}", email: "user#{i}@example.com", projects_limit: 1)
    end
  end

  it 'schedules background migration' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(described_class::MIGRATION).to be_scheduled_migration(1, 2)
        expect(described_class::MIGRATION).to be_scheduled_migration(3, 4)
      end
    end
  end
end
