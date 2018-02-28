require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171103140253_track_untracked_uploads')

describe TrackUntrackedUploads, :migration, :sidekiq do
  include TrackUntrackedUploadsHelpers

  matcher :be_scheduled_migration do
    match do |migration|
      BackgroundMigrationWorker.jobs.any? do |job|
        job['args'] == [migration]
      end
    end

    failure_message do |migration|
      "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
    end
  end

  it 'correctly schedules the follow-up background migration' do
    Sidekiq::Testing.fake! do
      migrate!

      expect(described_class::MIGRATION).to be_scheduled_migration
      expect(BackgroundMigrationWorker.jobs.size).to eq(1)
    end
  end
end
