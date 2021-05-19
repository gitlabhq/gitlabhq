# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedJob, type: :model do
  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it { is_expected.to belong_to(:batched_migration).with_foreign_key(:batched_background_migration_id) }
  end

  describe 'scopes' do
    let_it_be(:fixed_time) { Time.new(2021, 04, 27, 10, 00, 00, 00) }

    let_it_be(:pending_job) { create(:batched_background_migration_job, status: :pending, updated_at: fixed_time) }
    let_it_be(:running_job) { create(:batched_background_migration_job, status: :running, updated_at: fixed_time) }
    let_it_be(:stuck_job) { create(:batched_background_migration_job, status: :pending, updated_at: fixed_time - described_class::STUCK_JOBS_TIMEOUT) }
    let_it_be(:failed_job) { create(:batched_background_migration_job, status: :failed, attempts: 1) }

    before_all do
      create(:batched_background_migration_job, status: :failed, attempts: described_class::MAX_ATTEMPTS)
      create(:batched_background_migration_job, status: :succeeded)
    end

    before do
      travel_to fixed_time
    end

    describe '.active' do
      it 'returns active jobs' do
        expect(described_class.active).to contain_exactly(pending_job, running_job, stuck_job)
      end
    end

    describe '.stuck' do
      it 'returns stuck jobs' do
        expect(described_class.stuck).to contain_exactly(stuck_job)
      end
    end

    describe '.retriable' do
      it 'returns retriable jobs' do
        expect(described_class.retriable).to contain_exactly(failed_job, stuck_job)
      end
    end
  end

  describe 'delegated batched_migration attributes' do
    let(:batched_job) { build(:batched_background_migration_job) }
    let(:batched_migration) { batched_job.batched_migration }

    describe '#migration_aborted?' do
      before do
        batched_migration.status = :aborted
      end

      it 'returns the migration aborted?' do
        expect(batched_job.migration_aborted?).to eq(batched_migration.aborted?)
      end
    end

    describe '#migration_job_class' do
      it 'returns the migration job_class' do
        expect(batched_job.migration_job_class).to eq(batched_migration.job_class)
      end
    end

    describe '#migration_table_name' do
      it 'returns the migration table_name' do
        expect(batched_job.migration_table_name).to eq(batched_migration.table_name)
      end
    end

    describe '#migration_column_name' do
      it 'returns the migration column_name' do
        expect(batched_job.migration_column_name).to eq(batched_migration.column_name)
      end
    end

    describe '#migration_job_arguments' do
      it 'returns the migration job_arguments' do
        expect(batched_job.migration_job_arguments).to eq(batched_migration.job_arguments)
      end
    end
  end

  describe '#time_efficiency' do
    subject { job.time_efficiency }

    let(:migration) { build(:batched_background_migration, interval: 120.seconds) }
    let(:job) { build(:batched_background_migration_job, status: :succeeded, batched_migration: migration) }

    context 'when job has not yet succeeded' do
      let(:job) { build(:batched_background_migration_job, status: :running) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when finished_at is not set' do
      it 'returns nil' do
        job.started_at = Time.zone.now

        expect(subject).to be_nil
      end
    end

    context 'when started_at is not set' do
      it 'returns nil' do
        job.finished_at = Time.zone.now

        expect(subject).to be_nil
      end
    end

    context 'when job has finished' do
      it 'returns ratio of duration to interval, here: 0.5' do
        freeze_time do
          job.started_at = Time.zone.now - migration.interval / 2
          job.finished_at = Time.zone.now

          expect(subject).to eq(0.5)
        end
      end

      it 'returns ratio of duration to interval, here: 1' do
        freeze_time do
          job.started_at = Time.zone.now - migration.interval
          job.finished_at = Time.zone.now

          expect(subject).to eq(1)
        end
      end
    end
  end
end
