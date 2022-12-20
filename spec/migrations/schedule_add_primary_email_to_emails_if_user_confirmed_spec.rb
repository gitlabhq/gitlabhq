# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleAddPrimaryEmailToEmailsIfUserConfirmed, :sidekiq, feature_category: :users do
  let(:migration) { described_class.new }
  let(:users) { table(:users) }

  let!(:user_1) { users.create!(name: 'confirmed-user-1', email: 'confirmed-1@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }
  let!(:user_2) { users.create!(name: 'confirmed-user-2', email: 'confirmed-2@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }
  let!(:user_3) { users.create!(name: 'confirmed-user-3', email: 'confirmed-3@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }
  let!(:user_4) { users.create!(name: 'confirmed-user-4', email: 'confirmed-4@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
    stub_const("#{described_class.name}::INTERVAL", 2.minutes.to_i)
  end

  it 'schedules addition of primary email to emails in delayed batches' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migration.up

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, user_1.id, user_2.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, user_3.id, user_4.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
