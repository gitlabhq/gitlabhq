# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Targets::Database, :reestablished_active_record_base, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let(:progress_output) { progress.string }
  let(:backup_id) { 'some_id' }
  let(:one_database_configured?) { base_models_for_backup.one? }
  let(:force) { true }
  let(:backup_options) { Backup::Options.new(force: force) }
  let(:logger) { subject.logger }
  let(:timeout_service) do
    instance_double(Gitlab::Database::TransactionTimeoutSettings, restore_timeouts: nil, disable_timeouts: nil)
  end

  let(:base_models_for_backup) do
    Gitlab::Database.database_base_models_with_gitlab_shared.select do |database_name|
      Gitlab::Database.has_database?(database_name)
    end
  end

  before(:context) do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/gitlab/backup'
    Rake.application.rake_require 'tasks/gitlab/shell'
    Rake.application.rake_require 'tasks/gitlab/db'
    Rake.application.rake_require 'tasks/cache'
  end

  describe '#dump', :delete do
    subject(:databases) { described_class.new(progress, options: backup_options) }

    it 'creates gzipped database dumps' do
      Dir.mktmpdir do |dir|
        databases.dump(dir, backup_id)

        base_models_for_backup.each_key do |database_name|
          filename = database_name == 'main' ? 'database.sql.gz' : "#{database_name}_database.sql.gz"
          expect(File.exist?(File.join(dir, filename))).to eq(true)
        end
      end
    end

    context 'when using multiple databases' do
      before do
        skip_if_shared_database(:ci)
      end

      it 'uses snapshots' do
        Dir.mktmpdir do |dir|
          # We create two Backup::DatabaseConnection objects for
          # each database. The first one inside the each_database
          # block and another in the ensure block.
          number_of_databases = base_models_for_backup.count
          number_of_database_connections = number_of_databases * 2
          number_of_stubbed_database_connections = 0

          expect_next_instances_of(Backup::DatabaseConnection, number_of_database_connections) do |backup_connection|
            if number_of_stubbed_database_connections >= number_of_databases
              expect(backup_connection).to receive(:restore_timeouts!).and_call_original
            else
              expect(backup_connection).to receive(:export_snapshot!).and_call_original

              expect_next_instance_of(::Gitlab::Backup::Cli::Utils::PgDump) do |pgdump|
                expect(pgdump.snapshot_id).to eq(backup_connection.snapshot_id)
              end

              expect(backup_connection).to receive(:release_snapshot!).and_call_original
            end

            number_of_stubbed_database_connections += 1
          end

          databases.dump(dir, backup_id)
        end
      end
    end

    context 'when using a single database' do
      before do
        skip_if_database_exists(:ci)
      end

      it 'does not use snapshots' do
        Dir.mktmpdir do |dir|
          expect_next_instance_of(Backup::DatabaseConnection) do |backup_connection|
            expect(backup_connection).not_to receive(:export_snapshot!)

            expect_next_instance_of(::Gitlab::Backup::Cli::Utils::PgDump) do |pgdump|
              expect(pgdump.snapshot_id).to be_nil
            end

            expect(backup_connection).not_to receive(:release_snapshot!)
          end

          databases.dump(dir, backup_id)
        end
      end
    end

    context 'when a StandardError (or descendant) is raised' do
      before do
        allow(FileUtils).to receive(:mkdir_p).and_raise(StandardError)
      end

      context 'when using multiple databases' do
        before do
          skip_if_shared_database(:ci)
        end

        it 'restores timeouts' do
          Dir.mktmpdir do |dir|
            number_of_databases = base_models_for_backup.count

            expect(Backup::DatabaseConnection)
              .to receive(:new)
              .exactly(number_of_databases)
              .times
              .and_call_original

            expect(Gitlab::Database::TransactionTimeoutSettings)
              .to receive(:new)
              .exactly(number_of_databases)
              .times
              .and_return(timeout_service)

            expect(timeout_service)
              .to receive(:restore_timeouts)
              .exactly(number_of_databases)
              .times

            expect { databases.dump(dir, backup_id) }.to raise_error StandardError
          end
        end
      end

      context 'when using a single database' do
        before do
          skip_if_database_exists(:ci)
        end

        it 'does not restore timeouts' do
          expect(Gitlab::Database::TransactionTimeoutSettings).not_to receive(:new)

          expect { databases.dump(dir, backup_id) }.to raise_error StandardError
        end
      end
    end

    context 'when using GITLAB_BACKUP_* environment variables' do
      before do
        stub_env('GITLAB_BACKUP_PGHOST', 'test.invalid.')
      end

      it 'overrides database.yml configuration' do
        # Expect an error because we can't connect to test.invalid.
        expect do
          Dir.mktmpdir { |dir| databases.dump(dir, backup_id) }
        end.to raise_error(Backup::DatabaseBackupError)

        expect do
          ApplicationRecord.connection.select_value('select 1')
        end.not_to raise_error

        expect(ENV['PGHOST']).to be_nil
      end
    end
  end

  describe '#restore' do
    let(:cmd) { %W[#{Gem.ruby} -e $stdout.puts(1)] }
    let(:backup_dir) { Rails.root.join("spec/fixtures/") }
    let(:rake_task) { instance_double(Rake::Task, invoke: true) }

    subject(:databases) { described_class.new(progress, options: backup_options) }

    before do
      allow(Rake::Task).to receive(:[]).with(any_args).and_return(rake_task)

      allow(databases).to receive(:pg_restore_cmd).and_return(cmd)
    end

    context 'when not forced' do
      let(:force) { false }

      it 'warns the user and waits' do
        expect(databases).to receive(:sleep)

        if one_database_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        databases.restore(backup_dir, backup_id)

        expect(progress_output).to include('Removing all tables. Press `Ctrl-C` within 5 seconds to abort')
      end
    end

    context 'with an empty .gz file' do
      it 'returns successfully' do
        if one_database_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        databases.restore(backup_dir, backup_id)

        expect(progress_output).to include("Restoring PostgreSQL database")
        expect(progress_output).to include("[DONE]")
        expect(progress_output).not_to include("ERRORS")
      end

      context 'when DECOMPRESS_CMD is set to tee' do
        before do
          stub_env('DECOMPRESS_CMD', 'tee')
        end

        it 'outputs a message about DECOMPRESS_CMD' do
          expect do
            databases.restore(backup_dir, backup_id)
          end.to output(/Using custom DECOMPRESS_CMD 'tee'/).to_stdout
        end
      end
    end

    context 'with a corrupted .gz file' do
      before do
        allow(databases).to receive(:file_name).and_return("#{backup_dir}big-image.png")
      end

      it 'raises a backup error' do
        if one_database_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        expect { databases.restore(backup_dir, backup_id) }.to raise_error(Backup::Error)
      end
    end

    context 'when the restore command prints errors' do
      let(:visible_error) { "This is a test error\n" }
      let(:noise) { "must be owner of extension pg_trgm\nWARNING:  no privileges could be revoked for public\n" }
      let(:cmd) { %W[#{Gem.ruby} -e $stderr.write("#{noise}#{visible_error}")] }

      it 'filters out noise from errors and store in errors attribute' do
        if one_database_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        databases.restore(backup_dir, backup_id)

        expect(progress_output).to include("ERRORS")
        expect(progress_output).not_to include(noise)
        expect(progress_output).to include(visible_error)
        expect(databases.errors).not_to be_empty
      end
    end

    # Mark test as non-transactional to prevent Rails from trying to connect to the
    # DB with invalid config.
    # With transactional tests, Rails checks out a connection every time a new
    # connection pool is established so that it can be pinned for all threads.
    context 'with PostgreSQL settings defined in the environment', :delete do
      let(:config) { YAML.load_file(Rails.root.join('config/database.yml'))['test'] }

      before do
        stub_env(ENV.to_h.merge({
          'GITLAB_BACKUP_PGHOST' => 'test.example.com',
          'PGPASSWORD' => 'donotchange'
        }))
      end

      it 'overrides default config values' do
        if one_database_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        expect(ENV).to receive(:merge!).with(hash_including { 'PGHOST' => 'test.example.com' })
        expect(ENV).not_to receive(:[]=).with('PGPASSWORD', anything)

        databases.restore(backup_dir, backup_id)

        expect(ENV['PGPORT']).to eq(config['port']) if config['port']
        expect(ENV['PGUSER']).to eq(config['username']) if config['username']
      end
    end

    context 'when the source file is missing' do
      context 'for main database' do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with("#{backup_dir}database.sql.gz").and_return(false)
          allow(File).to receive(:exist?).with("#{backup_dir}ci_database.sql.gz").and_return(false)
        end

        it 'raises an error about missing source file' do
          if one_database_configured?
            expect(Rake::Task['gitlab:db:drop_tables']).not_to receive(:invoke)
          else
            expect(Rake::Task['gitlab:db:drop_tables:main']).not_to receive(:invoke)
          end

          expect do
            databases.restore('db', backup_id)
          end.to raise_error(Backup::Error, /Source database file does not exist/)
        end
      end

      context 'for ci database' do
        it 'ci database tolerates missing source file' do
          expect { databases.restore(backup_dir, backup_id) }.not_to raise_error
        end
      end

      context 'on raising an ActiveRecord::StatementInvalid error' do
        it 'returns an error when there is insufficient privilege' do
          allow(databases).to receive(:drop_tables)
            .and_raise(ActiveRecord::StatementInvalid.new('PG::InsufficientPrivilege test error'))
          expect(databases).to receive(:report_success).with(false)
          databases.restore(backup_dir, backup_id)
        end

        it 'raises an error that does not match an expected error' do
          allow(databases).to receive(:drop_tables).and_raise(ActiveRecord::StatementInvalid.new('test error'))
          expect do
            databases.restore(backup_dir, backup_id)
          end.to raise_error(ActiveRecord::StatementInvalid, 'test error')
        end
      end
    end
  end

  describe '#include_openbao_db?' do
    subject(:databases) { described_class.new(progress, options: backup_options) }

    context 'when only base connection keys are set' do
      it 'returns false' do
        allow(ENV).to receive(:keys).and_return(
          %w[OPENBAO_DATABASE_HOST OPENBAO_DATABASE_PORT OPENBAO_DATABASE_NAME
            OPENBAO_DATABASE_SSLMODE OPENBAO_DATABASE_CONNECT_TIMEOUT OPENBAO_DATABASE_USER]
        )

        expect(databases.send(:include_openbao_db?)).to eq(false)
      end
    end

    context 'when OPENBAO_DATABASE_PASSWORD is set along with base keys' do
      it 'returns true' do
        allow(ENV).to receive(:keys).and_return(
          %w[OPENBAO_DATABASE_HOST OPENBAO_DATABASE_PORT OPENBAO_DATABASE_NAME
            OPENBAO_DATABASE_USER OPENBAO_DATABASE_PASSWORD]
        )

        expect(databases.send(:include_openbao_db?)).to eq(true)
      end
    end

    context 'when no openbao database environment variables are set' do
      it 'returns false' do
        allow(ENV).to receive(:keys).and_return([])

        expect(databases.send(:include_openbao_db?)).to eq(false)
      end
    end
  end

  describe '#registry_db_connection' do
    subject(:databases) { described_class.new(progress, options: backup_options) }

    let(:registry_db_config) do
      {
        adapter: 'postgresql',
        database: 'registry_db',
        username: 'registry_user',
        password: 'registry_pass',
        host: 'registry.example.com',
        port: '5432',
        sslmode: 'require',
        sslcert: '/path/to/cert',
        sslkey: '/path/to/key',
        sslrootcert: '/path/to/rootcert'
      }
    end

    let(:mock_connection) do
      instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).tap do |conn|
        allow(conn).to receive(:postgresql_version).and_return(140000)
        allow(conn).to receive(:execute)
      end
    end

    let(:mock_db_connection) do
      instance_double(Backup::DatabaseConnection,
        connection: mock_connection,
        connection_name: 'registry'
      )
    end

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_NAME', nil).and_return(registry_db_config[:database])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_USER', nil).and_return(registry_db_config[:username])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_PASSWORD', nil).and_return(registry_db_config[:password])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_HOST', nil).and_return(registry_db_config[:host])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_PORT', nil).and_return(registry_db_config[:port])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_SSLMODE', nil).and_return(registry_db_config[:sslmode])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_SSLCERT', nil).and_return(registry_db_config[:sslcert])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_SSLKEY', nil).and_return(registry_db_config[:sslkey])
      allow(ENV).to receive(:fetch).with('REGISTRY_DATABASE_ROOTCERT',
        nil).and_return(registry_db_config[:sslrootcert])
      allow(ENV).to receive(:keys).and_return(["REGISTRY_DATABASE_VARIABLE"])
    end

    context 'for additional_connections_config' do
      it 'returns an array of connections' do
        allow(Backup::DatabaseConnection).to receive(:new).and_return(mock_db_connection)

        expect(databases.send(:additional_connections_config)).to eq([mock_db_connection])
      end
    end

    it 'creates registry connection with correct config' do
      expect(Backup::DatabaseConnection).to receive(:new).with('registry', custom_config: hash_including(
        adapter: 'postgresql',
        database: 'registry_db',
        username: 'registry_user',
        password: 'registry_pass',
        host: 'registry.example.com',
        port: '5432'
      )).and_return(mock_db_connection)

      databases.send(:registry_db_connection)
    end

    it 'validates registry connection is established' do
      failing_connection = double
      allow(failing_connection).to receive(:postgresql_version).and_raise(ActiveRecord::DatabaseConnectionError)

      expect(Backup::DatabaseConnection).to receive(:new).with('registry', custom_config: anything).and_return(
        instance_double(Backup::DatabaseConnection, connection: failing_connection)
      )

      expect do
        databases.send(:registry_db_connection)
      end.to raise_error(Backup::Error, /Unable to connect to the registry database/)
    end

    it 'returns a Backup::DatabaseConnection instance' do
      expect(Backup::DatabaseConnection).to receive(:new).with('registry',
        custom_config: anything).and_return(mock_db_connection)

      connection = databases.send(:registry_db_connection)

      expect(connection).to eq(mock_db_connection)
      expect(connection.connection_name).to eq('registry')
    end
  end

  describe '#openbao_db_connection' do
    subject(:databases) { described_class.new(progress, options: backup_options) }

    let(:openbao_db_config) do
      {
        adapter: 'postgresql',
        database: 'openbao_db',
        username: 'openbao_user',
        password: 'openbao_pass',
        host: 'openbao.example.com',
        port: '5432',
        sslmode: 'require',
        sslcert: '/path/to/cert',
        sslkey: '/path/to/key',
        sslrootcert: '/path/to/rootcert'
      }
    end

    let(:mock_connection) do
      instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).tap do |conn|
        allow(conn).to receive(:postgresql_version).and_return(140000)
        allow(conn).to receive(:execute)
      end
    end

    let(:mock_db_connection) do
      instance_double(Backup::DatabaseConnection,
        connection: mock_connection,
        connection_name: 'openbao'
      )
    end

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_NAME', nil).and_return(openbao_db_config[:database])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_USER', nil).and_return(openbao_db_config[:username])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_PASSWORD', nil).and_return(openbao_db_config[:password])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_HOST', nil).and_return(openbao_db_config[:host])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_PORT', nil).and_return(openbao_db_config[:port])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_SSLMODE', nil).and_return(openbao_db_config[:sslmode])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_SSLCERT', nil).and_return(openbao_db_config[:sslcert])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_SSLKEY', nil).and_return(openbao_db_config[:sslkey])
      allow(ENV).to receive(:fetch).with('OPENBAO_DATABASE_ROOTCERT',
        nil).and_return(openbao_db_config[:sslrootcert])
      allow(ENV).to receive(:keys).and_return(['OPENBAO_DATABASE_PASSWORD'])
    end

    it 'creates openbao connection with correct config' do
      expect(Backup::DatabaseConnection).to receive(:new).with('openbao', custom_config: hash_including(
        adapter: 'postgresql',
        database: 'openbao_db',
        username: 'openbao_user',
        password: 'openbao_pass',
        host: 'openbao.example.com',
        port: '5432'
      )).and_return(mock_db_connection)

      databases.send(:openbao_db_connection)
    end

    it 'validates openbao connection is established' do
      failing_connection = double
      allow(failing_connection).to receive(:postgresql_version).and_raise(ActiveRecord::DatabaseConnectionError)

      expect(Backup::DatabaseConnection).to receive(:new).with('openbao', custom_config: anything).and_return(
        instance_double(Backup::DatabaseConnection, connection: failing_connection)
      )

      expect do
        databases.send(:openbao_db_connection)
      end.to raise_error(Backup::Error, /Unable to connect to the openbao database/)
    end

    it 'returns a Backup::DatabaseConnection instance with connection_name openbao' do
      expect(Backup::DatabaseConnection).to receive(:new).with('openbao',
        custom_config: anything).and_return(mock_db_connection)

      connection = databases.send(:openbao_db_connection)

      expect(connection).to eq(mock_db_connection)
      expect(connection.connection_name).to eq('openbao')
    end

    context 'for additional_connections_config' do
      it 'returns an array containing the openbao connection' do
        allow(Backup::DatabaseConnection).to receive(:new).and_return(mock_db_connection)

        expect(databases.send(:additional_connections_config)).to eq([mock_db_connection])
      end
    end
  end

  describe '#additional_connections_config' do
    subject(:databases) { described_class.new(progress, options: backup_options) }

    let(:mock_registry_connection) do
      instance_double(Backup::DatabaseConnection,
        connection: instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter,
          postgresql_version: 140000),
        connection_name: 'registry'
      )
    end

    let(:mock_openbao_connection) do
      instance_double(Backup::DatabaseConnection,
        connection: instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter,
          postgresql_version: 140000),
        connection_name: 'openbao'
      )
    end

    context 'when only openbao env vars are set' do
      before do
        allow(ENV).to receive(:keys).and_return(['OPENBAO_DATABASE_PASSWORD'])
        allow(databases).to receive(:openbao_db_connection).and_return(mock_openbao_connection)
      end

      it 'returns only the openbao connection' do
        expect(databases.send(:additional_connections_config)).to eq([mock_openbao_connection])
      end
    end

    context 'when only registry env vars are set' do
      before do
        allow(ENV).to receive(:keys).and_return(['REGISTRY_DATABASE_PASSWORD'])
        allow(databases).to receive(:registry_db_connection).and_return(mock_registry_connection)
      end

      it 'returns only the registry connection' do
        expect(databases.send(:additional_connections_config)).to eq([mock_registry_connection])
      end
    end

    context 'when both registry and openbao env vars are set' do
      before do
        allow(ENV).to receive(:keys).and_return(%w[REGISTRY_DATABASE_PASSWORD OPENBAO_DATABASE_PASSWORD])
        allow(databases).to receive_messages(registry_db_connection: mock_registry_connection,
          openbao_db_connection: mock_openbao_connection)
      end

      it 'returns both connections' do
        result = databases.send(:additional_connections_config)

        expect(result).to match_array([mock_registry_connection, mock_openbao_connection])
      end
    end

    context 'when no additional databases are configured' do
      before do
        allow(ENV).to receive(:keys).and_return([])
      end

      it 'returns an empty array' do
        expect(databases.send(:additional_connections_config)).to eq([])
      end
    end
  end

  describe '#dump with additional connections', :delete do
    subject(:databases) { described_class.new(progress, options: backup_options) }

    context 'when registry database is configured' do
      let(:mock_registry_connection) do
        instance_double(Backup::DatabaseConnection,
          connection_name: 'registry',
          snapshot_id: nil,
          database_configuration: instance_double(Backup::DatabaseConfiguration,
            pg_env_variables: {},
            activerecord_variables: { database: 'registry_db' }
          )
        )
      end

      before do
        stub_env({
          'REGISTRY_DATABASE_NAME' => 'registry_db',
          'REGISTRY_DATABASE_USER' => 'registry_user',
          'REGISTRY_DATABASE_HOST' => 'localhost'
        })

        allow(databases).to receive(:additional_connections_config).and_return([mock_registry_connection])
        allow(mock_registry_connection).to receive(:release_snapshot!)
      end

      it 'dumps the registry database connection' do
        Dir.mktmpdir do |dir|
          dump_count = 0

          allow(Backup::Dump::Postgres).to receive(:new).and_return(
            double.tap do |postgres|
              allow(postgres).to receive(:dump) do
                dump_count += 1
                true
              end
            end
          )

          databases.dump(dir, backup_id)

          expected_dumps = base_models_for_backup.count + 1
          expect(dump_count).to eq(expected_dumps)
        end
      end
    end

    context 'when openbao database is configured' do
      let(:mock_openbao_connection) do
        instance_double(Backup::DatabaseConnection,
          connection_name: 'openbao',
          snapshot_id: nil,
          database_configuration: instance_double(Backup::DatabaseConfiguration,
            pg_env_variables: {},
            activerecord_variables: { database: 'openbao' }
          )
        )
      end

      before do
        stub_env({
          'OPENBAO_DATABASE_NAME' => 'openbao',
          'OPENBAO_DATABASE_USER' => 'openbao',
          'OPENBAO_DATABASE_HOST' => 'localhost'
        })

        allow(databases).to receive(:additional_connections_config).and_return([mock_openbao_connection])
        allow(mock_openbao_connection).to receive(:release_snapshot!)
      end

      it 'dumps the openbao database connection' do
        Dir.mktmpdir do |dir|
          dump_count = 0

          allow(Backup::Dump::Postgres).to receive(:new).and_return(
            double.tap do |postgres|
              allow(postgres).to receive(:dump) do
                dump_count += 1
                true
              end
            end
          )

          databases.dump(dir, backup_id)

          expected_dumps = base_models_for_backup.count + 1
          expect(dump_count).to eq(expected_dumps)
        end
      end
    end
  end

  describe '#restore with additional connections' do
    subject(:databases) { described_class.new(progress, options: backup_options) }

    let(:cmd) { %W[#{Gem.ruby} -e $stdout.puts(1)] }
    let(:backup_dir) { Rails.root.join("spec/fixtures/") }
    let(:rake_task) { instance_double(Rake::Task, invoke: true) }
    let(:registry_config) { { database: 'registry_db', adapter: 'postgresql' } }
    let(:registry_db_file) { "#{backup_dir}registry_database.sql.gz" }
    let(:mock_registry_connection) do
      instance_double(Backup::DatabaseConnection,
        connection_name: 'registry',
        database_configuration: instance_double(Backup::DatabaseConfiguration,
          activerecord_variables: registry_config,
          pg_env_variables: {}
        ),
        connection: instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter,
          execute: nil),
        tables: %w[test_table1 test_table2],
        functions: %w[test_function1 test_function2]
      )
    end

    before do
      allow(Rake::Task).to receive(:[]).with(any_args).and_return(rake_task)
      allow(databases).to receive(:pg_restore_cmd).and_return(cmd)
    end

    context 'when registry database is configured' do
      before do
        stub_env({
          'REGISTRY_DATABASE_NAME' => 'registry_db',
          'REGISTRY_DATABASE_USER' => 'registry_user',
          'REGISTRY_DATABASE_HOST' => 'localhost'
        })

        allow(databases).to receive(:additional_connections_config).and_return([mock_registry_connection])
      end

      it 'restores the registry database connection' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(registry_db_file).and_return(true)

        restore_calls = []
        allow(databases).to receive(:do_restore) do |connection, config, file|
          restore_calls << { connection: connection, config: config, file: file }
        end

        databases.restore(backup_dir, backup_id)

        registry_restore = restore_calls.find { |call| call[:connection] == mock_registry_connection }
        expect(registry_restore).not_to be_nil
        expect(registry_restore[:config]).to eq(registry_config)
        expect(registry_restore[:file]).to eq(registry_db_file)
      end

      context 'in #drop_tables_for_additional_connections' do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(registry_db_file).and_return(true)
          allow_next_instance_of(Backup::DatabaseConnection) do |connection|
            allow(connection).to receive(:connection).and_return(mock_registry_connection)
          end

          mock_registry_connection.tables.each do |table|
            allow(mock_registry_connection.connection).to receive(:quote_table_name).with(table).and_return(table)
          end
          mock_registry_connection.functions.each do |function|
            allow(mock_registry_connection.connection).to receive(:quote_table_name).with(function).and_return(function)
          end
        end

        it 'does not raise an error' do
          expect(databases).to receive(:drop_tables_for_additional_connection).once.and_call_original
          expect(mock_registry_connection).to receive(:connection)
          mock_registry_connection.tables.each do |table|
            expect(mock_registry_connection.connection)
              .to receive(:execute).with("DROP TABLE IF EXISTS #{table} CASCADE")
          end
          mock_registry_connection.functions.each do |function|
            expect(mock_registry_connection.connection).to receive(:execute).with("DROP FUNCTION IF EXISTS #{function}")
          end
          expect { databases.restore(backup_dir, backup_id) }.not_to raise_error
        end

        it 'does not raise an error when it receives a PG::ServerError' do
          error = ActiveRecord::StatementInvalid.new("test error")
          allow(error).to receive(:cause).and_return(PG::ServerError.new("server error"))
          allow(mock_registry_connection.connection).to receive(:execute).and_raise(error)
          expect { databases.restore(backup_dir, backup_id) }.not_to raise_error
        end

        it 'raises an error when it receives an error that is not of type PG::ServerError' do
          error = ActiveRecord::StatementInvalid.new("test error")
          allow(error).to receive(:cause).and_return(StandardError.new("server error"))
          allow(mock_registry_connection.connection).to receive(:execute).and_raise(error)
          expect { databases.restore(backup_dir, backup_id) }.to raise_error(StandardError, 'test error')
        end
      end

      it 'skips restore when backup file does not exist' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(registry_db_file).and_return(false)

        databases.restore(backup_dir, backup_id)

        expect(progress_output).to include("Source backup for the database registry doesn't exist")
      end
    end

    context 'when openbao database is configured' do
      let(:openbao_config) { { database: 'openbao', adapter: 'postgresql' } }
      let(:openbao_db_file) { "#{backup_dir}openbao_database.sql.gz" }
      let(:mock_openbao_connection) do
        instance_double(Backup::DatabaseConnection,
          connection_name: 'openbao',
          database_configuration: instance_double(Backup::DatabaseConfiguration,
            activerecord_variables: openbao_config,
            pg_env_variables: {}
          ),
          connection: instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter,
            execute: nil),
          tables: %w[test_table1 test_table2],
          functions: %w[test_function1 test_function2]
        )
      end

      before do
        stub_env({
          'OPENBAO_DATABASE_NAME' => 'openbao',
          'OPENBAO_DATABASE_USER' => 'openbao',
          'OPENBAO_DATABASE_HOST' => 'localhost'
        })

        allow(databases).to receive(:additional_connections_config).and_return([mock_openbao_connection])
      end

      it 'restores the openbao database connection' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(openbao_db_file).and_return(true)

        restore_calls = []
        allow(databases).to receive(:do_restore) do |connection, config, file|
          restore_calls << { connection: connection, config: config, file: file }
        end

        databases.restore(backup_dir, backup_id)

        openbao_restore = restore_calls.find { |call| call[:connection] == mock_openbao_connection }
        expect(openbao_restore).not_to be_nil
        expect(openbao_restore[:config]).to eq(openbao_config)
        expect(openbao_restore[:file]).to eq(openbao_db_file)
      end

      context 'in #drop_tables_for_additional_connections' do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(openbao_db_file).and_return(true)
          allow_next_instance_of(Backup::DatabaseConnection) do |connection|
            allow(connection).to receive(:connection).and_return(mock_openbao_connection)
          end

          mock_openbao_connection.tables.each do |table|
            allow(mock_openbao_connection.connection).to receive(:quote_table_name).with(table).and_return(table)
          end
          mock_openbao_connection.functions.each do |function|
            allow(mock_openbao_connection.connection).to receive(:quote_table_name).with(function).and_return(function)
          end
        end

        it 'does not raise an error' do
          expect(databases).to receive(:drop_tables_for_additional_connection).once.and_call_original
          expect(mock_openbao_connection).to receive(:connection)
          mock_openbao_connection.tables.each do |table|
            expect(mock_openbao_connection.connection)
              .to receive(:execute).with("DROP TABLE IF EXISTS #{table} CASCADE")
          end
          mock_openbao_connection.functions.each do |function|
            expect(mock_openbao_connection.connection).to receive(:execute).with("DROP FUNCTION IF EXISTS #{function}")
          end
          expect { databases.restore(backup_dir, backup_id) }.not_to raise_error
        end

        it 'does not raise an error when it receives a PG::ServerError' do
          error = ActiveRecord::StatementInvalid.new("test error")
          allow(error).to receive(:cause).and_return(PG::ServerError.new("server error"))
          allow(mock_openbao_connection.connection).to receive(:execute).and_raise(error)
          expect { databases.restore(backup_dir, backup_id) }.not_to raise_error
        end

        it 'raises an error when it receives an error that is not of type PG::ServerError' do
          error = ActiveRecord::StatementInvalid.new("test error")
          allow(error).to receive(:cause).and_return(StandardError.new("server error"))
          allow(mock_openbao_connection.connection).to receive(:execute).and_raise(error)
          expect { databases.restore(backup_dir, backup_id) }.to raise_error(StandardError, 'test error')
        end
      end

      it 'skips restore when backup file does not exist' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(openbao_db_file).and_return(false)

        databases.restore(backup_dir, backup_id)

        expect(progress_output).to include("Source backup for the database openbao doesn't exist")
      end
    end

    context 'when no additional databases are configured' do
      it 'only restores base databases' do
        allow(databases).to receive(:additional_connections_config).and_return([])

        restore_calls = []
        original_do_restore = databases.method(:do_restore)
        allow(databases).to receive(:do_restore) do |connection, config, file|
          restore_calls << file
          original_do_restore.call(connection, config, file)
        end

        databases.restore(backup_dir, backup_id)

        expect(restore_calls).not_to include(match(/registry/))
      end
    end
  end
end
