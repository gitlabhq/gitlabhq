# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleMergeTopicsWithSameName, feature_category: :projects do
  let(:topics) { table(:topics) }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      topics.create!(name: 'topic1')
      topics.create!(name: 'Topic2')
      topics.create!(name: 'Topic3')
      topics.create!(name: 'Topic4')
      topics.create!(name: 'topic2')
      topics.create!(name: 'topic3')
      topics.create!(name: 'topic4')
      topics.create!(name: 'TOPIC2')
      topics.create!(name: 'topic5')
    end

    it 'schedules MergeTopicsWithSameName background jobs', :aggregate_failures do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, %w[topic2 topic3])
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, %w[topic4])
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
