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

  before_all do
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

      it 'will override database.yml configuration' do
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

    context 'with PostgreSQL settings defined in the environment' do
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
    end
  end
end
