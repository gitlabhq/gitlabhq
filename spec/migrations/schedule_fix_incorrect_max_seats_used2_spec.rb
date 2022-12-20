# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleFixIncorrectMaxSeatsUsed2, :migration, feature_category: :purchase do
  let(:migration_name) { described_class::MIGRATION.to_s.demodulize }

  describe '#up' do
    it 'schedules a job on Gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(migration_name).to be_scheduled_delayed_migration(1.hour, 'batch_2_for_start_date_before_02_aug_2021')
          expect(BackgroundMigrationWorker.jobs.size).to eq(1)
        end
      end
    end

    it 'does not schedule any jobs when not Gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(false)

      Sidekiq::Testing.fake! do
        migrate!

        expect(migration_name).not_to be_scheduled_delayed_migration
        expect(BackgroundMigrationWorker.jobs.size).to eq(0)
      end
    end
  end
end
