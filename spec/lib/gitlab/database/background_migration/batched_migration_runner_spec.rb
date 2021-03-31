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
        relation = Gitlab::Database::BackgroundMigration::BatchedMigration.finished.where(id: migration.id)

        expect { runner.run_migration_job(migration) }.to change { relation.count }.by(1)
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
        create(:batched_background_migration, :active, batch_size: 2, min_value: event1.id, max_value: event3.id)
      end

      let!(:previous_job) do
        create(:batched_background_migration_job,
          batched_migration: migration,
          min_value: event1.id,
          max_value: event2.id,
          batch_size: 2,
          sub_batch_size: 1)
      end

      let(:job_relation) do
        Gitlab::Database::BackgroundMigration::BatchedJob.where(batched_background_migration_id: migration.id)
      end

      context 'when the migration has batches to process' do
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

      context 'when the migration has no batches remaining' do
        before do
          create(:batched_background_migration_job,
            batched_migration: migration,
            min_value: event3.id,
            max_value: event3.id,
            batch_size: 2,
            sub_batch_size: 1)
        end

        it_behaves_like 'it has completed the migration'
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
        end

        expect(migration_wrapper).to receive(:perform) do |job_record|
          expect(job_record).to eq(job_relation.last)
        end

        expect { runner.run_entire_migration(migration) }.to change { job_relation.count }.by(2)

        expect(job_relation.first).to have_attributes(min_value: event1.id, max_value: event2.id)
        expect(job_relation.last).to have_attributes(min_value: event3.id, max_value: event3.id)

        expect(migration.reload).to be_finished
      end
    end
  end
end
