# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundOperation::Runner, feature_category: :database do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }
  let(:executor) { instance_double(Gitlab::Database::BackgroundOperation::Executor) }
  let(:runner) { described_class.new(connection: connection, executor: executor) }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  before do
    normal_signal = instance_double(Gitlab::Database::HealthStatus::Signals::Normal, stop?: false)
    allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([normal_signal])
  end

  describe '#run_operation_job' do
    shared_examples_for 'it has completed the operation' do
      it 'does not create and run a operation job' do
        expect(executor).not_to receive(:perform)

        expect do
          runner.run_operation_job(worker)
        end.not_to change { Gitlab::Database::BackgroundOperation::Job.count }
      end

      it 'marks the operation as finished' do
        runner.run_operation_job(worker)

        expect(worker.reload).to be_finished
      end
    end

    context 'when the operation has no previous jobs' do
      let(:worker) { create(:background_operation_worker, :active, batch_size: 2, sub_batch_size: 2) }

      let(:operation_jobs) do
        Gitlab::Database::BackgroundOperation::Job.where(worker_id: worker.id)
      end

      context 'when the operation has batches to process' do
        let_it_be(:event1) { create(:event) }
        let_it_be(:event2) { create(:event) }
        let_it_be(:event3) { create(:event) }

        it 'runs the job for the first batch' do
          worker.update!(min_cursor: [0], max_cursor: [event2.id])

          expect(executor).to receive(:perform) do |job_record|
            expect(job_record).to eq(operation_jobs.first)
          end

          expect { runner.run_operation_job(worker) }.to change { operation_jobs.count }.by(1)

          expect(operation_jobs.first).to have_attributes(
            min_cursor: [event1.id],
            max_cursor: [event2.id],
            batch_size: worker.batch_size,
            sub_batch_size: worker.sub_batch_size
          )
        end

        context 'with operation health signals' do
          let(:health_status) { Gitlab::Database::HealthStatus }
          let(:stop_signal) { health_status::Signals::Stop.new(:indicator, reason: 'Take a break') }
          let(:normal_signal) { health_status::Signals::Normal.new(:indicator, reason: 'All good') }
          let(:not_available_signal) do
            health_status::Signals::NotAvailable.new(:indicator, reason: 'Indicator is disabled')
          end

          let(:unknown_signal) { health_status::Signals::Unknown.new(:indicator, reason: 'Something went wrong') }

          before do
            worker.update!(min_cursor: [event1.id], max_cursor: [event2.id])
          end

          it 'puts operation on hold on stop signal' do
            expect(executor).to receive(:perform)
            expect(health_status).to receive(:evaluate).and_return([stop_signal])

            expect { runner.run_operation_job(worker) }.to change { worker.on_hold? }.from(false).to(true)
          end

          it 'optimizes operation on normal signal' do
            expect(executor).to receive(:perform)
            expect(health_status).to receive(:evaluate).and_return([normal_signal])
            expect(worker).to receive(:optimize!)

            expect { runner.run_operation_job(worker) }.not_to change { worker.on_hold? }
          end

          it 'optimizes operation on no signal' do
            expect(executor).to receive(:perform)
            expect(health_status).to receive(:evaluate).and_return([not_available_signal])
            expect(worker).to receive(:optimize!)

            expect { runner.run_operation_job(worker) }.not_to change { worker.on_hold? }
          end

          it 'optimizes operation on unknown signal' do
            expect(executor).to receive(:perform)
            expect(health_status).to receive(:evaluate).and_return([unknown_signal])
            expect(worker).to receive(:optimize!)

            expect { runner.run_operation_job(worker) }.not_to change { worker.on_hold? }
          end
        end
      end

      context 'when the batch maximum exceeds the operation maximum' do
        let_it_be(:events) { create_list(:event, 3) }
        let(:event1) { events[0] }
        let(:event2) { events[1] }

        it 'clamps the batch maximum to the operation maximum' do
          worker.update!(min_cursor: [0], max_cursor: [event2.id], batch_size: 5, sub_batch_size: 5)

          expect(executor).to receive(:perform)

          expect { runner.run_operation_job(worker) }.to change { operation_jobs.count }.by(1)

          expect(operation_jobs.first).to have_attributes(
            min_cursor: [event1.id],
            max_cursor: [event2.id],
            batch_size: worker.batch_size,
            sub_batch_size: worker.sub_batch_size
          )
        end
      end

      context 'when the operation has no batches to process' do
        it_behaves_like 'it has completed the operation'
      end
    end

    context 'when the operation should stop' do
      let(:worker) { create(:background_operation_worker, :active, batch_size: 2, sub_batch_size: 2) }
      let!(:job) { create(:background_operation_job, :failed, worker: worker) }

      it 'changes the status to failure' do
        expect(worker).to receive(:should_stop?).and_return(true)
        expect(executor).to receive(:perform).and_return(job)

        expect { runner.run_operation_job(worker) }.to change { worker.status_name }.from(:active).to(:failed)
      end
    end

    context 'when the operation has previous jobs' do
      let_it_be(:event1) { create(:event) }
      let_it_be(:event2) { create(:event) }
      let_it_be(:event3) { create(:event) }

      let!(:worker) do
        create(:background_operation_worker, :active, batch_size: 2, sub_batch_size: 2, min_cursor: [0],
          max_cursor: [event2.id])
      end

      let!(:previous_job) do
        create(:background_operation_job, :succeeded, worker: worker, min_cursor: [0], max_cursor: [event2.id],
          batch_size: 2, sub_batch_size: 1)
      end

      let(:operation_jobs) do
        Gitlab::Database::BackgroundOperation::Job.where(worker_id: worker.id)
      end

      context 'when the operation has no batches remaining' do
        it_behaves_like 'it has completed the operation'
      end

      context 'when the operation has batches to process' do
        before do
          worker.update!(max_cursor: [event3.id])
        end

        it 'runs the operation job for the next batch' do
          new_job = nil

          expect(executor).to receive(:perform) do |job_record|
            new_job = job_record
            expect(job_record).to eq(new_job)
          end

          expect { runner.run_operation_job(worker) }.to change { operation_jobs.count }.by(1)

          expect(new_job).to have_attributes(
            min_cursor: [event3.id],
            max_cursor: [event3.id],
            batch_size: worker.batch_size,
            sub_batch_size: worker.sub_batch_size)
        end

        context 'when the batch minimum exceeds the operation maximum' do
          before do
            worker.update!(batch_size: 5, max_cursor: [event2.id])
          end

          it_behaves_like 'it has completed the operation'
        end
      end

      context 'when operation has failed jobs' do
        before do
          previous_job.failure!
        end

        it 'retries the failed job' do
          expect(executor).to receive(:perform) do |job_record|
            expect(job_record).to eq(previous_job)
          end

          expect { runner.run_operation_job(worker) }.not_to change { operation_jobs.count }
        end

        context 'when failed job has reached the maximum number of attempts' do
          before do
            previous_job.update!(attempts: Gitlab::Database::BackgroundOperation::Job::MAX_ATTEMPTS)
          end

          it 'marks the operation as failed' do
            expect(executor).not_to receive(:perform)

            expect { runner.run_operation_job(worker) }.not_to change { operation_jobs.count }

            expect(worker).to be_failed
          end
        end
      end

      context 'when the operation has batches to process and failed jobs' do
        before do
          worker.update!(max_cursor: [event3.id])
          previous_job.failure!
        end

        it 'runs next batch then retries the failed job' do
          new_job = nil

          expect(executor).to receive(:perform) do |job_record|
            new_job = job_record
            expect(job_record).to eq(new_job)
            job_record.succeed!
          end

          expect { runner.run_operation_job(worker) }.to change { operation_jobs.count }.by(1)

          expect(executor).to receive(:perform) do |job_record|
            expect(job_record).to eq(previous_job)
          end

          expect { runner.run_operation_job(worker.reload) }.not_to change { operation_jobs.count }
        end
      end
    end
  end
end
