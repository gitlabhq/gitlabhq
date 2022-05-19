# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  describe '#queue_batched_background_migration' do
    let(:pgclass_info) { instance_double('Gitlab::Database::PgClass', cardinality_estimate: 42) }

    before do
      allow(Gitlab::Database::PgClass).to receive(:for_table).and_call_original
    end

    context 'when such migration already exists' do
      it 'does not create duplicate migration' do
        create(
          :batched_background_migration,
          job_class_name: 'MyJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]]
        )

        expect do
          migration.queue_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            [:id], [:id_convert_to_bigint],
            job_interval: 5.minutes,
            batch_min_value: 5,
            batch_max_value: 1000,
            batch_class_name: 'MyBatchClass',
            batch_size: 100,
            sub_batch_size: 10)
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end

    it 'creates the database record for the migration' do
      expect(Gitlab::Database::PgClass).to receive(:for_table).with(:projects).and_return(pgclass_info)

      expect do
        migration.queue_batched_background_migration(
          'MyJobClass',
          :projects,
          :id,
          job_interval: 5.minutes,
          batch_min_value: 5,
          batch_max_value: 1000,
          batch_class_name: 'MyBatchClass',
          batch_size: 100,
          max_batch_size: 10000,
          sub_batch_size: 10)
      end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

      expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to have_attributes(
        job_class_name: 'MyJobClass',
        table_name: 'projects',
        column_name: 'id',
        interval: 300,
        min_value: 5,
        max_value: 1000,
        batch_class_name: 'MyBatchClass',
        batch_size: 100,
        max_batch_size: 10000,
        sub_batch_size: 10,
        job_arguments: %w[],
        status_name: :active,
        total_tuple_count: pgclass_info.cardinality_estimate)
    end

    context 'when the job interval is lower than the minimum' do
      let(:minimum_delay) { described_class::BATCH_MIN_DELAY }

      it 'sets the job interval to the minimum value' do
        expect do
          migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: minimum_delay - 1.minute)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

        expect(created_migration.interval).to eq(minimum_delay)
      end
    end

    context 'when additional arguments are passed to the method' do
      it 'saves the arguments on the database record' do
        expect do
          migration.queue_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            'my',
            'arguments',
            job_interval: 5.minutes,
            batch_max_value: 1000)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to have_attributes(
          job_class_name: 'MyJobClass',
          table_name: 'projects',
          column_name: 'id',
          interval: 300,
          min_value: 1,
          max_value: 1000,
          job_arguments: %w[my arguments])
      end
    end

    context 'when the max_value is not given' do
      context 'when records exist in the database' do
        let!(:event1) { create(:event) }
        let!(:event2) { create(:event) }
        let!(:event3) { create(:event) }

        it 'creates the record with the current max value' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(event3.id)
        end

        it 'creates the record with an active status' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_active
        end
      end

      context 'when the database is empty' do
        it 'sets the max value to the min value' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(created_migration.min_value)
        end

        it 'creates the record with a finished status' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :projects, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_finished
        end
      end
    end
  end

  describe '#finalize_batched_background_migration' do
    let!(:batched_migration) { create(:batched_background_migration, job_class_name: 'MyClass', table_name: :projects, column_name: :id, job_arguments: []) }

    it 'finalizes the migration' do
      allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
        expect(runner).to receive(:finalize).with('MyClass', :projects, :id, [])
      end

      migration.finalize_batched_background_migration(job_class_name: 'MyClass', table_name: :projects, column_name: :id, job_arguments: [])
    end

    context 'when the migration does not exist' do
      it 'raises an exception' do
        expect do
          migration.finalize_batched_background_migration(job_class_name: 'MyJobClass', table_name: :projects, column_name: :id, job_arguments: [])
        end.to raise_error(RuntimeError, 'Could not find batched background migration')
      end
    end
  end
end
