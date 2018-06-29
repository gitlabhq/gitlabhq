require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180604123514_cleanup_stages_position_migration.rb')

describe CleanupStagesPositionMigration, :migration, :sidekiq, :redis do
  let(:migration) { spy('migration') }

  before do
    allow(Gitlab::BackgroundMigration::MigrateStageIndex)
      .to receive(:new).and_return(migration)
  end

  context 'when there are pending background migrations' do
    it 'processes pending jobs synchronously' do
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker
          .perform_in(2.minutes, 'MigrateStageIndex', [1, 1])
        BackgroundMigrationWorker
          .perform_async('MigrateStageIndex', [1, 1])

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

  context 'when there are still unmigrated stages present' do
    let(:stages) { table('ci_stages') }
    let(:builds) { table('ci_builds') }

    let!(:entities) do
      %w[build test broken].map do |name|
        stages.create(name: name)
      end
    end

    before do
      stages.update_all(position: nil)

      builds.create(name: 'unit', stage_id: entities.first.id, stage_idx: 1, ref: 'master')
      builds.create(name: 'unit', stage_id: entities.second.id, stage_idx: 1, ref: 'master')
    end

    it 'migrates stages sequentially for every stage' do
      expect(stages.all).to all(have_attributes(position: nil))

      migrate!

      expect(migration).to have_received(:perform)
        .with(entities.first.id, entities.first.id)
      expect(migration).to have_received(:perform)
        .with(entities.second.id, entities.second.id)
      expect(migration).not_to have_received(:perform)
        .with(entities.third.id, entities.third.id)
    end
  end
end
