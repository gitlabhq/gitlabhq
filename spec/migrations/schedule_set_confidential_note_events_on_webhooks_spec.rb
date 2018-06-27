require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180104131052_schedule_set_confidential_note_events_on_webhooks.rb')

describe ScheduleSetConfidentialNoteEventsOnWebhooks, :migration, :sidekiq do
  let(:web_hooks_table) { table(:web_hooks) }
  let(:migration_class) { Gitlab::BackgroundMigration::SetConfidentialNoteEventsOnWebhooks }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let!(:web_hook_1)        { web_hooks_table.create!(confidential_note_events: nil, note_events: true) }
  let!(:web_hook_2)        { web_hooks_table.create!(confidential_note_events: nil, note_events: true) }
  let!(:web_hook_migrated) { web_hooks_table.create!(confidential_note_events: true, note_events: true) }
  let!(:web_hook_skip)     { web_hooks_table.create!(confidential_note_events: nil, note_events: false) }
  let!(:web_hook_new)      { web_hooks_table.create!(confidential_note_events: false, note_events: true) }
  let!(:web_hook_4)        { web_hooks_table.create!(confidential_note_events: nil, note_events: true) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  it 'schedules background migrations at correct time' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(5.minutes, web_hook_1.id, web_hook_1.id)
        expect(migration_name).to be_scheduled_delayed_migration(10.minutes, web_hook_2.id, web_hook_2.id)
        expect(migration_name).to be_scheduled_delayed_migration(15.minutes, web_hook_4.id, web_hook_4.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'correctly processes web hooks' do
    Sidekiq::Testing.inline! do
      expect(web_hooks_table.where(confidential_note_events: nil).count).to eq 4
      expect(web_hooks_table.where(confidential_note_events: true).count).to eq 1

      migrate!

      expect(web_hooks_table.where(confidential_note_events: nil).count).to eq 1
      expect(web_hooks_table.where(confidential_note_events: true).count).to eq 4
    end
  end
end
