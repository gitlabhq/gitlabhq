require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171005130944_schedule_create_gpg_key_subkeys_from_gpg_keys')

describe ScheduleCreateGpgKeySubkeysFromGpgKeys, :migration, :sidekiq do
  before do
    create(:gpg_key, id: 1, key: GpgHelpers::User1.public_key)
    create(:gpg_key, id: 2, key: GpgHelpers::User3.public_key)
    # Delete all subkeys so they can be recreated
    GpgKeySubkey.destroy_all
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      migrate!

      expect(described_class::MIGRATION).to be_scheduled_migration(1)
      expect(described_class::MIGRATION).to be_scheduled_migration(2)
      expect(BackgroundMigrationWorker.jobs.size).to eq(2)
    end
  end

  it 'schedules background migrations' do
    Sidekiq::Testing.inline! do
      expect(GpgKeySubkey.count).to eq(0)

      migrate!

      expect(GpgKeySubkey.count).to eq(3)
    end
  end
end
