# frozen_string_literal: true

RSpec.shared_examples 'batched background migrations execution worker' do
  include ExclusiveLeaseHelpers

  before do
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
  end

  it 'is a limited capacity worker' do
    expect(described_class.new).to be_a(LimitedCapacity::Worker)
  end

  describe 'defining the job attributes' do
    it 'defines the data_consistency as always' do
      expect(described_class.get_data_consistency_per_database.values.uniq).to eq([:always])
    end

    it 'defines the feature_category as database' do
      expect(described_class.get_feature_category).to eq(:database)
    end

    it 'defines the idempotency as false' do
      expect(described_class).not_to be_idempotent
    end

    it 'does not retry failed jobs' do
      expect(described_class.sidekiq_options['retry']).to eq(0)
    end

    it 'does not deduplicate jobs' do
      expect(described_class.get_deduplicate_strategy).to eq(:none)
    end

    it 'defines the queue namespace' do
      expect(described_class.queue_namespace).to eq('batched_background_migrations')
    end
  end

  describe '.perform_with_capacity' do
    it 'enqueues jobs without modifying provided arguments' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:remove_failed_jobs)
      end

      args = [['main', 123]]

      expect(described_class)
        .to receive(:bulk_perform_async)
        .with(args)

      described_class.perform_with_capacity(args)
    end
  end

  describe '.max_running_jobs' do
    it 'returns database_max_running_batched_background_migrations application setting' do
      stub_application_setting(database_max_running_batched_background_migrations: 3)

      expect(described_class.max_running_jobs)
        .to eq(Gitlab::CurrentSettings.database_max_running_batched_background_migrations)
    end
  end

  describe '#max_running_jobs' do
    it 'returns database_max_running_batched_background_migrations application setting' do
      stub_application_setting(database_max_running_batched_background_migrations: 3)

      expect(described_class.new.max_running_jobs)
        .to eq(Gitlab::CurrentSettings.database_max_running_batched_background_migrations)
    end
  end

  describe '#remaining_work_count' do
    it 'returns 0' do
      expect(described_class.new.remaining_work_count).to eq(0)
    end
  end

  describe '#perform_work' do
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

        worker.perform_work(database_name, migration.id)
      end
    end

    context 'when disable ddl flag is enabled' do
      let(:migration) do
        create(:batched_background_migration, :active, interval: job_interval, table_name: table_name)
      end

      before do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)
      end

      it 'does nothing' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigration).not_to receive(:find_executable)
        expect(worker).not_to receive(:run_migration_job)

        worker.perform_work(database_name, migration.id)
      end
    end

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(execute_batched_migrations_on_schedule: true)
      end

      context 'when the provided database is sharing config' do
        before do
          skip_if_multiple_databases_not_setup(:ci)
        end

        it 'does nothing' do
          ci_model = Gitlab::Database.database_base_models['ci']
          expect(Gitlab::Database).to receive(:db_config_share_with)
            .with(ci_model.connection_db_config).and_return('main')

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration).not_to receive(:find_executable)
          expect(worker).not_to receive(:run_migration_job)

          worker.perform_work(:ci, 123)
        end
      end

      context 'when migration does not exist' do
        it 'does nothing' do
          expect(worker).not_to receive(:run_migration_job)

          worker.perform_work(database_name, non_existing_record_id)
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

            worker.perform_work(database_name, migration.id)
          end
        end

        context 'when the interval has not elapsed' do
          it 'does not run the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield
            expect(migration).to receive(:interval_elapsed?).with(variance: interval_variance).and_return(false)
            expect(worker).not_to receive(:run_migration_job)

            worker.perform_work(database_name, migration.id)
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

              worker.perform_work(database_name, migration.id)
            end
          end

          it 'always cleans up the exclusive lease' do
            expect_to_obtain_exclusive_lease(table_name_lease_key, 'uuid-table-name', timeout: lease_timeout)
            expect_to_cancel_exclusive_lease(table_name_lease_key, 'uuid-table-name')

            expect(worker).to receive(:run_migration_job).and_raise(RuntimeError, 'I broke')

            expect { worker.perform_work(database_name, migration.id) }.to raise_error(RuntimeError, 'I broke')
          end

          it 'runs the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

            expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |instance|
              expect(instance).to receive(:run_migration_job).with(migration)
            end

            expect_to_obtain_exclusive_lease(table_name_lease_key, 'uuid-table-name', timeout: lease_timeout)
            expect_to_cancel_exclusive_lease(table_name_lease_key, 'uuid-table-name')

            expect(worker).to receive(:run_migration_job).and_call_original

            worker.perform_work(database_name, migration.id)
          end

          it 'assigns proper feature category to the context and the worker' do
            # max_value is set to create and execute a batched_job, where we fetch feature_category from the job_class
            migration.update!(max_value: create(:event).id)
            expect(migration.job_class).to receive(:feature_category).and_return(:code_review_workflow)

            allow_next_instance_of(migration.job_class) do |job_class|
              allow(job_class).to receive(:perform)
            end

            expect { worker.perform_work(database_name, migration.id) }.to change {
              Gitlab::ApplicationContext.current["meta.feature_category"]
            }.to('code_review_workflow')
              .and change { described_class.get_feature_category }.from(:database).to('code_review_workflow')
          end
        end
      end
    end
  end
end
