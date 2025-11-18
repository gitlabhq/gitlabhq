# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundOperation::Queueable, feature_category: :database do
  let(:worker_klass) { Gitlab::Database::BackgroundOperation::Worker }
  let_it_be(:user) { create(:user) }
  let(:organization) { user.organization }

  describe '.enqueue' do
    let(:job_class_name) { 'TestWorker' }
    let(:table_name) { 'users' }
    let(:column_name) { 'id' }
    let(:job_arguments) { %w[arg1 arg2] }

    subject(:enqueue_background_operation) do
      worker_klass.enqueue(job_class_name, table_name, column_name, job_arguments: job_arguments, user: user)
    end

    context 'when there are no duplicate records' do
      it 'enqueues the worker' do
        expect { enqueue_background_operation }.to change { worker_klass.count }.by(1)

        record = worker_klass.unfinished_with_config(job_class_name, table_name, column_name, job_arguments).first

        expect(record).to have_attributes(
          job_class_name: job_class_name,
          table_name: table_name,
          column_name: column_name,
          user_id: user.id,
          organization_id: organization.id,
          job_arguments: job_arguments,
          batch_size: described_class::DEFAULT_BATCH_VALUES[:batch_size],
          sub_batch_size: described_class::DEFAULT_BATCH_VALUES[:sub_batch_size],
          interval: described_class::DEFAULT_BATCH_VALUES[:interval].to_i,
          batch_class_name: described_class::DEFAULT_BATCH_VALUES[:batch_class_name],
          pause_ms: described_class::DEFAULT_BATCH_VALUES[:pause_ms],
          status: 0
        )
      end

      context 'for background_worker_cell_local' do
        subject(:enqueue_background_operation) do
          worker_klass.enqueue(job_class_name, table_name, column_name, job_arguments: job_arguments)
        end

        let(:worker_klass) { Gitlab::Database::BackgroundOperation::WorkerCellLocal }

        it 'can store without organization_id' do
          expect { enqueue_background_operation }.to change { worker_klass.count }.by(1)
        end
      end

      context "for 'giltab_main_cell' table" do
        it 'uses gitlab_main connection' do
          allow(worker_klass).to receive(:table_connection_info).with(table_name).and_call_original

          enqueue_background_operation

          expect(worker_klass).to have_received(:table_connection_info).with(table_name)

          schema, connection = worker_klass.table_connection_info(table_name)
          expect(schema).to eq(:gitlab_main_user)
          expect(connection).to eq(ApplicationRecord.connection)
        end
      end

      context "for 'gitlab_ci' table" do
        let(:table_name) { 'p_ci_build_tags' }

        it 'uses gitlab_ci connection' do
          allow(worker_klass).to receive(:table_connection_info).with(table_name).and_call_original

          enqueue_background_operation

          expect(worker_klass).to have_received(:table_connection_info).with(table_name)

          schema, connection = worker_klass.table_connection_info(table_name)
          expect(schema).to eq(:gitlab_ci)
          expect(connection).to eq(Ci::ApplicationRecord.connection)
        end
      end
    end

    context 'with duplicate' do
      before do
        worker_klass.enqueue(job_class_name, table_name, column_name, job_arguments: job_arguments, user: user)
      end

      it 'skips enqueue and logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          format(
            described_class::EXISTING_OPERATION_MSG,
            job_class_name,
            table_name,
            column_name,
            job_arguments.join(', ')
          )
        )

        expect { enqueue_background_operation }.not_to change { worker_klass.count }
      end
    end
  end
end
