# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::MigrateToHashedStorage, :sidekiq, :redis do
  let(:migrator) { Gitlab::HashedStorage::Migrator.new }

  subject(:background_migration) { described_class.new }

  describe '#perform' do
    let!(:project) { create(:project, :empty_repo, :legacy_storage) }

    context 'with pending rollback' do
      it 'aborts rollback operation' do
        Sidekiq::Testing.disable! do
          Sidekiq::Client.push(
            'queue' => ::HashedStorage::ProjectRollbackWorker.queue,
            'class' => ::HashedStorage::ProjectRollbackWorker,
            'args' => [project.id]
          )

          expect { background_migration.perform }.to change { migrator.rollback_pending? }.from(true).to(false)
        end
      end
    end

    it 'enqueues legacy projects to be migrated' do
      Sidekiq::Testing.fake! do
        expect { background_migration.perform }.to change { Sidekiq::Queues[::HashedStorage::MigratorWorker.queue].size }.by(1)
      end
    end

    context 'when executing all jobs' do
      it 'migrates legacy projects' do
        Sidekiq::Testing.inline! do
          expect { background_migration.perform }.to change { project.reload.legacy_storage? }.from(true).to(false)
        end
      end
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
