# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper, '#perform' do
  let(:migration_wrapper) { described_class.new }
  let(:job_class) { Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob }

  let_it_be(:active_migration) { create(:batched_background_migration, :active, job_arguments: [:id, :other_id]) }

  let!(:job_record) { create(:batched_background_migration_job, batched_migration: active_migration) }
  let(:job_instance) { double('job instance', batch_metrics: {}) }

  before do
    allow(job_class).to receive(:new).and_return(job_instance)
  end

  it 'runs the migration job' do
    expect(job_instance).to receive(:perform).with(1, 10, 'events', 'id', 1, 'id', 'other_id')

    migration_wrapper.perform(job_record)
  end

  it 'updates the tracking record in the database' do
    test_metrics = { 'my_metris' => 'some value' }

    expect(job_instance).to receive(:perform)
    expect(job_instance).to receive(:batch_metrics).and_return(test_metrics)

    expect(job_record).to receive(:update!).with(hash_including(attempts: 1, status: :running)).and_call_original

    freeze_time do
      migration_wrapper.perform(job_record)

      reloaded_job_record = job_record.reload

      expect(reloaded_job_record).not_to be_pending
      expect(reloaded_job_record.attempts).to eq(1)
      expect(reloaded_job_record.started_at).to eq(Time.current)
      expect(reloaded_job_record.metrics).to eq(test_metrics)
    end
  end

  context 'when the migration job does not raise an error' do
    it 'marks the tracking record as succeeded' do
      expect(job_instance).to receive(:perform).with(1, 10, 'events', 'id', 1, 'id', 'other_id')

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
      expect(job_instance).to receive(:perform)
        .with(1, 10, 'events', 'id', 1, 'id', 'other_id')
        .and_raise(RuntimeError, 'Something broke!')

      freeze_time do
        expect { migration_wrapper.perform(job_record) }.to raise_error(RuntimeError, 'Something broke!')

        reloaded_job_record = job_record.reload

        expect(reloaded_job_record).to be_failed
        expect(reloaded_job_record.finished_at).to eq(Time.current)
      end
    end
  end
end
