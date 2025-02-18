# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Runner, :reestablished_active_record_base do
  let(:base_result_dir) { Pathname.new(Dir.mktmpdir) }

  let(:migration_runs) { [] } # This list gets populated as the runner tries to run migrations

  # Tests depend on all of these lists being sorted in the order migrations would be applied
  let(:applied_migrations_other_branches) do
    [
      double(
        ActiveRecord::Migration,
        version: 1,
        name: 'migration_complete_other_branch',
        filename: 'db/migrate/1_migration_complete_other_branch.rb'
      )
    ]
  end

  let(:applied_migrations_this_branch) do
    [
      double(
        ActiveRecord::Migration,
        version: 2,
        name: 'older_migration_complete_this_branch',
        filename: 'db/migrate/2_older_migration_complete_this_branch.rb'
      ),
      double(
        ActiveRecord::Migration,
        version: 3,
        name: 'post_migration_complete_this_branch',
        filename: 'db/post_migrate/3_post_migration_complete_this_branch.rb'
      ),
      double(
        ActiveRecord::Migration,
        version: 4,
        name: 'newer_migration_complete_this_branch',
        filename: 'db/migrate/4_newer_migration_complete_this_branch.rb'
      )
    ].sort_by(&:version)
  end

  let(:pending_migrations) do
    [
      double(
        ActiveRecord::Migration,
        version: 5,
        name: 'older_migration_pending',
        filename: 'db/migrate/5_older_migration_pending.rb'
      ),
      double(
        ActiveRecord::Migration,
        version: 6,
        name: 'post_migration_pending',
        filename: 'db/post_migrate/6_post_migration_pending.rb'
      ),
      double(
        ActiveRecord::Migration,
        version: 7,
        name: 'newer_migration_pending',
        filename: 'db/migrate/7_newer_migration_pending.rb'
      )
    ].sort_by(&:version)
  end

  before do
    skip_if_shared_database(database)

    stub_const('Gitlab::Database::Migrations::Runner::BASE_RESULT_DIR', base_result_dir)
    allow(ActiveRecord::Migrator).to receive(:new) do |dir, _all_migrations, _schema_migration_class, version_to_migrate|
      migrator = double(ActiveRecord::Migrator)
      expect(migrator).to receive(:run) do
        config_for_migration_run = ActiveRecord::Base.connection_db_config
        migration_runs << double('migrator', dir: dir, version_to_migrate: version_to_migrate, database: config_for_migration_run.name)
      end
      migrator
    end

    all_versions = (applied_migrations_other_branches + applied_migrations_this_branch).map(&:version)
    migrations = applied_migrations_other_branches + applied_migrations_this_branch + pending_migrations
    ctx = double(ActiveRecord::MigrationContext, get_all_versions: all_versions, migrations: migrations, schema_migration: ActiveRecord::SchemaMigration)

    allow(ActiveRecord::Base.connection).to receive(:migration_context).and_return(ctx)

    names_this_branch = (applied_migrations_this_branch + pending_migrations).map { |m| "db/migrate/#{m.version}_#{m.name}.rb" }
    allow(described_class).to receive(:migration_file_names_this_branch).and_return(names_this_branch)
  end

  after do
    FileUtils.rm_rf(base_result_dir)
  end

  where(:case_name, :database, :result_dir, :legacy_mode, :expected_schema_version) do
    [
      ['main database', :main, lazy { base_result_dir.join('main') }, false, described_class::SCHEMA_VERSION],
      ['main database (legacy mode)', :main, lazy { base_result_dir }, true, 3],
      ['ci database', :ci, lazy { base_result_dir.join('ci') }, false, described_class::SCHEMA_VERSION]
    ]
  end

  with_them do
    it 'creates the results dir when one does not exist' do
      FileUtils.rm_rf(result_dir)

      expect do
        described_class.new(direction: :up, migrations: [], database: database).run
      end.to change { Dir.exist?(result_dir) }.from(false).to(true)
    end

    describe '.up' do
      context 'result directory' do
        it 'uses the /up subdirectory' do
          expect(described_class.up(database: database, legacy_mode: legacy_mode).result_dir).to eq(result_dir.join('up'))
        end
      end

      context 'migrations to run' do
        subject(:up) { described_class.up(database: database, legacy_mode: legacy_mode) }

        it 'is the list of pending migrations' do
          expect(up.migrations).to eq(pending_migrations)
        end
      end

      context 'running migrations' do
        subject(:up) { described_class.up(database: database, legacy_mode: legacy_mode) }

        it 'runs the unapplied migrations in regular/post order, then version order', :aggregate_failures do
          up.run

          expect(migration_runs.map(&:dir)).to match_array([:up, :up, :up])
          expect(migration_runs.map(&:version_to_migrate)).to eq([5, 7, 6])
        end

        it 'writes a metadata file with the current schema version and database name' do
          up.run

          metadata_file = result_dir.join('up', described_class::METADATA_FILENAME)
          expect(metadata_file.exist?).to be_truthy
          metadata = Gitlab::Json.parse(File.read(metadata_file))
          expect(metadata).to match('version' => expected_schema_version, 'database' => database.to_s)
        end

        it 'runs the unapplied migrations on the correct database' do
          up.run

          expect(migration_runs.map(&:database).uniq).to contain_exactly(database.to_s)
        end
      end
    end

    describe '.down' do
      subject(:down) { described_class.down(database: database, legacy_mode: legacy_mode) }

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

          expect(migration_runs.map(&:dir)).to match_array([:down, :down, :down])
          expect(migration_runs.map(&:version_to_migrate)).to eq([3, 4, 2])
        end
      end

      it 'writes a metadata file with the current schema version' do
        down.run

        metadata_file = result_dir.join('down', described_class::METADATA_FILENAME)
        expect(metadata_file.exist?).to be_truthy
        metadata = Gitlab::Json.parse(File.read(metadata_file))
        expect(metadata).to match('version' => expected_schema_version, 'database' => database.to_s)
      end
    end

    describe '.background_migrations' do
      it 'is a TestBackgroundRunner' do
        expect(described_class.background_migrations).to be_a(Gitlab::Database::Migrations::TestBackgroundRunner)
      end

      it 'is configured with a result dir of /background_migrations' do
        runner = described_class.background_migrations

        expect(runner.result_dir).to eq(described_class::BASE_RESULT_DIR.join('background_migrations'))
      end
    end

    describe '.batched_background_migrations' do
      it 'is a TestBatchedBackgroundRunner' do
        expect(described_class.batched_background_migrations(for_database: database)).to be_a(Gitlab::Database::Migrations::TestBatchedBackgroundRunner)
      end

      context 'choosing the database to test against' do
        it 'chooses the provided database' do
          runner = described_class.batched_background_migrations(for_database: database)

          chosen_connection_name = Gitlab::Database.db_config_name(runner.connection)

          expect(chosen_connection_name).to eq(database.to_s)
        end

        it 'throws an error with an invalid name' do
          expect { described_class.batched_background_migrations(for_database: 'not_a_database') }
            .to raise_error(/not a valid database name/)
        end

        it 'includes the database name in the result dir' do
          runner = described_class.batched_background_migrations(for_database: database)

          expect(runner.result_dir).to eq(base_result_dir.join(database.to_s, 'background_migrations'))
        end
      end

      context 'legacy mode' do
        it 'does not include the database name in the path' do
          runner = described_class.batched_background_migrations(for_database: database, legacy_mode: true)

          expect(runner.result_dir).to eq(base_result_dir.join('background_migrations'))
        end
      end
    end

    describe '.batched_migrations_last_id' do
      let(:runner_class) { Gitlab::Database::Migrations::BatchedMigrationLastId }

      it 'matches the expected runner class' do
        expect(described_class.batched_migrations_last_id(database)).to be_a(runner_class)
      end
    end
  end
end
