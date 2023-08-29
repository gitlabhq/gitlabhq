# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::LockTablesWorker, feature_category: :cell do
  using RSpec::Parameterized::TableSyntax

  let(:worker) { described_class.new }
  let(:exception_class) { described_class::TableShouldNotBeLocked }

  describe '#perform' do
    context 'when running with single database' do # this covers both single-db and single-db-ci-connection cases
      before do
        skip_if_database_exists(:ci)
      end

      it 'skips executing the job' do
        expect do
          worker.perform('ci', %w[ci_pipelines])
        end.to raise_error(exception_class, 'GitLab is not running in multiple database mode')
      end
    end

    context 'when running in decomposed database' do
      before do
        skip_if_shared_database(:ci)
      end

      context 'when the table is wrong' do
        context 'when trying to lock tables on an unknown database' do
          it 'raises an exception' do
            expect do
              worker.perform('foobar', %w[ci_pipelines])
            end.to raise_error(exception_class, /does not support locking writes on tables/)
          end
        end

        context 'when trying to lock tables on the database that does not support locking' do
          it 'raises an exception' do
            expect do
              worker.perform('geo', %w[ci_pipelines]) # ci tables should be locked only on main
            end.to raise_error(exception_class, /does not support locking writes on tables/)
          end
        end

        context 'when trying to lock tables on the wrong database' do
          it 'raises an exception' do
            expect do
              worker.perform('ci', %w[ci_pipelines]) # ci tables should be locked only on main
            end.to raise_error(exception_class, "table 'ci_pipelines' should not be locked on the database 'ci'")
          end
        end

        context 'when trying to lock shared tables on the database' do
          it 'raises an exception' do
            expect do
              worker.perform('main', %w[loose_foreign_keys_deleted_records])
            end.to raise_error(exception_class, /should not be locked on the database 'main'/)
          end
        end
      end

      context 'when the table is correct' do
        context 'when the table is not locked for writes' do
          where(:database_name, :tables) do
            :ci   | %w[users namespaces]
            :main | %w[ci_pipelines ci_builds]
          end

          with_them do
            it 'locks the tables on the corresponding database' do
              tables.each do |table_name|
                unlock_table(database_name, table_name)
                expect(lock_writes_manager(database_name, table_name).table_locked_for_writes?).to eq(false)
              end

              expected_log_results = tables.map do |table_name|
                { action: "locked", database: database_name, dry_run: false, table: table_name }
              end
              expect(worker).to receive(:log_extra_metadata_on_done).with(:performed_actions, expected_log_results)

              worker.perform(database_name, tables)
              tables.each do |table_name|
                expect(lock_writes_manager(database_name, table_name).table_locked_for_writes?).to eq(true)
              end
            end
          end

          context 'when the table is already locked for writes' do
            where(:database_name, :tables) do
              :ci   | %w[users namespaces]
              :main | %w[ci_pipelines ci_builds]
            end

            with_them do
              it 'skips locking the tables on the corresponding database' do
                tables.each do |table_name|
                  lock_table(database_name, table_name)
                end

                expected_log_results = tables.map do |table_name|
                  { action: 'skipped', database: database_name, dry_run: false, table: table_name }
                end
                expect(worker).to receive(:log_extra_metadata_on_done).with(:performed_actions, expected_log_results)

                worker.perform(database_name, tables)
                tables.each do |table_name|
                  expect(lock_writes_manager(database_name, table_name).table_locked_for_writes?).to eq(true)
                end
              end
            end
          end
        end
      end
    end
  end

  def lock_table(database_name, table_name)
    lock_writes_manager(database_name, table_name).lock_writes
  end

  def unlock_table(database_name, table_name)
    lock_writes_manager(database_name, table_name).unlock_writes
  end

  def lock_writes_manager(database_name, table_name)
    connection = Gitlab::Database.database_base_models_with_gitlab_shared[database_name].connection
    Gitlab::Database::LockWritesManager.new(
      table_name: table_name,
      connection: connection,
      database_name: database_name,
      with_retries: false,
      dry_run: false
    )
  end
end
