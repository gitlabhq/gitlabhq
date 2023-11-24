# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:clickhouse', click_house: :without_migrations, feature_category: :database do
  include ClickHouseTestHelpers

  # We don't need to delete data since we don't modify Postgres data
  self.use_transactional_tests = false

  let(:verbose) { nil }
  let(:target_version) { nil }
  let(:step) { nil }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/click_house/migration'
  end

  before do
    stub_env('VERBOSE', verbose) if verbose
    stub_env('VERSION', target_version) if target_version
    stub_env('STEP', step.to_s) if step
  end

  context 'with real migrations' do
    let(:migrations_dir) { File.expand_path(rails_root_join('db', 'click_house', 'migrate')) }

    before do
      ClickHouse::MigrationSupport::Migrator.migrations_paths = [migrations_dir]
    end

    it 'runs migrations and rollbacks' do
      expect { run_rake_task('gitlab:clickhouse:migrate') }.to change { active_schema_migrations_count }.from(0)
        .and output.to_stdout

      expect { run_rake_task('gitlab:clickhouse:rollback') }.to change { active_schema_migrations_count }.by(-1)
        .and output.to_stdout

      stub_env('VERSION', 0)
      expect { run_rake_task('gitlab:clickhouse:rollback') }.to change { active_schema_migrations_count }.to(0)
    end
  end

  context 'with migration fixtures' do
    let(:migrations_base_dir) { 'click_house/migrations' }
    let(:migrations_dirname) { 'undefined' }
    let(:migrations_dir) { expand_fixture_path("#{migrations_base_dir}/#{migrations_dirname}") }

    describe 'migrate' do
      subject(:migration) { run_rake_task('gitlab:clickhouse:migrate') }

      around do |example|
        ClickHouse::MigrationSupport::Migrator.migrations_paths = [migrations_dir]

        example.run

        clear_consts(expand_fixture_path(migrations_base_dir))
      end

      describe 'when creating a table' do
        let(:migrations_dirname) { 'plain_table_creation' }

        it 'creates a table' do
          expect { migration }.to change { active_schema_migrations_count }.from(0).to(1)
            .and output.to_stdout

          expect(describe_table('some')).to match({
            id: a_hash_including(type: 'UInt64'),
            date: a_hash_including(type: 'Date')
          })
        end

        context 'when VERBOSE is false' do
          let(:verbose) { 'false' }

          it 'does not write to stdout' do
            expect { migration }.not_to output.to_stdout

            expect(describe_table('some')).to match({
              id: a_hash_including(type: 'UInt64'),
              date: a_hash_including(type: 'Date')
            })
          end
        end
      end

      describe 'when dropping a table' do
        let(:migrations_dirname) { 'drop_table' }

        context 'with VERSION set' do
          let(:target_version) { 2 }

          it 'drops table' do
            stub_env('VERSION', 1)
            run_rake_task('gitlab:clickhouse:migrate')

            expect(table_names).to include('some')

            stub_env('VERSION', target_version)
            migration
            expect(table_names).not_to include('some')
          end

          context 'with STEP also set' do
            let(:step) { 1 }

            it 'ignores STEP and executes both migrations' do
              migration

              expect(table_names).not_to include('some')
            end
          end
        end

        context 'with STEP set to 1' do
          let(:step) { 1 }

          it 'executes only first step and creates table' do
            migration

            expect(table_names).to include('some')
          end
        end

        context 'with STEP set to 0' do
          let(:step) { 0 }

          it 'executes only first step and creates table' do
            expect { migration }.to raise_error ArgumentError, 'STEP should be a positive number'
          end
        end

        context 'with STEP set to not-a-number' do
          let(:step) { 'NaN' }

          it 'raises an error' do
            expect { migration }.to raise_error ArgumentError, 'invalid value for Integer(): "NaN"'
          end
        end

        context 'with STEP set to empty string' do
          let(:step) { '' }

          it 'raises an error' do
            expect { migration }.to raise_error ArgumentError, 'invalid value for Integer(): ""'
          end
        end
      end

      context 'with VERSION is invalid' do
        let(:migrations_dirname) { 'plain_table_creation' }
        let(:target_version) { 'invalid' }

        it { expect { migration }.to raise_error RuntimeError, 'Invalid format of target version: `VERSION=invalid`' }
      end
    end

    describe 'rollback' do
      subject(:migration) { run_rake_task('gitlab:clickhouse:rollback') }

      let(:migrations_dirname) { 'table_creation_with_down_method' }

      around do |example|
        ClickHouse::MigrationSupport::Migrator.migrations_paths = [migrations_dir]
        # Ensure we start with all migrations up
        schema_migration = ClickHouse::MigrationSupport::SchemaMigration
        migrate(ClickHouse::MigrationSupport::MigrationContext.new(migrations_dir, schema_migration), nil)

        example.run

        clear_consts(expand_fixture_path(migrations_base_dir))
      end

      context 'with VERSION set' do
        context 'when migrating back all the way to 0' do
          let(:target_version) { 0 }

          it 'rolls back all migrations' do
            expect(table_names).to include('some', 'another')

            migration
            expect(table_names).not_to include('some', 'another')
          end

          context 'with STEP also set' do
            let(:step) { 1 }

            it 'ignores STEP and rolls back all migrations' do
              expect(table_names).to include('some', 'another')

              migration
              expect(table_names).not_to include('some', 'another')
            end
          end
        end
      end

      context 'with STEP set to 1' do
        let(:step) { 1 }

        it 'executes only first step and drops "another" table' do
          run_rake_task('gitlab:clickhouse:rollback')

          expect(table_names).to include('some')
          expect(table_names).not_to include('another')
        end
      end
    end
  end

  %w[gitlab:clickhouse:migrate].each do |task|
    context "when running #{task}" do
      it "does run gitlab:clickhouse:prepare_schema_migration_table before" do
        expect(Rake::Task['gitlab:clickhouse:prepare_schema_migration_table']).to receive(:execute).and_return(true)
        expect(Rake::Task[task]).to receive(:execute).and_return(true)

        Rake::Task['gitlab:clickhouse:prepare_schema_migration_table'].reenable
        run_rake_task(task)
      end
    end
  end
end
