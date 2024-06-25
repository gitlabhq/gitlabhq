# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:truncate_legacy_tables', :silence_stdout, :reestablished_active_record_base,
  :suppress_gitlab_schemas_validate_connection, feature_category: :cell do
  let(:main_connection) { ApplicationRecord.connection }
  let(:ci_connection) { Ci::ApplicationRecord.connection }
  let(:test_gitlab_main_table) { '_test_gitlab_main_table' }
  let(:test_gitlab_ci_table) { '_test_gitlab_ci_table' }

  before(:all) do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/db/validate_config'
    Rake.application.rake_require 'tasks/gitlab/db/truncate_legacy_tables'
  end

  before do
    skip_if_shared_database(:ci)

    execute_on_each_database(<<~SQL)
       CREATE TABLE #{test_gitlab_main_table} (id integer NOT NULL);
       INSERT INTO #{test_gitlab_main_table} VALUES(generate_series(1, 50));
    SQL
    execute_on_each_database(<<~SQL)
       CREATE TABLE #{test_gitlab_ci_table} (id integer NOT NULL);
       INSERT INTO #{test_gitlab_ci_table} VALUES(generate_series(1, 50));
    SQL

    allow(Gitlab::Database::GitlabSchema).to receive(:tables_to_schema).and_return(
      {
        test_gitlab_main_table => :gitlab_main,
        test_gitlab_ci_table => :gitlab_ci
      }
    )
  end

  shared_examples 'truncating legacy tables' do
    context 'when tables are not locked for writes' do
      it 'raises an error when trying to truncate the tables' do
        error_message = /is not locked for writes. Run the rake task gitlab:db:lock_writes first/
        expect { truncate_legacy_tables }.to raise_error(error_message)
      end
    end

    context 'when tables are locked for writes' do
      before do
        # Locking ci table on the main database
        Gitlab::Database::LockWritesManager.new(
          table_name: test_gitlab_ci_table,
          connection: main_connection,
          database_name: "main",
          with_retries: false
        ).lock_writes

        # Locking main table on the ci database
        Gitlab::Database::LockWritesManager.new(
          table_name: test_gitlab_main_table,
          connection: ci_connection,
          database_name: "ci",
          with_retries: false
        ).lock_writes
      end

      it 'calls TablesTruncate with the correct parameters and default minimum batch size' do
        expect(Gitlab::Database::TablesTruncate).to receive(:new).with(
          database_name: database_name,
          min_batch_size: 5,
          logger: anything,
          dry_run: false,
          until_table: nil
        ).and_call_original

        truncate_legacy_tables
      end

      it 'truncates the legacy table' do
        expect do
          truncate_legacy_tables
        end.to change { connection.select_value("SELECT count(*) from #{legacy_table}") }.from(50).to(0)
      end

      it 'does not truncate the table that belongs to the connection schema' do
        expect do
          truncate_legacy_tables
        end.not_to change { connection.select_value("SELECT count(*) from #{active_table}") }
      end

      context 'when running in dry_run mode' do
        before do
          stub_env('DRY_RUN', 'true')
        end

        it 'does not truncate any tables' do
          expect do
            truncate_legacy_tables
          end.not_to change { connection.select_value("SELECT count(*) from #{legacy_table}") }
        end

        it 'prints the truncation sql statement to the output' do
          expect do
            truncate_legacy_tables
          end.to output(/TRUNCATE TABLE #{legacy_table} RESTRICT/).to_stdout
        end
      end

      context 'when passing until_table parameter via environment variable' do
        before do
          stub_env('UNTIL_TABLE', legacy_table)
        end

        it 'sends the table name to TablesTruncate' do
          expect(Gitlab::Database::TablesTruncate).to receive(:new).with(
            database_name: database_name,
            min_batch_size: 5,
            logger: anything,
            dry_run: false,
            until_table: legacy_table
          ).and_call_original

          truncate_legacy_tables
        end
      end
    end
  end

  context 'when truncating ci tables on the main database' do
    subject(:truncate_legacy_tables) { run_rake_task('gitlab:db:truncate_legacy_tables:main') }

    let(:connection) { ApplicationRecord.connection }
    let(:database_name) { 'main' }
    let(:active_table) { test_gitlab_main_table }
    let(:legacy_table) { test_gitlab_ci_table }

    it_behaves_like 'truncating legacy tables'
  end

  context 'when truncating main tables on the ci database' do
    subject(:truncate_legacy_tables) { run_rake_task('gitlab:db:truncate_legacy_tables:ci') }

    let(:connection) { Ci::ApplicationRecord.connection }
    let(:database_name) { 'ci' }
    let(:active_table) { test_gitlab_ci_table }
    let(:legacy_table) { test_gitlab_main_table }

    it_behaves_like 'truncating legacy tables'
  end
end
