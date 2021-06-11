# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateUserHighestRolesTable do
  let(:users) { table(:users) }

  def create_user(id, params = {})
    user_params = {
      id: id,
      state: 'active',
      user_type: nil,
      bot_type: nil,
      ghost: nil,
      email: "user#{id}@example.com",
      projects_limit: 0
    }.merge(params)

    users.create!(user_params)
  end

  it 'correctly schedules background migrations' do
    create_user(1)
    create_user(2, state: 'blocked')
    create_user(3, user_type: 2)
    create_user(4)
    create_user(5, bot_type: 1)
    create_user(6, ghost: true)
    create_user(7, ghost: false)

    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, 1, 4)

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, 7, 7)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
