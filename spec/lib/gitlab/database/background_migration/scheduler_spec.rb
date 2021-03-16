# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::Scheduler, '#perform' do
  let(:scheduler) { described_class.new }

  shared_examples_for 'it has no jobs to run' do
    it 'does not create and run a migration job' do
      test_wrapper = double('test wrapper')

      expect(test_wrapper).not_to receive(:perform)

      expect do
        scheduler.perform(migration_wrapper: test_wrapper)
      end.not_to change { Gitlab::Database::BackgroundMigration::BatchedJob.count }
    end
  end

  context 'when there are no active migrations' do
    let!(:migration) { create(:batched_background_migration, :finished) }

    it_behaves_like 'it has no jobs to run'
  end

  shared_examples_for 'it has completed the migration' do
    it 'marks the migration as finished' do
      relation = Gitlab::Database::BackgroundMigration::BatchedMigration.finished.where(id: first_migration.id)

      expect { scheduler.perform }.to change { relation.count }.by(1)
    end
  end

  context 'when there are active migrations' do
    let!(:first_migration) { create(:batched_background_migration, :active, batch_size: 2) }
    let!(:last_migration) { create(:batched_background_migration, :active) }

    let(:job_relation) do
      Gitlab::Database::BackgroundMigration::BatchedJob.where(batched_background_migration_id: first_migration.id)
    end

    context 'when the migration interval has not elapsed' do
      before do
        expect_next_found_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigration) do |migration|
          expect(migration).to receive(:interval_elapsed?).and_return(false)
        end
      end

      it_behaves_like 'it has no jobs to run'
    end

    context 'when the interval has elapsed' do
      before do
        expect_next_found_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigration) do |migration|
          expect(migration).to receive(:interval_elapsed?).and_return(true)
        end
      end

      context 'when the first migration has no previous jobs' do
        context 'when the migration has batches to process' do
          let!(:event1) { create(:event) }
          let!(:event2) { create(:event) }
          let!(:event3) { create(:event) }

          it 'runs the job for the first batch' do
            first_migration.update!(min_value: event1.id, max_value: event3.id)

            expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper) do |wrapper|
              expect(wrapper).to receive(:perform).and_wrap_original do |_, job_record|
                expect(job_record).to eq(job_relation.first)
              end
            end

            expect { scheduler.perform }.to change { job_relation.count }.by(1)

            expect(job_relation.first).to have_attributes(
              min_value: event1.id,
              max_value: event2.id,
              batch_size: first_migration.batch_size,
              sub_batch_size: first_migration.sub_batch_size)
          end
        end

        context 'when the migration has no batches to process' do
          it_behaves_like 'it has no jobs to run'
          it_behaves_like 'it has completed the migration'
        end
      end

      context 'when the first migration has previous jobs' do
        let!(:event1) { create(:event) }
        let!(:event2) { create(:event) }
        let!(:event3) { create(:event) }

        let!(:previous_job) do
          create(:batched_background_migration_job,
            batched_migration: first_migration,
            min_value: event1.id,
            max_value: event2.id,
            batch_size: 2,
            sub_batch_size: 1)
        end

        context 'when the migration is ready to process another job' do
          it 'runs the migration job for the next batch' do
            first_migration.update!(min_value: event1.id, max_value: event3.id)

            expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper) do |wrapper|
              expect(wrapper).to receive(:perform).and_wrap_original do |_, job_record|
                expect(job_record).to eq(job_relation.last)
              end
            end

            expect { scheduler.perform }.to change { job_relation.count }.by(1)

            expect(job_relation.last).to have_attributes(
              min_value: event3.id,
              max_value: event3.id,
              batch_size: first_migration.batch_size,
              sub_batch_size: first_migration.sub_batch_size)
          end
        end

        context 'when the migration has no batches remaining' do
          let!(:final_job) do
            create(:batched_background_migration_job,
              batched_migration: first_migration,
              min_value: event3.id,
              max_value: event3.id,
              batch_size: 2,
              sub_batch_size: 1)
          end

          it_behaves_like 'it has no jobs to run'
          it_behaves_like 'it has completed the migration'
        end
      end

      context 'when the bounds of the next batch exceed the migration maximum value' do
        let!(:events) { create_list(:event, 3) }
        let(:event1) { events[0] }
        let(:event2) { events[1] }

        context 'when the batch maximum exceeds the migration maximum' do
          it 'clamps the batch maximum to the migration maximum' do
            first_migration.update!(batch_size: 5, min_value: event1.id, max_value: event2.id)

            expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper) do |wrapper|
              expect(wrapper).to receive(:perform)
            end

            expect { scheduler.perform }.to change { job_relation.count }.by(1)

            expect(job_relation.first).to have_attributes(
              min_value: event1.id,
              max_value: event2.id,
              batch_size: first_migration.batch_size,
              sub_batch_size: first_migration.sub_batch_size)
          end
        end

        context 'when the batch minimum exceeds the migration maximum' do
          let!(:previous_job) do
            create(:batched_background_migration_job,
              batched_migration: first_migration,
              min_value: event1.id,
              max_value: event2.id,
              batch_size: 5,
              sub_batch_size: 1)
          end

          before do
            first_migration.update!(batch_size: 5, min_value: 1, max_value: event2.id)
          end

          it_behaves_like 'it has no jobs to run'
          it_behaves_like 'it has completed the migration'
        end
      end
    end
  end
end
