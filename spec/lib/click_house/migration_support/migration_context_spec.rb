# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::MigrationSupport::MigrationContext,
  click_house: :without_migrations, feature_category: :database do
  include ClickHouseTestHelpers

  # We don't need to delete data since we don't modify Postgres data
  self.use_transactional_tests = false

  let_it_be(:schema_migration) { ClickHouse::MigrationSupport::SchemaMigration }

  let(:migrations_base_dir) { 'click_house/migrations' }
  let(:migrations_dir) { expand_fixture_path("#{migrations_base_dir}/#{migrations_dirname}") }
  let(:migration_context) { described_class.new(migrations_dir, schema_migration) }
  let(:target_version) { nil }

  after do
    clear_consts(expand_fixture_path(migrations_base_dir))
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

    context 'when a migration targets an unknown database' do
      let(:migrations_dirname) { 'plain_table_creation_on_invalid_database' }

      it 'raises ConfigurationError' do
        expect { migration }.to raise_error ClickHouse::Client::ConfigurationError,
          "The database 'unknown_database' is not configured"
      end
    end

    context 'when migrations target multiple databases' do
      let_it_be(:config) { ClickHouse::Client::Configuration.new }
      let_it_be(:main_db_config) { [:main, config] }
      let_it_be(:another_db_config) { [:another_db, config] }
      let_it_be(:another_database_name) { 'gitlab_clickhouse_test_2' }

      let(:migrations_dirname) { 'migrations_over_multiple_databases' }

      before(:context) do
        # Ensure we have a second database to run the test on
        clone_database_configuration(:main, :another_db, another_database_name, config)

        with_net_connect_allowed do
          ClickHouse::Client.execute("CREATE DATABASE IF NOT EXISTS #{another_database_name}", :main, config)
        end
      end

      after(:context) do
        with_net_connect_allowed do
          ClickHouse::Client.execute("DROP DATABASE #{another_database_name}", :another_db, config)
        end
      end

      around do |example|
        clear_db(config)

        previous_config = ClickHouse::Migration.client_configuration
        ClickHouse::Migration.client_configuration = config

        example.run
      ensure
        ClickHouse::Migration.client_configuration = previous_config
      end

      def clone_database_configuration(source_db_identifier, target_db_identifier, target_db_name, target_config)
        raw_config = Rails.application.config_for(:click_house)
        raw_config.each do |database_identifier, db_config|
          register_database(target_config, database_identifier, db_config)
        end

        target_db_config = raw_config[source_db_identifier].merge(database: target_db_name)
        register_database(target_config, target_db_identifier, target_db_config)
        target_config.http_post_proc = ClickHouse::Client.configuration.http_post_proc
        target_config.json_parser = ClickHouse::Client.configuration.json_parser
        target_config.logger = ::Logger.new(IO::NULL)
      end

      it 'registers migrations on respective database', :aggregate_failures do
        expect { migrate(migration_context, 2) }
          .to change { active_schema_migrations_count(*main_db_config) }.from(0).to(1)
          .and change { active_schema_migrations_count(*another_db_config) }.from(0).to(1)

        expect(schema_migrations(*another_db_config)).to contain_exactly(a_hash_including(version: '2', active: 1))
        expect(table_names(*main_db_config)).not_to include('some_on_another_db')
        expect(table_names(*another_db_config)).not_to include('some')

        expect(describe_table('some', *main_db_config)).to match({
          id: a_hash_including(type: 'UInt64'),
          date: a_hash_including(type: 'Date')
        })
        expect(describe_table('some_on_another_db', *another_db_config)).to match({
          id: a_hash_including(type: 'UInt64'),
          date: a_hash_including(type: 'Date')
        })

        expect { migrate(migration_context, nil) }
          .to change { active_schema_migrations_count(*main_db_config) }.to(2)
          .and not_change { active_schema_migrations_count(*another_db_config) }

        expect(schema_migrations(*main_db_config)).to match([
          a_hash_including(version: '1', active: 1),
          a_hash_including(version: '3', active: 1)
        ])
        expect(schema_migrations(*another_db_config)).to match_array(a_hash_including(version: '2', active: 1))

        expect(describe_table('some', *main_db_config)).to match({
          id: a_hash_including(type: 'UInt64'),
          timestamp: a_hash_including(type: 'Date')
        })
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
