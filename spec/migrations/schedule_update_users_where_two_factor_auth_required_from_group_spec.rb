# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleUpdateUsersWhereTwoFactorAuthRequiredFromGroup do
  let(:users) { table(:users) }
  let!(:user_1) { users.create!(require_two_factor_authentication_from_group: false, name: "user1", email: "user1@example.com", projects_limit: 1) }
  let!(:user_2) { users.create!(require_two_factor_authentication_from_group: true, name: "user2", email: "user2@example.com", projects_limit: 1) }
  let!(:user_3) { users.create!(require_two_factor_authentication_from_group: false, name: "user3", email: "user3@example.com", projects_limit: 1) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it 'schedules jobs for users that do not require two factor authentication' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          2.minutes, user_1.id, user_1.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          4.minutes, user_3.id, user_3.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
