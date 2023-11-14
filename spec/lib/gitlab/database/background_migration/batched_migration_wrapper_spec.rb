# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper, '#perform' do
  subject(:perform) { described_class.new(connection: connection, metrics: metrics_tracker).perform(job_record) }

  let(:connection) { Gitlab::Database.database_base_models[:main].connection }
  let(:metrics_tracker) { instance_double('::Gitlab::Database::BackgroundMigration::PrometheusMetrics', track: nil) }
  let(:job_class) { Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) }
  let(:sub_batch_exception) { Gitlab::Database::BackgroundMigration::SubBatchTimeoutError }

  let_it_be(:pause_ms) { 250 }
  let_it_be(:active_migration) { create(:batched_background_migration, :active, job_arguments: [:id, :other_id]) }

  let!(:job_record) do
    create(:batched_background_migration_job, batched_migration: active_migration, pause_ms: pause_ms)
  end

  let(:job_instance) { instance_double('Gitlab::BackgroundMigration::BatchedMigrationJob') }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  before do
    allow(active_migration).to receive(:job_class).and_return(job_class)

    allow(job_class).to receive(:new).and_return(job_instance)
  end

  it 'runs the migration job' do
    expect(job_class).to receive(:new).with(
      start_id: 1,
      end_id: 10,
      batch_table: 'events',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: pause_ms,
      job_arguments: active_migration.job_arguments,
      connection: connection,
      sub_batch_exception: sub_batch_exception
    ).and_return(job_instance)

    expect(job_instance).to receive(:perform).with(no_args)

    perform
  end

  it 'updates the tracking record in the database' do
    test_metrics = { 'my_metrics' => 'some value' }

    expect(job_instance).to receive(:perform).with(no_args)
    expect(job_instance).to receive(:batch_metrics).and_return(test_metrics)

    freeze_time do
      perform

      reloaded_job_record = job_record.reload

      expect(reloaded_job_record).not_to be_pending
      expect(reloaded_job_record.attempts).to eq(1)
      expect(reloaded_job_record.started_at).to eq(Time.current)
      expect(reloaded_job_record.metrics).to eq(test_metrics)
    end
  end

  context 'when running a job that failed previously' do
    let!(:job_record) do
      create(:batched_background_migration_job, :failed,
        batched_migration: active_migration,
        pause_ms: pause_ms,
        attempts: 1,
        finished_at: 1.hour.ago,
        metrics: { 'my_metrics' => 'some_value' }
      )
    end

    it 'increments attempts and updates other fields' do
      updated_metrics = { 'updated_metrics' => 'some_value' }

      expect(job_instance).to receive(:perform).with(no_args)
      expect(job_instance).to receive(:batch_metrics).and_return(updated_metrics)

      freeze_time do
        perform

        job_record.reload

        expect(job_record).not_to be_failed
        expect(job_record.attempts).to eq(2)
        expect(job_record.started_at).to eq(Time.current)
        expect(job_record.finished_at).to eq(Time.current)
        expect(job_record.metrics).to eq(updated_metrics)
      end
    end
  end

  context 'when the migration job does not raise an error' do
    it 'marks the tracking record as succeeded' do
      expect(job_instance).to receive(:perform).with(no_args)

      freeze_time do
        perform

        reloaded_job_record = job_record.reload

        expect(reloaded_job_record).to be_succeeded
        expect(reloaded_job_record.finished_at).to eq(Time.current)
      end
    end

    it 'tracks metrics of the execution' do
      expect(job_instance).to receive(:perform).with(no_args)
      expect(metrics_tracker).to receive(:track).with(job_record)

      perform
    end
  end

  context 'when the migration job raises an error' do
    shared_examples 'an error is raised' do |error_class, cause|
      let(:expected_to_raise) { cause || error_class }

      it 'marks the tracking record as failed' do
        expect(job_instance).to receive(:perform).with(no_args).and_raise(error_class)

        freeze_time do
          expect { perform }.to raise_error(expected_to_raise)

          reloaded_job_record = job_record.reload

          expect(reloaded_job_record).to be_failed
          expect(reloaded_job_record.finished_at).to eq(Time.current)
        end
      end

      it 'tracks metrics of the execution' do
        expect(job_instance).to receive(:perform).with(no_args).and_raise(error_class)
        expect(metrics_tracker).to receive(:track).with(job_record)

        expect { perform }.to raise_error(expected_to_raise)
      end
    end

    it_behaves_like 'an error is raised', RuntimeError.new('Something broke!')
    it_behaves_like 'an error is raised', SignalException.new('SIGTERM')
    it_behaves_like 'an error is raised', ActiveRecord::StatementTimeout.new('Timeout!')

    error = StandardError.new
    it_behaves_like('an error is raised', Gitlab::Database::BackgroundMigration::SubBatchTimeoutError.new(error), error)
  end

  context 'when the batched background migration does not inherit from BatchedMigrationJob' do
    let(:job_class) { Class.new }
    let(:job_instance) { job_class.new }

    it 'runs the job with the correct arguments' do
      expect(job_class).to receive(:new).with(no_args).and_return(job_instance)
      expect(Gitlab::ApplicationContext).to receive(:push).with(feature_category: :database)
      expect(job_instance).to receive(:perform).with(1, 10, 'events', 'id', 1, pause_ms, 'id', 'other_id')

      perform
    end
  end
end
