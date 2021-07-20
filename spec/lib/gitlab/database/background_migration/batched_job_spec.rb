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

  describe '#split_and_retry!' do
    let!(:job) { create(:batched_background_migration_job, batch_size: 10, min_value: 6, max_value: 15, status: :failed, attempts: 3) }

    context 'when job can be split' do
      before do
        allow_next_instance_of(Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy) do |batch_class|
          allow(batch_class).to receive(:next_batch).with(anything, anything, batch_min_value: 6, batch_size: 5).and_return([6, 10])
        end
      end

      it 'sets the correct attributes' do
        expect { job.split_and_retry! }.to change { described_class.count }.by(1)

        expect(job).to have_attributes(
          min_value: 6,
          max_value: 10,
          batch_size: 5,
          status: 'failed',
          attempts: 0,
          started_at: nil,
          finished_at: nil,
          metrics: {}
        )

        new_job = described_class.last

        expect(new_job).to have_attributes(
          batched_background_migration_id: job.batched_background_migration_id,
          min_value: 11,
          max_value: 15,
          batch_size: 5,
          status: 'failed',
          attempts: 0,
          started_at: nil,
          finished_at: nil,
          metrics: {}
        )
        expect(new_job.created_at).not_to eq(job.created_at)
      end

      it 'splits the jobs into retriable jobs' do
        migration = job.batched_migration

        expect { job.split_and_retry! }.to change { migration.batched_jobs.retriable.count }.from(0).to(2)
      end
    end

    context 'when job is not failed' do
      let!(:job) { create(:batched_background_migration_job, status: :succeeded) }

      it 'raises an exception' do
        expect { job.split_and_retry! }.to raise_error 'Only failed jobs can be split'
      end
    end

    context 'when batch size is already 1' do
      let!(:job) { create(:batched_background_migration_job, batch_size: 1, status: :failed) }

      it 'raises an exception' do
        expect { job.split_and_retry! }.to raise_error 'Job cannot be split further'
      end
    end

    context 'when computed midpoint is larger than the max value of the batch' do
      before do
        allow_next_instance_of(Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy) do |batch_class|
          allow(batch_class).to receive(:next_batch).with(anything, anything, batch_min_value: 6, batch_size: 5).and_return([6, 16])
        end
      end

      it 'lowers the batch size and resets the number of attempts' do
        expect { job.split_and_retry! }.not_to change { described_class.count }

        expect(job.batch_size).to eq(5)
        expect(job.attempts).to eq(0)
        expect(job.status).to eq('failed')
      end
    end
  end
end
