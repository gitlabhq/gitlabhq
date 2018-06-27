require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180122154930_schedule_set_confidential_note_events_on_services.rb')

describe ScheduleSetConfidentialNoteEventsOnServices, :migration, :sidekiq do
  let(:services_table) { table(:services) }
  let(:migration_class) { Gitlab::BackgroundMigration::SetConfidentialNoteEventsOnServices }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let!(:service_1)        { services_table.create!(confidential_note_events: nil, note_events: true) }
  let!(:service_2)        { services_table.create!(confidential_note_events: nil, note_events: true) }
  let!(:service_migrated) { services_table.create!(confidential_note_events: true, note_events: true) }
  let!(:service_skip)     { services_table.create!(confidential_note_events: nil, note_events: false) }
  let!(:service_new)      { services_table.create!(confidential_note_events: false, note_events: true) }
  let!(:service_4)        { services_table.create!(confidential_note_events: nil, note_events: true) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  it 'schedules background migrations at correct time' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(20.minutes, service_1.id, service_1.id)
        expect(migration_name).to be_scheduled_delayed_migration(40.minutes, service_2.id, service_2.id)
        expect(migration_name).to be_scheduled_delayed_migration(60.minutes, service_4.id, service_4.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'correctly processes services' do
    Sidekiq::Testing.inline! do
      expect(services_table.where(confidential_note_events: nil).count).to eq 4
      expect(services_table.where(confidential_note_events: true).count).to eq 1

      migrate!

      expect(services_table.where(confidential_note_events: nil).count).to eq 1
      expect(services_table.where(confidential_note_events: true).count).to eq 4
    end
  end
end
