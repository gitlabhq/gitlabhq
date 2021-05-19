# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper, '#perform' do
  subject { described_class.new.perform(job_record) }

  let(:job_class) { Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob }

  let_it_be(:pause_ms) { 250 }
  let_it_be(:active_migration) { create(:batched_background_migration, :active, job_arguments: [:id, :other_id]) }

  let!(:job_record) do
    create(:batched_background_migration_job,
           batched_migration: active_migration,
           pause_ms: pause_ms
          )
  end

  let(:job_instance) { double('job instance', batch_metrics: {}) }

  before do
    allow(job_class).to receive(:new).and_return(job_instance)
  end

  it 'runs the migration job' do
    expect(job_instance).to receive(:perform).with(1, 10, 'events', 'id', 1, pause_ms, 'id', 'other_id')

    subject
  end

  it 'updates the tracking record in the database' do
    test_metrics = { 'my_metris' => 'some value' }

    expect(job_instance).to receive(:perform)
    expect(job_instance).to receive(:batch_metrics).and_return(test_metrics)

    expect(job_record).to receive(:update!).with(hash_including(attempts: 1, status: :running)).and_call_original

    freeze_time do
      subject

      reloaded_job_record = job_record.reload

      expect(reloaded_job_record).not_to be_pending
      expect(reloaded_job_record.attempts).to eq(1)
      expect(reloaded_job_record.started_at).to eq(Time.current)
      expect(reloaded_job_record.metrics).to eq(test_metrics)
    end
  end

  context 'when running a job that failed previously' do
    let!(:job_record) do
      create(:batched_background_migration_job,
        batched_migration: active_migration,
        pause_ms: pause_ms,
        attempts: 1,
        status: :failed,
        finished_at: 1.hour.ago,
        metrics: { 'my_metrics' => 'some_value' }
      )
    end

    it 'increments attempts and updates other fields' do
      updated_metrics = { 'updated_metrics' => 'some_value' }

      expect(job_instance).to receive(:perform)
      expect(job_instance).to receive(:batch_metrics).and_return(updated_metrics)

      expect(job_record).to receive(:update!).with(
        hash_including(attempts: 2, status: :running, finished_at: nil, metrics: {})
      ).and_call_original

      freeze_time do
        subject

        job_record.reload

        expect(job_record).not_to be_failed
        expect(job_record.attempts).to eq(2)
        expect(job_record.started_at).to eq(Time.current)
        expect(job_record.finished_at).to eq(Time.current)
        expect(job_record.metrics).to eq(updated_metrics)
      end
    end
  end

  context 'reporting prometheus metrics' do
    let(:labels) { job_record.batched_migration.prometheus_labels }

    before do
      allow(job_instance).to receive(:perform)
    end

    it 'reports batch_size' do
      expect(described_class.metrics[:gauge_batch_size]).to receive(:set).with(labels, job_record.batch_size)

      subject
    end

    it 'reports sub_batch_size' do
      expect(described_class.metrics[:gauge_sub_batch_size]).to receive(:set).with(labels, job_record.sub_batch_size)

      subject
    end

    it 'reports interval' do
      expect(described_class.metrics[:gauge_interval]).to receive(:set).with(labels, job_record.batched_migration.interval)

      subject
    end

    it 'reports updated tuples (currently based on batch_size)' do
      expect(described_class.metrics[:counter_updated_tuples]).to receive(:increment).with(labels, job_record.batch_size)

      subject
    end

    it 'reports migrated tuples' do
      count = double
      expect(job_record.batched_migration).to receive(:migrated_tuple_count).and_return(count)
      expect(described_class.metrics[:gauge_migrated_tuples]).to receive(:set).with(labels, count)

      subject
    end

    it 'reports summary of query timings' do
      metrics = { 'timings' => { 'update_all' => [1, 2, 3, 4, 5] } }

      expect(job_instance).to receive(:batch_metrics).and_return(metrics)

      metrics['timings'].each do |key, timings|
        summary_labels = labels.merge(operation: key)
        timings.each do |timing|
          expect(described_class.metrics[:histogram_timings]).to receive(:observe).with(summary_labels, timing)
        end
      end

      subject
    end

    it 'reports job duration' do
      freeze_time do
        expect(Time).to receive(:current).and_return(Time.zone.now - 5.seconds).ordered
        allow(Time).to receive(:current).and_call_original

        expect(described_class.metrics[:gauge_job_duration]).to receive(:set).with(labels, 5.seconds)

        subject
      end
    end

    it 'reports the total tuple count for the migration' do
      expect(described_class.metrics[:gauge_total_tuple_count]).to receive(:set).with(labels, job_record.batched_migration.total_tuple_count)

      subject
    end

    it 'reports last updated at timestamp' do
      freeze_time do
        expect(described_class.metrics[:gauge_last_update_time]).to receive(:set).with(labels, Time.current.to_i)

        subject
      end
    end
  end

  context 'when the migration job does not raise an error' do
    it 'marks the tracking record as succeeded' do
      expect(job_instance).to receive(:perform).with(1, 10, 'events', 'id', 1, pause_ms, 'id', 'other_id')

      freeze_time do
        subject

        reloaded_job_record = job_record.reload

        expect(reloaded_job_record).to be_succeeded
        expect(reloaded_job_record.finished_at).to eq(Time.current)
      end
    end
  end

  context 'when the migration job raises an error' do
    shared_examples 'an error is raised' do |error_class|
      it 'marks the tracking record as failed' do
        expect(job_instance).to receive(:perform)
          .with(1, 10, 'events', 'id', 1, pause_ms, 'id', 'other_id')
          .and_raise(error_class)

        freeze_time do
          expect { subject }.to raise_error(error_class)

          reloaded_job_record = job_record.reload

          expect(reloaded_job_record).to be_failed
          expect(reloaded_job_record.finished_at).to eq(Time.current)
        end
      end
    end

    it_behaves_like 'an error is raised', RuntimeError.new('Something broke!')
    it_behaves_like 'an error is raised', SignalException.new('SIGTERM')
  end
end
