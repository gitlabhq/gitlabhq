# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:clickhouse', click_house: :without_migrations, feature_category: :database do
  include ClickHouseHelpers

  # We don't need to delete data since we don't modify Postgres data
  self.use_transactional_tests = false

  let(:migrations_base_dir) { 'click_house/migrations' }
  let(:migrations_dirname) { '' }
  let(:migrations_dir) { expand_fixture_path("#{migrations_base_dir}/#{migrations_dirname}") }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/click_house/migration'
  end

  before do
    stub_env('VERBOSE', 'false')
  end

  describe 'migrate' do
    subject(:migration) { run_rake_task('gitlab:clickhouse:migrate') }

    let(:target_version) { nil }

    around do |example|
      ClickHouse::MigrationSupport::Migrator.migrations_paths = [migrations_dir]

      example.run

      clear_consts(expand_fixture_path(migrations_base_dir))
    end

    before do
      stub_env('VERSION', target_version) if target_version
    end

    describe 'when creating a table' do
      let(:migrations_dirname) { 'plain_table_creation' }

      it 'creates a table' do
        expect { migration }.to change { active_schema_migrations_count }.from(0).to(1)

        expect(describe_table('some')).to match({
          id: a_hash_including(type: 'UInt64'),
          date: a_hash_including(type: 'Date')
        })
      end
    end

    describe 'when dropping a table' do
      let(:migrations_dirname) { 'drop_table' }
      let(:target_version) { 2 }

      it 'drops table' do
        stub_env('VERSION', 1)
        run_rake_task('gitlab:clickhouse:migrate')

        expect(table_names).to include('some')

        stub_env('VERSION', target_version)
        migration
        expect(table_names).not_to include('some')
      end
    end

    describe 'with VERSION is invalid' do
      let(:migrations_dirname) { 'plain_table_creation' }
      let(:target_version) { 'invalid' }

      it { expect { migration }.to raise_error RuntimeError, 'Invalid format of target version: `VERSION=invalid`' }
    end
  end

  describe 'rollback' do
    subject(:migration) { run_rake_task('gitlab:clickhouse:rollback') }

    let(:schema_migration) { ClickHouse::MigrationSupport::SchemaMigration }

    around do |example|
      ClickHouse::MigrationSupport::Migrator.migrations_paths = [migrations_dir]
      migrate(nil, ClickHouse::MigrationSupport::MigrationContext.new(migrations_dir, schema_migration))

      example.run

      clear_consts(expand_fixture_path(migrations_base_dir))
    end

    context 'when migrating back all the way to 0' do
      let(:target_version) { 0 }

      context 'when down method is present' do
        let(:migrations_dirname) { 'table_creation_with_down_method' }

        it 'removes migration' do
          expect(table_names).to include('some')

          migration
          expect(table_names).not_to include('some')
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
