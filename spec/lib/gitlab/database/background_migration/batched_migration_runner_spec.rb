# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigrationRunner, feature_category: :database do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }
  let(:migration_wrapper) { double('test wrapper') }

  let(:runner) { described_class.new(connection: connection, migration_wrapper: migration_wrapper) }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  before do
    normal_signal = instance_double(Gitlab::Database::HealthStatus::Signals::Normal, stop?: false)
    allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([normal_signal])
  end

  describe '#run_migration_job' do
    shared_examples_for 'it has completed the migration' do
      it 'does not create and run a migration job' do
        expect(migration_wrapper).not_to receive(:perform)

        expect do
          runner.run_migration_job(migration)
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedJob.count }
      end

      it 'marks the migration as finished' do
        runner.run_migration_job(migration)

        expect(migration.reload).to be_finished
      end
    end

    context 'when the migration has no previous jobs' do
      let(:migration) { create(:batched_background_migration, :active, batch_size: 2) }

      let(:job_relation) do
        Gitlab::Database::BackgroundMigration::BatchedJob.where(batched_background_migration_id: migration.id)
      end

      context 'when the migration has batches to process' do
        let!(:event1) { create(:event) }
        let!(:event2) { create(:event) }
        let!(:event3) { create(:event) }

        it 'runs the job for the first batch' do
          migration.update!(min_value: event1.id, max_value: event2.id)

          expect(migration_wrapper).to receive(:perform) do |job_record|
            expect(job_record).to eq(job_relation.first)
          end

          expect { runner.run_migration_job(migration) }.to change { job_relation.count }.by(1)

          expect(job_relation.first).to have_attributes(
            min_value: event1.id,
            max_value: event2.id,
            batch_size: migration.batch_size,
            sub_batch_size: migration.sub_batch_size)
        end

        context 'migration health' do
          let(:health_status) { Gitlab::Database::HealthStatus }
          let(:stop_signal) { health_status::Signals::Stop.new(:indicator, reason: 'Take a break') }
          let(:normal_signal) { health_status::Signals::Normal.new(:indicator, reason: 'All good') }
          let(:not_available_signal) { health_status::Signals::NotAvailable.new(:indicator, reason: 'Indicator is disabled') }
          let(:unknown_signal) { health_status::Signals::Unknown.new(:indicator, reason: 'Something went wrong') }

          before do
            migration.update!(min_value: event1.id, max_value: event2.id)
            expect(migration_wrapper).to receive(:perform)
          end

          it 'puts migration on hold on stop signal' do
            expect(health_status).to receive(:evaluate).and_return([stop_signal])

            expect { runner.run_migration_job(migration) }.to change { migration.on_hold? }
              .from(false).to(true)
          end

          it 'optimizes migration on normal signal' do
            expect(health_status).to receive(:evaluate).and_return([normal_signal])

            expect(migration).to receive(:optimize!)

            expect { runner.run_migration_job(migration) }.not_to change { migration.on_hold? }
          end

          it 'optimizes migration on no signal' do
            expect(health_status).to receive(:evaluate).and_return([not_available_signal])

            expect(migration).to receive(:optimize!)

            expect { runner.run_migration_job(migration) }.not_to change { migration.on_hold? }
          end

          it 'optimizes migration on unknown signal' do
            expect(health_status).to receive(:evaluate).and_return([unknown_signal])

            expect(migration).to receive(:optimize!)

            expect { runner.run_migration_job(migration) }.not_to change { migration.on_hold? }
          end
        end
      end

      context 'when the batch maximum exceeds the migration maximum' do
        let!(:events) { create_list(:event, 3) }
        let(:event1) { events[0] }
        let(:event2) { events[1] }

        it 'clamps the batch maximum to the migration maximum' do
          migration.update!(min_value: event1.id, max_value: event2.id, batch_size: 5)

          expect(migration_wrapper).to receive(:perform)

          expect { runner.run_migration_job(migration) }.to change { job_relation.count }.by(1)

          expect(job_relation.first).to have_attributes(
            min_value: event1.id,
            max_value: event2.id,
            batch_size: migration.batch_size,
            sub_batch_size: migration.sub_batch_size)
        end
      end

      context 'when the migration has no batches to process' do
        it_behaves_like 'it has completed the migration'
      end
    end

    context 'when the migration should stop' do
      let(:migration) { create(:batched_background_migration, :active) }

      let!(:job) { create(:batched_background_migration_job, :failed, batched_migration: migration) }

      it 'changes the status to failure' do
        expect(migration).to receive(:should_stop?).and_return(true)
        expect(migration_wrapper).to receive(:perform).and_return(job)

        expect { runner.run_migration_job(migration) }.to change { migration.status_name }.from(:active).to(:failed)
      end
    end

    context 'when the migration has previous jobs' do
      let!(:event1) { create(:event) }
      let!(:event2) { create(:event) }
      let!(:event3) { create(:event) }

      let!(:migration) do
        create(:batched_background_migration, :active, batch_size: 2, min_value: event1.id, max_value: event2.id)
      end

      let!(:previous_job) do
        create(:batched_background_migration_job, :succeeded,
          batched_migration: migration,
          min_value: event1.id,
          max_value: event2.id,
          batch_size: 2,
          sub_batch_size: 1
        )
      end

      let(:job_relation) do
        Gitlab::Database::BackgroundMigration::BatchedJob.where(batched_background_migration_id: migration.id)
      end

      context 'when the migration has no batches remaining' do
        it_behaves_like 'it has completed the migration'
      end

      context 'when the migration has batches to process' do
        before do
          migration.update!(max_value: event3.id)
        end

        it 'runs the migration job for the next batch' do
          expect(migration_wrapper).to receive(:perform) do |job_record|
            expect(job_record).to eq(job_relation.last)
          end

          expect { runner.run_migration_job(migration) }.to change { job_relation.count }.by(1)

          expect(job_relation.last).to have_attributes(
            min_value: event3.id,
            max_value: event3.id,
            batch_size: migration.batch_size,
            sub_batch_size: migration.sub_batch_size)
        end

        context 'when the batch minimum exceeds the migration maximum' do
          before do
            migration.update!(batch_size: 5, max_value: event2.id)
          end

          it_behaves_like 'it has completed the migration'
        end
      end

      context 'when migration has failed jobs' do
        before do
          previous_job.failure!
        end

        it 'retries the failed job' do
          expect(migration_wrapper).to receive(:perform) do |job_record|
            expect(job_record).to eq(previous_job)
          end

          expect { runner.run_migration_job(migration) }.to change { job_relation.count }.by(0)
        end

        context 'when failed job has reached the maximum number of attempts' do
          before do
            previous_job.update!(attempts: Gitlab::Database::BackgroundMigration::BatchedJob::MAX_ATTEMPTS)
          end

          it 'marks the migration as failed' do
            expect(migration_wrapper).not_to receive(:perform)

            expect { runner.run_migration_job(migration) }.to change { job_relation.count }.by(0)

            expect(migration).to be_failed
          end
        end
      end

      context 'when migration has stuck jobs' do
        before do
          previous_job.update!(status_event: 'run', updated_at: 1.hour.ago - Gitlab::Database::BackgroundMigration::BatchedJob::STUCK_JOBS_TIMEOUT)
        end

        it 'retries the stuck job' do
          expect(migration_wrapper).to receive(:perform) do |job_record|
            expect(job_record).to eq(previous_job)
          end

          expect { runner.run_migration_job(migration.reload) }.to change { job_relation.count }.by(0)
        end
      end

      context 'when migration has possible stuck jobs' do
        before do
          previous_job.update!(status_event: 'run', updated_at: 1.hour.from_now - Gitlab::Database::BackgroundMigration::BatchedJob::STUCK_JOBS_TIMEOUT)
        end

        it 'keeps the migration active' do
          expect(migration_wrapper).not_to receive(:perform)

          expect { runner.run_migration_job(migration) }.to change { job_relation.count }.by(0)

          expect(migration.reload).to be_active
        end
      end

      context 'when the migration has batches to process and failed jobs' do
        before do
          migration.update!(max_value: event3.id)
          previous_job.failure!
        end

        it 'runs next batch then retries the failed job' do
          expect(migration_wrapper).to receive(:perform) do |job_record|
            expect(job_record).to eq(job_relation.last)
            job_record.succeed!
          end

          expect { runner.run_migration_job(migration) }.to change { job_relation.count }.by(1)

          expect(migration_wrapper).to receive(:perform) do |job_record|
            expect(job_record).to eq(previous_job)
          end

          expect { runner.run_migration_job(migration.reload) }.to change { job_relation.count }.by(0)
        end
      end
    end
  end

  describe '#run_entire_migration' do
    context 'when not in a development or test environment' do
      it 'raises an error' do
        environment = double('environment', development?: false, test?: false)
        migration = build(:batched_background_migration, :finished)

        allow(Rails).to receive(:env).and_return(environment)

        expect do
          runner.run_entire_migration(migration)
        end.to raise_error('this method is not intended for use in real environments')
      end
    end

    context 'when the given migration is not active' do
      it 'does not create and run migration jobs' do
        migration = build(:batched_background_migration, :finished)

        expect(migration_wrapper).not_to receive(:perform)

        expect do
          runner.run_entire_migration(migration)
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedJob.count }
      end
    end

    context 'when the given migration is active' do
      let!(:event1) { create(:event) }
      let!(:event2) { create(:event) }
      let!(:event3) { create(:event) }

      let!(:migration) do
        create(:batched_background_migration, :active, batch_size: 2, min_value: event1.id, max_value: event3.id)
      end

      let(:job_relation) do
        Gitlab::Database::BackgroundMigration::BatchedJob.where(batched_background_migration_id: migration.id)
      end

      it 'runs all jobs inline until finishing the migration' do
        expect(migration_wrapper).to receive(:perform) do |job_record|
          expect(job_record).to eq(job_relation.first)
          job_record.succeed!
        end

        expect(migration_wrapper).to receive(:perform) do |job_record|
          expect(job_record).to eq(job_relation.last)
          job_record.succeed!
        end

        expect { runner.run_entire_migration(migration) }.to change { job_relation.count }.by(2)

        expect(job_relation.first).to have_attributes(min_value: event1.id, max_value: event2.id)
        expect(job_relation.last).to have_attributes(min_value: event3.id, max_value: event3.id)

        expect(migration.reload).to be_finished
      end
    end
  end

  describe '#finalize' do
    let(:migration_wrapper) do
      Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper.new(connection: connection)
    end

    let(:migration_helpers) { ActiveRecord::Migration.new }
    let(:table_name) { :_test_batched_migrations_test_table }
    let(:column_name) { :some_id }
    let(:job_arguments) { [:some_id, :some_id_convert_to_bigint] }
    let(:gitlab_schemas) { Gitlab::Database.gitlab_schemas_for_connection(connection) }

    let(:migration_status) { :active }

    let!(:batched_migration) do
      create(
        :batched_background_migration, migration_status,
        max_value: 8,
        batch_size: 2,
        sub_batch_size: 1,
        interval: 0,
        table_name: table_name,
        column_name: column_name,
        job_arguments: job_arguments,
        pause_ms: 0
      )
    end

    before do
      migration_helpers.drop_table table_name, if_exists: true
      migration_helpers.create_table table_name, id: false do |t|
        t.integer :some_id, primary_key: true
        t.integer :some_id_convert_to_bigint
      end

      migration_helpers.execute("INSERT INTO #{table_name} VALUES (1, 1), (2, 2), (3, NULL), (4, NULL), (5, NULL), (6, NULL), (7, NULL), (8, NULL)")
    end

    after do
      migration_helpers.drop_table table_name, if_exists: true
    end

    context 'when the migration is not yet completed' do
      before do
        common_attributes = {
          batched_migration: batched_migration,
          batch_size: 2,
          sub_batch_size: 1,
          pause_ms: 0
        }

        create(:batched_background_migration_job, :succeeded, common_attributes.merge(min_value: 1, max_value: 2))
        create(:batched_background_migration_job, :pending, common_attributes.merge(min_value: 3, max_value: 4))
        create(:batched_background_migration_job, :failed, common_attributes.merge(min_value: 5, max_value: 6, attempts: 1))
      end

      it 'completes the migration' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_for_configuration)
          .with(gitlab_schemas, 'CopyColumnUsingBackgroundMigrationJob', table_name, column_name, job_arguments)
          .and_return(batched_migration)

        expect(batched_migration).to receive(:reset_attempts_of_blocked_jobs!).and_call_original

        expect(batched_migration).to receive(:finalize!).and_call_original

        expect do
          runner.finalize(
            batched_migration.job_class_name,
            table_name,
            column_name,
            job_arguments
          )
        end.to change { batched_migration.reload.status_name }.from(:active).to(:finished)

        expect(batched_migration.batched_jobs).to all(be_succeeded)

        not_converted = migration_helpers.execute("SELECT * FROM #{table_name} WHERE some_id_convert_to_bigint IS NULL")
        expect(not_converted.to_a).to be_empty
      end

      context 'when migration fails to complete' do
        let(:error_message) do
          "Batched migration #{batched_migration.job_class_name} could not be completed and a manual action is required."\
          "Check the admin panel at (`/admin/background_migrations`) for more details."
        end

        it 'raises an error' do
          allow(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_for_configuration).and_return(batched_migration)

          allow(batched_migration).to receive(:finished?).and_return(false)

          expect do
            runner.finalize(
              batched_migration.job_class_name,
              table_name,
              column_name,
              job_arguments
            )
          end.to raise_error(described_class::FailedToFinalize, error_message)
        end
      end
    end

    context 'when the migration is already finished' do
      let(:migration_status) { :finished }

      it 'is a no-op' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_for_configuration)
          .with(gitlab_schemas, 'CopyColumnUsingBackgroundMigrationJob', table_name, column_name, job_arguments)
          .and_return(batched_migration)

        configuration = {
          job_class_name: batched_migration.job_class_name,
          table_name: table_name.to_sym,
          column_name: column_name.to_sym,
          job_arguments: job_arguments
        }

        expect(Gitlab::AppLogger).to receive(:warn)
          .with("Batched background migration for the given configuration is already finished: #{configuration}")

        expect(batched_migration).not_to receive(:finalize!)

        runner.finalize(
          batched_migration.job_class_name,
          table_name,
          column_name,
          job_arguments
        )
      end
    end

    context 'when the migration does not exist' do
      it 'is a no-op' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_for_configuration)
          .with(gitlab_schemas, 'CopyColumnUsingBackgroundMigrationJob', table_name, column_name, [:some, :other, :arguments])
          .and_return(nil)

        configuration = {
          job_class_name: batched_migration.job_class_name,
          table_name: table_name.to_sym,
          column_name: column_name.to_sym,
          job_arguments: [:some, :other, :arguments]
        }

        expect(Gitlab::AppLogger).to receive(:warn)
          .with("Could not find batched background migration for the given configuration: #{configuration}")

        expect(batched_migration).not_to receive(:finalize!)

        runner.finalize(
          batched_migration.job_class_name,
          table_name,
          column_name,
          [:some, :other, :arguments]
        )
      end
    end
  end

  describe '.finalize' do
    context 'when the connection is passed' do
      let(:table_name) { :_test_batched_migrations_test_table }
      let(:column_name) { :some_id }
      let(:job_arguments) { [:some, :other, :arguments] }
      let(:batched_migration) { create(:batched_background_migration, table_name: table_name, column_name: column_name) }

      it 'initializes the object with the given connection' do
        expect(described_class).to receive(:new).with(connection: connection).and_call_original

        described_class.finalize(
          batched_migration.job_class_name,
          table_name,
          column_name,
          job_arguments,
          connection: connection
        )
      end
    end
  end
end
