# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:clickhouse', click_house: :without_migrations, feature_category: :database do
  include ClickHouseSchemaHelpers

  # We don't need to delete data since we don't modify Postgres data
  self.use_transactional_tests = false

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/click_house/migration'
  end

  it 'migrates and rolls back the database' do
    expect { run_rake_task('gitlab:clickhouse:migrate:main') }.to change { active_schema_migrations_count }.from(0)
      .and output.to_stdout

    expect { run_rake_task('gitlab:clickhouse:rollback:main') }.to change { active_schema_migrations_count }.by(-1)
      .and output.to_stdout

    stub_env('VERSION', 0)
    expect { run_rake_task('gitlab:clickhouse:rollback:main') }.to change { active_schema_migrations_count }.to(0)
      .and output.to_stdout
  end

  context 'when clickhouse database is not configured' do
    before do
      allow(::ClickHouse::Client).to receive(:configuration).and_return(::ClickHouse::Client::Configuration.new)
    end

    it 'raises an error' do
      expect { run_rake_task('gitlab:clickhouse:migrate:main') }.to raise_error(ClickHouse::Client::ConfigurationError)
    end

    it 'prints the error message and exits successfully if skip_unless_configured is passed' do
      expect do
        run_rake_task('gitlab:clickhouse:migrate:main', true)
      end.to output(/The 'main' ClickHouse database is not configured, skipping migrations/).to_stdout
    end
  end

  describe 'gitlab:clickhouse:migrate' do
    it 'delegates to gitlab:clickhouse:migrate:main' do
      task = Rake::Task['gitlab:clickhouse:migrate:main']
      task.reenable # re-enabling task in case other tests already run it
      expect(task).to receive(:invoke).with("true").and_call_original

      expect do
        run_rake_task('gitlab:clickhouse:migrate', true)
      end.to change { active_schema_migrations_count }.from(0).and output.to_stdout
    end
  end

  context 'with migration fixtures', :silence_stdout do
    let(:migrations_base_dir) { 'click_house/migrations' }
    let(:migrations_dirname) { 'undefined' }
    let(:migrations_dir) { expand_fixture_path("#{migrations_base_dir}/#{migrations_dirname}") }

    describe 'migrate:main' do
      subject(:migration) { run_rake_task('gitlab:clickhouse:migrate:main') }

      let(:verbose) { nil }
      let(:target_version) { nil }
      let(:step) { nil }

      before do
        allow(ClickHouse::MigrationSupport::Migrator).to receive(:migrations_paths).with(:main)
          .and_return(migrations_dir)

        stub_env('VERBOSE', verbose) if verbose
        stub_env('VERSION', target_version) if target_version
        stub_env('STEP', step.to_s) if step
      end

      after do
        unload_click_house_migration_classes(expand_fixture_path(migrations_dir))
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
            run_rake_task('gitlab:clickhouse:migrate:main')

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

    describe 'rollback:main' do
      subject(:migration) { run_rake_task('gitlab:clickhouse:rollback:main') }

      let(:target_version) { nil }
      let(:rollback_step) { nil }
      let(:migrations_dirname) { 'table_creation_with_down_method' }

      before do
        allow(ClickHouse::MigrationSupport::Migrator).to receive(:migrations_paths).with(:main)
          .and_return(migrations_dir)

        run_rake_task('gitlab:clickhouse:migrate:main')

        stub_env('VERSION', target_version) if target_version
        stub_env('STEP', rollback_step.to_s) if rollback_step
      end

      after do
        unload_click_house_migration_classes(expand_fixture_path(migrations_dir))
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
            let(:rollback_step) { 1 }

            it 'ignores STEP and rolls back all migrations' do
              expect(table_names).to include('some', 'another')

              migration
              expect(table_names).not_to include('some', 'another')
            end
          end
        end
      end

      context 'with STEP set to 1' do
        let(:rollback_step) { 1 }

        it 'executes only first step and drops "another" table' do
          run_rake_task('gitlab:clickhouse:rollback:main')

          expect(table_names).to include('some')
          expect(table_names).not_to include('another')
        end
      end
    end
  end
end
