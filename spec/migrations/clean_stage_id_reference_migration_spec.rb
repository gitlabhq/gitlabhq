require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170710083355_clean_stage_id_reference_migration.rb')
require Rails.root.join('db', 'post_migrate', '20170628080858_migrate_stage_id_reference_in_background')

describe CleanStageIdReferenceMigration, :migration, :sidekiq, :redis do
  let(:migration) { MigrateStageIdReferenceInBackground::MIGRATION }

  context 'when there are pending background migrations' do
    it 'processes pending jobs synchronously' do
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker.perform_in(2.minutes, migration, [1])
        BackgroundMigrationWorker.perform_async(migration, [1])

        expect(Gitlab::BackgroundMigration).to receive(:perform).twice

        migrate!
      end
    end
  end

  context 'when there are no background migrations pending' do
    it 'does nothing' do
      Sidekiq::Testing.disable! do
        expect(Gitlab::BackgroundMigration).not_to receive(:perform)

        migrate!
      end
    end
  end
end
