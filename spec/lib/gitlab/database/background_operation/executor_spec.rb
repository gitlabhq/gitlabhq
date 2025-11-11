# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundOperation::Executor, '#perform', feature_category: :database do
  subject(:perform) { described_class.new(connection: connection).perform(job) }

  let(:connection) { Gitlab::Database.database_base_models[:main].connection }
  let(:job_class) { Class.new(Gitlab::Database::BackgroundOperation::Job) }
  let(:sub_batch_exception) { Gitlab::Database::BackgroundOperation::Executor::SubBatchTimeoutError }

  let_it_be(:pause_ms) { 250 }
  let_it_be(:worker) { create(:background_operation_worker, :active, job_arguments: [:id, :other_id]) }
  let!(:job) do
    create(:background_operation_job, worker: worker, worker_partition: worker.partition, pause_ms: pause_ms)
  end

  let(:worker_instance) { instance_double(Gitlab::BackgroundOperation::BaseOperationWorker) }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  before do
    allow(worker).to receive(:job_class).and_return(job_class)
    allow(job_class).to receive(:new).and_return(worker_instance)
  end

  it 'runs the operation job' do
    expect(job_class).to receive(:new).with(
      min_cursor: [1],
      max_cursor: [1000],
      batch_table: 'events',
      batch_column: 'id',
      sub_batch_size: 10,
      pause_ms: pause_ms,
      job_arguments: worker.job_arguments,
      connection: connection,
      sub_batch_exception: sub_batch_exception
    ).and_return(worker_instance)

    expect(worker_instance).to receive(:perform).with(no_args)

    perform
  end

  it 'updates the tracking record in the database', :freeze_time do
    test_metrics = { 'my_metrics' => 'some value' }

    expect(worker_instance).to receive(:perform).with(no_args)
    expect(worker_instance).to receive(:batch_metrics).and_return(test_metrics)

    perform

    expect(job).not_to be_pending
    expect(job.attempts).to eq(1)
    expect(job.started_at).to eq(Time.current)
    expect(job.metrics).to eq(test_metrics)
  end

  context 'when running a job that failed previously', :freeze_time do
    let!(:job) do
      create(:background_operation_job,
        :failed,
        attempts: 1,
        finished_at: 1.hour.ago,
        worker: worker,
        worker_partition: worker.partition,
        metrics: { 'my_metrics' => 'some_value' },
        pause_ms: pause_ms
      )
    end

    it 'increments attempts and updates other fields' do
      updated_metrics = { 'updated_metrics' => 'some_value' }

      expect(worker_instance).to receive(:perform).with(no_args)
      expect(worker_instance).to receive(:batch_metrics).and_return(updated_metrics)

      perform

      reloaded_job = job.reload

      expect(reloaded_job).not_to be_failed
      expect(reloaded_job.attempts).to eq(2)
      expect(reloaded_job.started_at).to eq(Time.current)
      expect(reloaded_job.finished_at).to eq(Time.current)
      expect(reloaded_job.metrics).to eq(updated_metrics)
    end
  end

  context 'when the operation job does not raise an error' do
    it 'marks the tracking record as succeeded', :freeze_time do
      expect(worker_instance).to receive(:perform).with(no_args)

      perform

      expect(job).to be_succeeded
      expect(job.finished_at).to eq(Time.current)
    end
  end

  context 'when the operation job raises an error' do
    shared_examples 'an error is raised' do |error_class|
      it 'marks the record as failed', :freeze_time do
        expect(worker_instance).to receive(:perform).with(no_args).and_raise(error_class)

        expect { perform }.to raise_error(error_class.class)

        reloaded_job = job.reload

        expect(reloaded_job).to be_failed
        expect(reloaded_job.finished_at).to eq(Time.current)
      end
    end

    it_behaves_like 'an error is raised', RuntimeError.new('Something broke!')
    it_behaves_like 'an error is raised', SignalException.new('SIGTERM')
    it_behaves_like 'an error is raised', ActiveRecord::StatementTimeout.new('Timeout!')
    it_behaves_like 'an error is raised', described_class::SubBatchTimeoutError.new('Sub batch error')
  end
end
