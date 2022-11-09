# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedJob, type: :model do
  it_behaves_like 'having unique enum values'

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  specify do
    expect(described_class::TIMEOUT_EXCEPTIONS).to contain_exactly(
      ActiveRecord::StatementTimeout,
      ActiveRecord::ConnectionTimeoutError,
      ActiveRecord::AdapterTimeout,
      ActiveRecord::LockWaitTimeout,
      ActiveRecord::QueryCanceled
    )
  end

  describe 'associations' do
    it { is_expected.to belong_to(:batched_migration).with_foreign_key(:batched_background_migration_id) }
    it { is_expected.to have_many(:batched_job_transition_logs).with_foreign_key(:batched_background_migration_job_id) }
  end

  describe 'state machine' do
    let_it_be(:job) { create(:batched_background_migration_job, :failed) }

    it { expect(described_class.state_machine.states.map(&:name)).to eql(%i(pending running failed succeeded)) }

    context 'when a job is running' do
      it 'logs the transition' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            batched_job_id: job.id,
            batched_migration_id: job.batched_background_migration_id,
            exception_class: nil,
            exception_message: nil,
            job_arguments: job.batched_migration.job_arguments,
            job_class_name: job.batched_migration.job_class_name,
            message: 'BatchedJob transition',
            new_state: :running,
            previous_state: :failed
          }
        )

        expect { job.run! }.to change(job, :started_at)
      end
    end

    context 'when a job succeed' do
      let(:job) { create(:batched_background_migration_job, :running) }

      it 'logs the transition' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            batched_job_id: job.id,
            batched_migration_id: job.batched_background_migration_id,
            exception_class: nil,
            exception_message: nil,
            job_arguments: job.batched_migration.job_arguments,
            job_class_name: job.batched_migration.job_class_name,
            message: 'BatchedJob transition',
            new_state: :succeeded,
            previous_state: :running
          }
        )

        job.succeed!
      end

      it 'updates the finished_at' do
        expect { job.succeed! }.to change(job, :finished_at).from(nil).to(Time)
      end

      it 'creates a new transition log' do
        job.succeed!

        transition_log = job.batched_job_transition_logs.first

        expect(transition_log.next_status).to eq('succeeded')
        expect(transition_log.exception_class).to be_nil
        expect(transition_log.exception_message).to be_nil
      end
    end

    context 'when a job fails the number of max times' do
      let(:max_times) { described_class::MAX_ATTEMPTS }
      let!(:job) { create(:batched_background_migration_job, :running, batch_size: 10, min_value: 6, max_value: 15, attempts: max_times) }

      context 'when job can be split' do
        let(:exception) { ActiveRecord::StatementTimeout.new('Timeout!') }

        before do
          allow_next_instance_of(Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy) do |batch_class|
            allow(batch_class).to receive(:next_batch).and_return([6, 10])
          end
        end

        it 'splits the job into two retriable jobs' do
          expect { job.failure!(error: exception) }.to change { job.batched_migration.batched_jobs.retriable.count }.from(0).to(2)
        end
      end

      context 'when the job cannot be split' do
        let(:exception) { ActiveRecord::StatementTimeout.new('Timeout!') }
        let(:max_times) { described_class::MAX_ATTEMPTS }
        let!(:job) { create(:batched_background_migration_job, :running, batch_size: 50, sub_batch_size: 20, min_value: 6, max_value: 15, attempts: max_times) }
        let(:error_message) { 'Job cannot be split further' }
        let(:split_and_retry_exception) { Gitlab::Database::BackgroundMigration::SplitAndRetryError.new(error_message) }

        before do
          allow(job).to receive(:split_and_retry!).and_raise(split_and_retry_exception)
        end

        it 'does not split the job' do
          expect { job.failure!(error: exception) }.not_to change { job.batched_migration.batched_jobs.retriable.count }
        end

        it 'keeps the same job attributes' do
          expect { job.failure!(error: exception) }.not_to change { job }
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error).with(
            {
              batched_job_id: job.id,
              batched_migration_id: job.batched_background_migration_id,
              job_arguments: job.batched_migration.job_arguments,
              job_class_name: job.batched_migration.job_class_name,
              message: error_message
            }
          )

          job.failure!(error: exception)
        end
      end
    end

    context 'when a job fails' do
      let(:job) { create(:batched_background_migration_job, :running) }

      it 'logs the transition' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            batched_job_id: job.id,
            batched_migration_id: job.batched_background_migration_id,
            exception_class: RuntimeError,
            exception_message: 'error',
            job_arguments: job.batched_migration.job_arguments,
            job_class_name: job.batched_migration.job_class_name,
            message: 'BatchedJob transition',
            new_state: :failed,
            previous_state: :running
          }
        )

        job.failure!(error: RuntimeError.new('error'))
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          RuntimeError,
          {
            batched_job_id: job.id,
            job_arguments: job.batched_migration.job_arguments,
            job_class_name: job.batched_migration.job_class_name
          }
        )

        job.failure!(error: RuntimeError.new)
      end

      it 'updates the finished_at' do
        expect { job.failure! }.to change(job, :finished_at).from(nil).to(Time)
      end

      it 'creates a new transition log' do
        job.failure!(error: RuntimeError.new)

        transition_log = job.batched_job_transition_logs.first

        expect(transition_log.next_status).to eq('failed')
        expect(transition_log.exception_class).to eq('RuntimeError')
        expect(transition_log.exception_message).to eq('RuntimeError')
      end
    end
  end

  describe 'scopes' do
    let_it_be(:fixed_time) { Time.new(2021, 04, 27, 10, 00, 00, 00) }

    let_it_be(:pending_job) { create(:batched_background_migration_job, :pending, created_at: fixed_time - 2.days, updated_at: fixed_time) }
    let_it_be(:running_job) { create(:batched_background_migration_job, :running, created_at: fixed_time - 2.days, updated_at: fixed_time) }
    let_it_be(:stuck_job) { create(:batched_background_migration_job, :pending, created_at: fixed_time, updated_at: fixed_time - described_class::STUCK_JOBS_TIMEOUT) }
    let_it_be(:failed_job) { create(:batched_background_migration_job, :failed, created_at: fixed_time, attempts: 1) }
    let_it_be(:max_attempts_failed_job) { create(:batched_background_migration_job, :failed, created_at: fixed_time, attempts: described_class::MAX_ATTEMPTS) }

    before do
      travel_to fixed_time
    end

    describe '.except_succeeded' do
      it 'returns not succeeded jobs' do
        expect(described_class.except_succeeded).to contain_exactly(pending_job, running_job, stuck_job, failed_job, max_attempts_failed_job)
      end
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

    describe '.created_since' do
      it 'returns jobs since a given time' do
        expect(described_class.created_since(fixed_time)).to contain_exactly(stuck_job, failed_job, max_attempts_failed_job)
      end
    end

    describe '.blocked_by_max_attempts' do
      it 'returns blocked jobs' do
        expect(described_class.blocked_by_max_attempts).to contain_exactly(max_attempts_failed_job)
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

    describe '#migration_job_class_name' do
      it 'returns the migration job_class_name' do
        expect(batched_job.migration_job_class_name).to eq(batched_migration.job_class_name)
      end
    end
  end

  describe '#can_split?' do
    subject { job.can_split?(exception) }

    context 'when the number of attempts is greater than the limit and the batch_size is greater than the sub_batch_size' do
      let(:job) { create(:batched_background_migration_job, :failed, batch_size: 4, sub_batch_size: 2, attempts: described_class::MAX_ATTEMPTS + 1) }

      context 'when is a timeout exception' do
        let(:exception) { ActiveRecord::StatementTimeout.new }

        it { expect(subject).to be_truthy }
      end

      context 'when is a QueryCanceled exception' do
        let(:exception) { ActiveRecord::QueryCanceled.new }

        it { expect(subject).to be_truthy }
      end

      context 'when is not a timeout exception' do
        let(:exception) { RuntimeError.new }

        it { expect(subject).to be_falsey }
      end
    end

    context 'when the number of attempts is lower than the limit and the batch_size is greater than the sub_batch_size' do
      let(:job) { create(:batched_background_migration_job, :failed, batch_size: 4, sub_batch_size: 2, attempts: described_class::MAX_ATTEMPTS - 1) }

      context 'when is a timeout exception' do
        let(:exception) { ActiveRecord::StatementTimeout.new }

        it { expect(subject).to be_falsey }
      end

      context 'when is not a timeout exception' do
        let(:exception) { RuntimeError.new }

        it { expect(subject).to be_falsey }
      end
    end

    context 'when the batch_size is lower than the sub_batch_size' do
      let(:job) { create(:batched_background_migration_job, :failed, batch_size: 2, sub_batch_size: 4) }
      let(:exception) { ActiveRecord::StatementTimeout.new }

      it { expect(subject).to be_falsey }
    end

    context 'when the batch_size is 1' do
      let(:job) { create(:batched_background_migration_job, :failed, batch_size: 1) }
      let(:exception) { ActiveRecord::StatementTimeout.new }

      it { expect(subject).to be_falsey }
    end
  end

  describe '#time_efficiency' do
    subject { job.time_efficiency }

    let(:migration) { build(:batched_background_migration, interval: 120.seconds) }
    let(:job) { build(:batched_background_migration_job, :succeeded, batched_migration: migration) }

    context 'when job has not yet succeeded' do
      let(:job) { build(:batched_background_migration_job, :running) }

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
    let_it_be(:migration) { create(:batched_background_migration, table_name: :events) }
    let_it_be(:job) { create(:batched_background_migration_job, :failed, batched_migration: migration, batch_size: 10, min_value: 6, max_value: 15, attempts: 3) }
    let_it_be(:project) { create(:project) }

    before_all do
      (6..16).each do |id|
        create(:event, id: id, project: project)
      end
    end

    context 'when job can be split' do
      it 'sets the correct attributes' do
        expect { job.split_and_retry! }.to change { described_class.count }.by(1)

        expect(job).to have_attributes(
          min_value: 6,
          max_value: 10,
          batch_size: 5,
          status_name: :failed,
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
          status_name: :failed,
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
      let!(:job) { create(:batched_background_migration_job, :succeeded) }

      it 'raises an exception' do
        expect { job.split_and_retry! }.to raise_error 'Only failed jobs can be split'
      end
    end

    context 'when batch size is already 1' do
      let!(:job) { create(:batched_background_migration_job, :failed, batch_size: 1, attempts: 3) }

      it 'keeps the same batch size' do
        job.split_and_retry!

        expect(job.reload.batch_size).to eq 1
      end

      it 'resets the number of attempts' do
        job.split_and_retry!

        expect(job.attempts).to eq 0
      end
    end

    context 'when computed midpoint is larger than the max value of the batch' do
      before do
        Event.where(id: 6..12).delete_all
      end

      it 'lowers the batch size and resets the number of attempts' do
        expect { job.split_and_retry! }.not_to change { described_class.count }

        expect(job.batch_size).to eq(5)
        expect(job.attempts).to eq(0)
        expect(job.status_name).to eq(:failed)
      end
    end
  end
end
