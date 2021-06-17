# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigrationRunner do
  let(:migration_wrapper) { double('test wrapper') }
  let(:runner) { described_class.new(migration_wrapper) }

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

        it 'optimizes the migration after executing the job' do
          migration.update!(min_value: event1.id, max_value: event2.id)

          expect(migration_wrapper).to receive(:perform).ordered
          expect(migration).to receive(:optimize!).ordered

          runner.run_migration_job(migration)
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

    context 'when the migration has previous jobs' do
      let!(:event1) { create(:event) }
      let!(:event2) { create(:event) }
      let!(:event3) { create(:event) }

      let!(:migration) do
        create(:batched_background_migration, :active, batch_size: 2, min_value: event1.id, max_value: event2.id)
      end

      let!(:previous_job) do
        create(:batched_background_migration_job,
          batched_migration: migration,
          min_value: event1.id,
          max_value: event2.id,
          batch_size: 2,
          sub_batch_size: 1,
          status: :succeeded
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
          previous_job.update!(status: :failed)
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
          previous_job.update!(status: :running, updated_at: 1.hour.ago - Gitlab::Database::BackgroundMigration::BatchedJob::STUCK_JOBS_TIMEOUT)
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
          previous_job.update!(status: :running, updated_at: 1.hour.from_now - Gitlab::Database::BackgroundMigration::BatchedJob::STUCK_JOBS_TIMEOUT)
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
          previous_job.update!(status: :failed)
        end

        it 'runs next batch then retries the failed job' do
          expect(migration_wrapper).to receive(:perform) do |job_record|
            expect(job_record).to eq(job_relation.last)
            job_record.update!(status: :succeeded)
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
          job_record.update!(status: :succeeded)
        end

        expect(migration_wrapper).to receive(:perform) do |job_record|
          expect(job_record).to eq(job_relation.last)
          job_record.update!(status: :succeeded)
        end

        expect { runner.run_entire_migration(migration) }.to change { job_relation.count }.by(2)

        expect(job_relation.first).to have_attributes(min_value: event1.id, max_value: event2.id)
        expect(job_relation.last).to have_attributes(min_value: event3.id, max_value: event3.id)

        expect(migration.reload).to be_finished
      end
    end
  end

  describe '#finalize' do
    let(:migration_wrapper) { Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper.new }

    let(:migration_helpers) { ActiveRecord::Migration.new }
    let(:table_name) { :_batched_migrations_test_table }
    let(:column_name) { :some_id }
    let(:job_arguments) { [:some_id, :some_id_convert_to_bigint] }

    let(:migration_status) { :active }

    let!(:batched_migration) do
      create(
        :batched_background_migration,
        status: migration_status,
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

        create(:batched_background_migration_job, common_attributes.merge(status: :succeeded, min_value: 1, max_value: 2))
        create(:batched_background_migration_job, common_attributes.merge(status: :pending, min_value: 3, max_value: 4))
        create(:batched_background_migration_job, common_attributes.merge(status: :failed, min_value: 5, max_value: 6, attempts: 1))
      end

      it 'completes the migration' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_for_configuration)
          .with('CopyColumnUsingBackgroundMigrationJob', table_name, column_name, job_arguments)
          .and_return(batched_migration)

        expect(batched_migration).to receive(:finalizing!).and_call_original

        expect do
          runner.finalize(
            batched_migration.job_class_name,
            table_name,
            column_name,
            job_arguments
          )
        end.to change { batched_migration.reload.status }.from('active').to('finished')

        expect(batched_migration.batched_jobs).to all(be_succeeded)

        not_converted = migration_helpers.execute("SELECT * FROM #{table_name} WHERE some_id_convert_to_bigint IS NULL")
        expect(not_converted.to_a).to be_empty
      end

      context 'when migration fails to complete' do
        it 'raises an error' do
          batched_migration.batched_jobs.failed.update_all(attempts: Gitlab::Database::BackgroundMigration::BatchedJob::MAX_ATTEMPTS)

          expect do
            runner.finalize(
              batched_migration.job_class_name,
              table_name,
              column_name,
              job_arguments
            )
          end.to raise_error described_class::FailedToFinalize
        end
      end
    end

    context 'when the migration is already finished' do
      let(:migration_status) { :finished }

      it 'is a no-op' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_for_configuration)
          .with('CopyColumnUsingBackgroundMigrationJob', table_name, column_name, job_arguments)
          .and_return(batched_migration)

        configuration = {
          job_class_name: batched_migration.job_class_name,
          table_name: table_name.to_sym,
          column_name: column_name.to_sym,
          job_arguments: job_arguments
        }

        expect(Gitlab::AppLogger).to receive(:warn)
          .with("Batched background migration for the given configuration is already finished: #{configuration}")

        expect(batched_migration).not_to receive(:finalizing!)

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
          .with('CopyColumnUsingBackgroundMigrationJob', table_name, column_name, [:some, :other, :arguments])
          .and_return(nil)

        configuration = {
          job_class_name: batched_migration.job_class_name,
          table_name: table_name.to_sym,
          column_name: column_name.to_sym,
          job_arguments: [:some, :other, :arguments]
        }

        expect(Gitlab::AppLogger).to receive(:warn)
          .with("Could not find batched background migration for the given configuration: #{configuration}")

        expect(batched_migration).not_to receive(:finalizing!)

        runner.finalize(
          batched_migration.job_class_name,
          table_name,
          column_name,
          [:some, :other, :arguments]
        )
      end
    end
  end
end
