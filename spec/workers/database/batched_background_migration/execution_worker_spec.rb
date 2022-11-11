# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigration::ExecutionWorker, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let(:database_name) { Gitlab::Database::MAIN_DATABASE_NAME.to_sym }
    let(:base_model) { Gitlab::Database.database_base_models[database_name] }
    let(:table_name) { :events }
    let(:job_interval) { 5.minutes }
    let(:lease_timeout) { job_interval * described_class::LEASE_TIMEOUT_MULTIPLIER }
    let(:interval_variance) { described_class::INTERVAL_VARIANCE }

    subject(:worker) { described_class.new }

    context 'when the feature flag is disabled' do
      let(:migration) do
        create(:batched_background_migration, :active, interval: job_interval, table_name: table_name)
      end

      before do
        stub_feature_flags(execute_batched_migrations_on_schedule: false)
      end

      it 'does nothing' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigration).not_to receive(:find_executable)
        expect(worker).not_to receive(:run_migration_job)

        worker.perform(database_name, migration.id)
      end
    end

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(execute_batched_migrations_on_schedule: true)
      end

      context 'when the provided database is sharing config' do
        it 'does nothing' do
          ci_model = Gitlab::Database.database_base_models['ci']
          expect(Gitlab::Database).to receive(:db_config_share_with)
            .with(ci_model.connection_db_config).and_return('main')

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration).not_to receive(:find_executable)
          expect(worker).not_to receive(:run_migration_job)

          worker.perform(:ci, 123)
        end
      end

      context 'when migration does not exist' do
        it 'does nothing' do
          expect(worker).not_to receive(:run_migration_job)

          worker.perform(database_name, non_existing_record_id)
        end
      end

      context 'when migration exist' do
        let(:migration) do
          create(:batched_background_migration, :active, interval: job_interval, table_name: table_name)
        end

        before do
          allow(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_executable)
            .with(migration.id, connection: base_model.connection)
            .and_return(migration)
        end

        context 'when the migration is no longer active' do
          it 'does not run the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

            expect(migration).to receive(:active?).and_return(false)

            expect(worker).not_to receive(:run_migration_job)

            worker.perform(database_name, migration.id)
          end
        end

        context 'when the interval has not elapsed' do
          it 'does not run the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield
            expect(migration).to receive(:interval_elapsed?).with(variance: interval_variance).and_return(false)
            expect(worker).not_to receive(:run_migration_job)

            worker.perform(database_name, migration.id)
          end
        end

        context 'when the migration is still active and the interval has elapsed' do
          let(:table_name_lease_key) do
            "#{described_class.name.underscore}:database_name:#{database_name}:" \
              "table_name:#{table_name}"
          end

          context 'when can not obtain lease on the table name' do
            it 'does nothing' do
              stub_exclusive_lease_taken(table_name_lease_key, timeout: lease_timeout)

              expect(worker).not_to receive(:run_migration_job)

              worker.perform(database_name, migration.id)
            end
          end

          it 'always cleans up the exclusive lease' do
            expect_to_obtain_exclusive_lease(table_name_lease_key, 'uuid-table-name', timeout: lease_timeout)
            expect_to_cancel_exclusive_lease(table_name_lease_key, 'uuid-table-name')

            expect(worker).to receive(:run_migration_job).and_raise(RuntimeError, 'I broke')

            expect { worker.perform(database_name, migration.id) }.to raise_error(RuntimeError, 'I broke')
          end

          it 'runs the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

            expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |instance|
              expect(instance).to receive(:run_migration_job).with(migration)
            end

            expect_to_obtain_exclusive_lease(table_name_lease_key, 'uuid-table-name', timeout: lease_timeout)
            expect_to_cancel_exclusive_lease(table_name_lease_key, 'uuid-table-name')

            expect(worker).to receive(:run_migration_job).and_call_original

            worker.perform(database_name, migration.id)
          end
        end
      end
    end
  end
end
