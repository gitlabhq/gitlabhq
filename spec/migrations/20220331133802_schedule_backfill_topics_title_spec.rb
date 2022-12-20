# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleBackfillTopicsTitle, feature_category: :projects do
  let(:topics) { table(:topics) }

  let!(:topic1) { topics.create!(name: 'topic1') }
  let!(:topic2) { topics.create!(name: 'topic2') }
  let!(:topic3) { topics.create!(name: 'topic3') }

  it 'correctly schedules background migrations', :aggregate_failures do
    stub_const("#{Gitlab::Database::Migrations::BackgroundMigrationHelpers}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, topic1.id, topic2.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, topic3.id, topic3.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
