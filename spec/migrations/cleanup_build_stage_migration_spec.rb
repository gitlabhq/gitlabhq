require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180420010616_cleanup_build_stage_migration.rb')

describe CleanupBuildStageMigration, :migration, :sidekiq, :redis do
  let(:migration) { spy('migration') }

  before do
    allow(Gitlab::BackgroundMigration::MigrateBuildStage)
      .to receive(:new).and_return(migration)
  end

  context 'when there are pending background migrations' do
    it 'processes pending jobs synchronously' do
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker
          .perform_in(2.minutes, 'MigrateBuildStage', [1, 1])
        BackgroundMigrationWorker
          .perform_async('MigrateBuildStage', [1, 1])

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

  context 'when there are still unmigrated builds present' do
    let(:builds) { table('ci_builds') }

    before do
      builds.create!(name: 'test:1', ref: 'master')
      builds.create!(name: 'test:2', ref: 'master')
    end

    it 'migrates stages sequentially in batches' do
      expect(builds.all).to all(have_attributes(stage_id: nil))

      migrate!

      expect(migration).to have_received(:perform).once
    end
  end
end
