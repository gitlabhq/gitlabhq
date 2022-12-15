# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateTopicsTotalProjectsCountCache, feature_category: :projects do
  let(:topics) { table(:topics) }
  let!(:topic_1) { topics.create!(name: 'Topic1') }
  let!(:topic_2) { topics.create!(name: 'Topic2') }
  let!(:topic_3) { topics.create!(name: 'Topic3') }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
    end

    it 'schedules BackfillProjectsWithCoverage background jobs', :aggregate_failures do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, topic_1.id, topic_2.id)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, topic_3.id, topic_3.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
