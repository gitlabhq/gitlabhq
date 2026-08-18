# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::PendingMigrationsCheck, feature_category: :database do
  let(:regular_migration) do
    instance_double(
      ActiveRecord::MigrationProxy,
      version: 1,
      name: 'regular_migration',
      filename: 'db/migrate/1_regular_migration.rb'
    )
  end

  let(:post_deployment_migration) do
    instance_double(
      ActiveRecord::MigrationProxy,
      version: 2,
      name: 'post_deployment_migration',
      filename: 'db/post_migrate/2_post_deployment_migration.rb'
    )
  end

  describe '#check!' do
    subject(:check!) { described_class.check! }

    context 'when there are no pending migrations' do
      it 'does not raise' do
        expect { check! }.not_to raise_error
      end
    end

    context 'with pending migrations' do
      let(:open_migrations) { [] }

      before do
        migrator = instance_double(ActiveRecord::Migrator, pending_migrations: open_migrations)
        migration_context = instance_double(ActiveRecord::MigrationContext, open: migrator)
        pool = instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool, migration_context: migration_context)

        allow(ActiveRecord::PendingMigrationConnection)
          .to receive(:with_temporary_pool)
          .and_yield(pool)
      end

      context 'when only post-deployment migrations are pending' do
        let(:open_migrations) { [post_deployment_migration] }

        it 'does not raise' do
          expect { check! }.not_to raise_error
        end
      end

      context 'when regular migrations are pending' do
        let(:open_migrations) { [regular_migration] }

        it 'raises PendingMigrationError' do
          expect { check! }.to raise_error(ActiveRecord::PendingMigrationError)
        end
      end

      context 'when both regular and post-deployment migrations are pending' do
        let(:open_migrations) { [regular_migration, post_deployment_migration] }

        it 'raises PendingMigrationError' do
          expect { check! }.to raise_error(ActiveRecord::PendingMigrationError)
        end
      end
    end
  end
end
