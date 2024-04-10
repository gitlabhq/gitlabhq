# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::MigrationSupport::MigrationContext,
  click_house: :without_migrations, feature_category: :database do
  include ClickHouseSchemaHelpers

  # We don't need to delete data since we don't modify Postgres data
  self.use_transactional_tests = false

  let(:connection) { ::ClickHouse::Connection.new(:main) }
  let(:schema_migration) { ClickHouse::MigrationSupport::SchemaMigration.new(connection) }

  let(:migrations_base_dir) { 'click_house/migrations' }
  let(:migrations_dir) { expand_fixture_path("#{migrations_base_dir}/#{migrations_dirname}") }
  let(:migration_context) { described_class.new(connection, migrations_dir, schema_migration) }
  let(:target_version) { nil }

  after do
    unload_click_house_migration_classes(expand_fixture_path(migrations_base_dir))
  end

  describe 'performs migrations' do
    include ExclusiveLeaseHelpers

    subject(:migration) { migrate(migration_context, target_version) }

    describe 'when creating a table' do
      let(:migrations_dirname) { 'plain_table_creation' }
      let(:lease_key) { 'click_house:migrations' }
      let(:lease_timeout) { 1.hour }

      it 'executes migration through ClickHouse::MigrationSupport::ExclusiveLock.execute_migration' do
        expect(ClickHouse::MigrationSupport::ExclusiveLock).to receive(:execute_migration)

        # Test that not running execute_migration will not execute migrations
        expect { migration }.not_to change { active_schema_migrations_count }
      end

      it 'creates a table' do
        expect(ClickHouse::MigrationSupport::ExclusiveLock).to receive(:execute_migration).and_call_original
        expect_to_obtain_exclusive_lease(lease_key, timeout: lease_timeout)

        expect { migration }.to change { active_schema_migrations_count }.from(0).to(1)

        table_schema = describe_table('some')
        expect(schema_migrations).to contain_exactly(a_hash_including(version: '1', active: 1))
        expect(table_schema).to match({
          id: a_hash_including(type: 'UInt64'),
          date: a_hash_including(type: 'Date')
        })
      end

      context 'when a migration is already running' do
        let(:migration_name) { 'create_some_table' }

        before do
          stub_exclusive_lease_taken(lease_key)
        end

        it 'raises error after timeout when migration is executing concurrently' do
          expect { migration }.to raise_error(ClickHouse::MigrationSupport::Errors::LockError)
            .and not_change { active_schema_migrations_count }
        end
      end
    end

    describe 'when dropping a table' do
      let(:migrations_dirname) { 'drop_table' }
      let(:target_version) { 2 }

      it 'drops table' do
        migrate(migration_context, 1)
        expect(table_names).to include('some')

        migration
        expect(table_names).not_to include('some')
      end
    end

    context 'when a migration raises an error' do
      let(:migrations_dirname) { 'migration_with_error' }

      it 'passes the error to caller as a StandardError' do
        expect { migration }.to raise_error StandardError,
          "An error has occurred, all later migrations canceled:\n\nA migration error happened"
        expect(schema_migrations).to be_empty
      end
    end

    context 'when connecting to not-existing database' do
      let(:migrations_dirname) { 'plain_table_creation' }
      let(:connection) { ::ClickHouse::Connection.new(:unknown_database) }

      it 'raises ConfigurationError' do
        expect { migration }.to raise_error ClickHouse::Client::ConfigurationError,
          "The database 'unknown_database' is not configured"
      end
    end

    context 'when target_version is incorrect' do
      let(:target_version) { 2 }
      let(:migrations_dirname) { 'plain_table_creation' }

      it 'raises UnknownMigrationVersionError' do
        expect { migration }.to raise_error ClickHouse::MigrationSupport::Errors::UnknownMigrationVersionError

        expect(active_schema_migrations_count).to eq 0
      end
    end

    context 'when migrations with duplicate name exist' do
      let(:migrations_dirname) { 'duplicate_name' }

      it 'raises DuplicateMigrationNameError' do
        expect { migration }.to raise_error ClickHouse::MigrationSupport::Errors::DuplicateMigrationNameError

        expect(active_schema_migrations_count).to eq 0
      end
    end

    context 'when migrations with duplicate version exist' do
      let(:migrations_dirname) { 'duplicate_version' }

      it 'raises DuplicateMigrationVersionError' do
        expect { migration }.to raise_error ClickHouse::MigrationSupport::Errors::DuplicateMigrationVersionError

        expect(active_schema_migrations_count).to eq 0
      end
    end
  end

  describe 'performs rollbacks' do
    subject(:migration) { rollback(migration_context, target_version) }

    before do
      # Ensure that all migrations are up
      migrate(migration_context, nil)
    end

    context 'when down method is present' do
      let(:migrations_dirname) { 'table_creation_with_down_method' }

      context 'when specifying target_version' do
        it 'removes migrations and performs down method' do
          expect(table_names).to include('some', 'another')

          # test that target_version is prioritized over step
          expect { rollback(migration_context, 1, 10000) }.to change { active_schema_migrations_count }.from(2).to(1)
          expect(table_names).not_to include('another')
          expect(table_names).to include('some')
          expect(schema_migrations).to contain_exactly(
            a_hash_including(version: '1', active: 1),
            a_hash_including(version: '2', active: 0)
          )

          expect { rollback(migration_context, nil) }.to change { active_schema_migrations_count }.to(0)
          expect(table_names).not_to include('some', 'another')

          expect(schema_migrations).to contain_exactly(
            a_hash_including(version: '1', active: 0),
            a_hash_including(version: '2', active: 0)
          )
        end
      end

      context 'when specifying step' do
        it 'removes migrations and performs down method' do
          expect(table_names).to include('some', 'another')

          expect { rollback(migration_context, nil, 1) }.to change { active_schema_migrations_count }.from(2).to(1)
          expect(table_names).not_to include('another')
          expect(table_names).to include('some')

          expect { rollback(migration_context, nil, 2) }.to change { active_schema_migrations_count }.to(0)
          expect(table_names).not_to include('some', 'another')
        end
      end
    end

    context 'when down method is missing' do
      let(:migrations_dirname) { 'plain_table_creation' }
      let(:target_version) { 0 }

      it 'removes migration ignoring missing down method' do
        expect { migration }.to change { active_schema_migrations_count }.from(1).to(0)
          .and not_change { table_names & %w[some] }.from(%w[some])
      end
    end

    context 'when target_version is incorrect' do
      let(:target_version) { -1 }
      let(:migrations_dirname) { 'plain_table_creation' }

      it 'raises UnknownMigrationVersionError' do
        expect { migration }.to raise_error ClickHouse::MigrationSupport::Errors::UnknownMigrationVersionError

        expect(active_schema_migrations_count).to eq 1
      end
    end
  end
end
