# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200915044225_schedule_migration_to_hashed_storage.rb')

RSpec.describe ScheduleMigrationToHashedStorage, :sidekiq do
  describe '#up' do
    it 'schedules background migration job' do
      Sidekiq::Testing.fake! do
        expect { migrate! }.to change { BackgroundMigrationWorker.jobs.size }.by(1)
      end
    end
  end
end
