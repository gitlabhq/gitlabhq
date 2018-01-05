require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171128214150_schedule_populate_merge_request_metrics_with_events_data.rb')

describe SchedulePopulateMergeRequestMetricsWithEventsData, :migration, :sidekiq do
  let!(:mrs) { create_list(:merge_request, 3) }

  it 'correctly schedules background migrations' do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(10.minutes, mrs.first.id, mrs.second.id)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(20.minutes, mrs.third.id, mrs.third.id)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
