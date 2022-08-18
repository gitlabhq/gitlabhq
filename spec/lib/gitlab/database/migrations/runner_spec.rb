# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Runner do
  include Database::MultipleDatabases

  let(:result_dir) { Pathname.new(Dir.mktmpdir) }

  let(:migration_runs) { [] } # This list gets populated as the runner tries to run migrations

  # Tests depend on all of these lists being sorted in the order migrations would be applied
  let(:applied_migrations_other_branches) { [double(ActiveRecord::Migration, version: 1, name: 'migration_complete_other_branch')] }

  let(:applied_migrations_this_branch) do
    [
      double(ActiveRecord::Migration, version: 2, name: 'older_migration_complete_this_branch'),
      double(ActiveRecord::Migration, version: 3, name: 'newer_migration_complete_this_branch')
    ].sort_by(&:version)
  end

  let(:pending_migrations) do
    [
      double(ActiveRecord::Migration, version: 4, name: 'older_migration_pending'),
      double(ActiveRecord::Migration, version: 5, name: 'newer_migration_pending')
    ].sort_by(&:version)
  end

  before do
    stub_const('Gitlab::Database::Migrations::Runner::BASE_RESULT_DIR', result_dir)
    allow(ActiveRecord::Migrator).to receive(:new) do |dir, _all_migrations, _schema_migration_class, version_to_migrate|
      migrator = double(ActiveRecord::Migrator)
      expect(migrator).to receive(:run) do
        migration_runs << double('migrator', dir: dir, version_to_migrate: version_to_migrate)
      end
      migrator
    end

    all_versions = (applied_migrations_other_branches + applied_migrations_this_branch).map(&:version)
    migrations = applied_migrations_other_branches + applied_migrations_this_branch + pending_migrations
    ctx = double(ActiveRecord::MigrationContext, get_all_versions: all_versions, migrations: migrations, schema_migration: ActiveRecord::SchemaMigration)

    allow(described_class).to receive(:migration_context).and_return(ctx)

    names_this_branch = (applied_migrations_this_branch + pending_migrations).map { |m| "db/migrate/#{m.version}_#{m.name}.rb" }
    allow(described_class).to receive(:migration_file_names_this_branch).and_return(names_this_branch)
  end

  after do
    FileUtils.rm_rf(result_dir)
  end

  it 'creates the results dir when one does not exist' do
    FileUtils.rm_rf(result_dir)

    expect do
      described_class.new(direction: :up, migrations: [], result_dir: result_dir).run
    end.to change { Dir.exist?(result_dir) }.from(false).to(true)
  end

  describe '.up' do
    context 'result directory' do
      it 'uses the /up subdirectory' do
        expect(described_class.up.result_dir).to eq(result_dir.join('up'))
      end
    end

    context 'migrations to run' do
      subject(:up) { described_class.up }

      it 'is the list of pending migrations' do
        expect(up.migrations).to eq(pending_migrations)
      end
    end

    context 'running migrations' do
      subject(:up) { described_class.up }

      it 'runs the unapplied migrations in version order', :aggregate_failures do
        up.run

        expect(migration_runs.map(&:dir)).to match_array([:up, :up])
        expect(migration_runs.map(&:version_to_migrate)).to eq(pending_migrations.map(&:version))
      end

      it 'writes a metadata file with the current schema version' do
        up.run

        metadata_file = result_dir.join('up', described_class::METADATA_FILENAME)
        expect(metadata_file.exist?).to be_truthy
        metadata = Gitlab::Json.parse(File.read(metadata_file))
        expect(metadata).to match('version' => described_class::SCHEMA_VERSION)
      end
    end
  end

  describe '.down' do
    subject(:down) { described_class.down }

    context 'result directory' do
      it 'is the /down subdirectory' do
        expect(down.result_dir).to eq(result_dir.join('down'))
      end
    end

    context 'migrations to run' do
      it 'is the list of migrations that are up and on this branch' do
        expect(down.migrations).to eq(applied_migrations_this_branch)
      end
    end

    context 'running migrations' do
      it 'runs the applied migrations for the current branch in reverse order', :aggregate_failures do
        down.run

        expect(migration_runs.map(&:dir)).to match_array([:down, :down])
        expect(migration_runs.map(&:version_to_migrate)).to eq(applied_migrations_this_branch.reverse.map(&:version))
      end
    end

    it 'writes a metadata file with the current schema version' do
      down.run

      metadata_file = result_dir.join('down', described_class::METADATA_FILENAME)
      expect(metadata_file.exist?).to be_truthy
      metadata = Gitlab::Json.parse(File.read(metadata_file))
      expect(metadata).to match('version' => described_class::SCHEMA_VERSION)
    end
  end

  describe '.background_migrations' do
    it 'is a TestBackgroundRunner' do
      expect(described_class.background_migrations).to be_a(Gitlab::Database::Migrations::TestBackgroundRunner)
    end

    it 'is configured with a result dir of /background_migrations' do
      runner = described_class.background_migrations

      expect(runner.result_dir).to eq(described_class::BASE_RESULT_DIR.join( 'background_migrations'))
    end
  end

  describe '.batched_background_migrations' do
    it 'is a TestBatchedBackgroundRunner' do
      expect(described_class.batched_background_migrations(for_database: 'main')).to be_a(Gitlab::Database::Migrations::TestBatchedBackgroundRunner)
    end

    context 'choosing the database to test against' do
      it 'chooses the main database' do
        runner = described_class.batched_background_migrations(for_database: 'main')

        chosen_connection_name = Gitlab::Database.db_config_name(runner.connection)

        expect(chosen_connection_name).to eq('main')
      end

      it 'chooses the ci database' do
        skip_if_multiple_databases_not_setup

        runner = described_class.batched_background_migrations(for_database: 'ci')

        chosen_connection_name = Gitlab::Database.db_config_name(runner.connection)

        expect(chosen_connection_name).to eq('ci')
      end

      it 'throws an error with an invalid name' do
        expect { described_class.batched_background_migrations(for_database: 'not_a_database') }
          .to raise_error(/not a valid database name/)
      end
    end
  end
end
