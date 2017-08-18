require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170710083355_clean_stage_id_reference_migration.rb')

describe CleanStageIdReferenceMigration, :migration, :sidekiq, :redis do
  let(:migration_class) { 'MigrateBuildStageIdReference' }
  let(:migration) { spy('migration') }

  before do
    allow(Gitlab::BackgroundMigration.const_get(migration_class))
      .to receive(:new).and_return(migration)
  end

  context 'when there are pending background migrations' do
    it 'processes pending jobs synchronously' do
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker.perform_in(2.minutes, migration_class, [1, 1])
        BackgroundMigrationWorker.perform_async(migration_class, [1, 1])

        migrate!

        expect(migration).to have_received(:perform).with(1, 1).twice
      end
    end
  end
  context 'when there are no background migrations pending' do
    it 'does nothing' do
      Sidekiq::Testing.disable! do
        migrate!

        expect(migration).not_to have_received(:perform)
      end
    end
  end
end
