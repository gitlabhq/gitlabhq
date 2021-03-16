# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper, '#perform' do
  let(:migration_wrapper) { described_class.new }
  let(:job_class) { Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob }

  let_it_be(:active_migration) { create(:batched_background_migration, :active, job_arguments: [:id, :other_id]) }

  let!(:job_record) { create(:batched_background_migration_job, batched_migration: active_migration) }

  it 'runs the migration job' do
    expect_next_instance_of(job_class) do |job_instance|
      expect(job_instance).to receive(:perform).with(1, 10, 'events', 'id', 1, 'id', 'other_id')
    end

    migration_wrapper.perform(job_record)
  end

  it 'updates the the tracking record in the database' do
    expect(job_record).to receive(:update!).with(hash_including(attempts: 1, status: :running)).and_call_original

    freeze_time do
      migration_wrapper.perform(job_record)

      reloaded_job_record = job_record.reload

      expect(reloaded_job_record).not_to be_pending
      expect(reloaded_job_record.attempts).to eq(1)
      expect(reloaded_job_record.started_at).to eq(Time.current)
    end
  end

  context 'when the migration job does not raise an error' do
    it 'marks the tracking record as succeeded' do
      expect_next_instance_of(job_class) do |job_instance|
        expect(job_instance).to receive(:perform).with(1, 10, 'events', 'id', 1, 'id', 'other_id')
      end

      freeze_time do
        migration_wrapper.perform(job_record)

        reloaded_job_record = job_record.reload

        expect(reloaded_job_record).to be_succeeded
        expect(reloaded_job_record.finished_at).to eq(Time.current)
      end
    end
  end

  context 'when the migration job raises an error' do
    it 'marks the tracking record as failed before raising the error' do
      expect_next_instance_of(job_class) do |job_instance|
        expect(job_instance).to receive(:perform)
          .with(1, 10, 'events', 'id', 1, 'id', 'other_id')
          .and_raise(RuntimeError, 'Something broke!')
      end

      freeze_time do
        expect { migration_wrapper.perform(job_record) }.to raise_error(RuntimeError, 'Something broke!')

        reloaded_job_record = job_record.reload

        expect(reloaded_job_record).to be_failed
        expect(reloaded_job_record.finished_at).to eq(Time.current)
      end
    end
  end
end
