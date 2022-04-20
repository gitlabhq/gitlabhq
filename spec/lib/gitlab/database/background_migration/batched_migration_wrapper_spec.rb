# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper, '#perform' do
  subject { described_class.new(connection: connection, metrics: metrics_tracker).perform(job_record) }

  let(:connection) { Gitlab::Database.database_base_models[:main].connection }
  let(:metrics_tracker) { instance_double('::Gitlab::Database::BackgroundMigration::PrometheusMetrics', track: nil) }
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

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

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

      expect(job_instance).to receive(:perform)
      expect(job_instance).to receive(:batch_metrics).and_return(updated_metrics)

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

    it 'tracks metrics of the execution' do
      expect(job_instance).to receive(:perform)
      expect(metrics_tracker).to receive(:track).with(job_record)

      subject
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

      it 'tracks metrics of the execution' do
        expect(job_instance).to receive(:perform).and_raise(error_class)
        expect(metrics_tracker).to receive(:track).with(job_record)

        expect { subject }.to raise_error(error_class)
      end
    end

    it_behaves_like 'an error is raised', RuntimeError.new('Something broke!')
    it_behaves_like 'an error is raised', SignalException.new('SIGTERM')
    it_behaves_like 'an error is raised', ActiveRecord::StatementTimeout.new('Timeout!')
  end

  context 'when the batched background migration does not inherit from BaseJob' do
    let(:migration_class) { Class.new }

    before do
      stub_const('Gitlab::BackgroundMigration::Foo', migration_class)
    end

    let(:active_migration) { create(:batched_background_migration, :active, job_class_name: 'Foo') }
    let!(:job_record) { create(:batched_background_migration_job, batched_migration: active_migration) }

    it 'does not pass any argument' do
      expect(Gitlab::BackgroundMigration::Foo).to receive(:new).with(no_args).and_return(job_instance)

      expect(job_instance).to receive(:perform)

      subject
    end
  end

  context 'when the batched background migration inherits from BaseJob' do
    let(:active_migration) { create(:batched_background_migration, :active, job_class_name: 'Foo') }
    let!(:job_record) { create(:batched_background_migration_job, batched_migration: active_migration) }

    let(:migration_class) { Class.new(::Gitlab::BackgroundMigration::BaseJob) }

    before do
      stub_const('Gitlab::BackgroundMigration::Foo', migration_class)
    end

    it 'passes the correct connection' do
      expect(Gitlab::BackgroundMigration::Foo).to receive(:new).with(connection: connection).and_return(job_instance)

      expect(job_instance).to receive(:perform)

      subject
    end
  end
end
