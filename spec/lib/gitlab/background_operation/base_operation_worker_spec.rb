# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundOperation::BaseOperationWorker, feature_category: :database do
  include MigrationsHelpers

  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  describe '.job_arguments' do
    let(:job_class) do
      Class.new(described_class) do
        job_arguments :value_a, :value_b
      end
    end

    subject(:job_instance) do
      job_class.new(
        min_cursor: [1],
        max_cursor: [10],
        batch_table: '_test_table',
        batch_column: 'id',
        sub_batch_size: 2,
        pause_ms: 1000,
        job_arguments: %w[a b],
        connection: connection
      )
    end

    it 'defines methods' do
      expect(job_instance.value_a).to eq('a')
      expect(job_instance.value_b).to eq('b')
    end
  end

  describe '.feature_category' do
    context 'when jobs does not have feature_category attribute set' do
      let(:job_class) { Class.new(described_class) }

      it 'returns :database as default' do
        expect(job_class.feature_category).to eq(:database)
      end
    end

    context 'when jobs have feature_category attribute set' do
      let(:job_class) do
        Class.new(described_class) do
          feature_category :webhooks
        end
      end

      it 'returns the provided value' do
        expect(job_class.feature_category).to eq(:webhooks)
      end
    end
  end

  describe '.operation_name' do
    subject(:perform_job) { job_instance.perform }

    let(:job_instance) do
      job_class.new(
        min_cursor: [1],
        max_cursor: [10],
        batch_table: '_test_table',
        batch_column: 'id',
        sub_batch_size: 2,
        pause_ms: 1000,
        job_arguments: %w[a b],
        connection: connection
      )
    end

    let(:job_class) do
      Class.new(described_class) do
        operation_name :update_all
      end
    end

    it 'defines method' do
      expect(job_instance.operation_name).to eq(:update_all)
    end

    context 'when `operation_name` is not defined' do
      let(:job_class) do
        Class.new(described_class)
      end

      it 'raises an exception' do
        expect { job_instance.send(:operation_name) }.to raise_error(RuntimeError, /Operation name is required/)
      end
    end
  end

  describe '.cursor' do
    let(:job_class) do
      Class.new(described_class) do
        cursor :id, :created_at
      end
    end

    subject(:job_instance) do
      job_class.new(
        min_cursor: [1, 2.months.ago.to_s],
        max_cursor: [10, Date.current.to_s],
        batch_table: '_test_table',
        batch_column: 'id',
        sub_batch_size: 2,
        pause_ms: 1000,
        job_arguments: %w[a b],
        connection: connection
      )
    end

    it 'defines methods' do
      expect(job_class.cursor_columns).to match_array([:id, :created_at])
    end

    context 'when no cursors columns are defined' do
      let(:job_class) do
        Class.new(described_class)
      end

      it 'raises an exception' do
        expect { job_instance.send(:cursor) }.to raise_error(RuntimeError, /Cursor is required/)
      end
    end
  end

  describe '#perform' do
    let(:job_class) { Class.new(described_class) }

    let(:job_instance) do
      job_class.new(
        min_cursor: [1],
        max_cursor: [10],
        batch_table: '_test_table',
        batch_column: 'id',
        sub_batch_size: 2,
        pause_ms: 1000,
        connection: connection
      )
    end

    subject(:perform_job) { job_instance.perform }

    it 'raises an error if not overridden' do
      expect { perform_job }.to raise_error(NotImplementedError, /must implement perform/)
    end

    context 'when the subclass implements perform' do
      let(:job_class) do
        Class.new(described_class) do
          operation_name :test_operation
          cursor :id

          def perform(*_job_arguments)
            'performed successfully'
          end
        end
      end

      it 'executes the perform method' do
        expect(perform_job).to eq('performed successfully')
      end
    end

    context 'when the subclass uses job arguments' do
      let(:job_class) do
        Class.new(described_class) do
          operation_name :test_operation
          cursor :id
          job_arguments :arg1, :arg2

          def perform
            "#{arg1}-#{arg2}"
          end
        end
      end

      let(:job_instance) do
        job_class.new(
          min_cursor: [1],
          max_cursor: [10],
          batch_table: '_test_table',
          batch_column: 'id',
          sub_batch_size: 2,
          pause_ms: 1000,
          job_arguments: %w[hello world],
          connection: connection
        )
      end

      it 'has access to job arguments' do
        expect(perform_job).to eq('hello-world')
      end
    end

    context 'when the subclass uses sub-batching' do
      let(:job_class) do
        Class.new(described_class) do
          operation_name :update
          cursor :id

          def perform(*_job_arguments)
            each_sub_batch do |sub_batch|
              sub_batch.update_all('to_column = from_column')
            end
          end
        end
      end

      let(:test_table) { table(:_test_table) }

      before do
        allow(job_instance).to receive(:sleep)

        connection.create_table :_test_table do |t|
          t.timestamps_with_timezone null: false
          t.integer :from_column, null: false
          t.text :bar
          t.integer :to_column
        end

        test_table.create!(id: 1, from_column: 5, bar: 'value')
        test_table.create!(id: 2, from_column: 10, bar: 'value')
        test_table.create!(id: 3, from_column: 15)
        test_table.create!(id: 4, from_column: 20, bar: 'value')

        # Mock nullable_column? method for dynamic model
        allow(job_instance).to receive(:define_batchable_model).and_wrap_original do |original_method, *args, **kwargs|
          model = original_method.call(*args, **kwargs)
          allow(model).to receive(:nullable_column?).and_return(false)
          model
        end
      end

      after do
        connection.drop_table(:_test_table)
      end

      it 'calls the operation for each sub-batch' do
        expect { perform_job }.to change { test_table.where(to_column: nil).count }.from(4).to(0)

        expect(test_table.order(:id).pluck(:to_column)).to contain_exactly(5, 10, 15, 20)
      end

      it 'pauses after each sub-batch' do
        expect(job_instance).to receive(:sleep).with(1.0).twice

        perform_job
      end

      context 'when using a sub batch exception for timeouts' do
        let(:job_class) do
          Class.new(described_class) do
            operation_name :update
            cursor :id

            def perform(*_)
              each_sub_batch { raise ActiveRecord::StatementTimeout } # rubocop:disable Lint/UnreachableLoop -- no clearer way to write this
            end
          end
        end

        let(:job_instance) do
          job_class.new(
            min_cursor: [1],
            max_cursor: [10],
            batch_table: '_test_table',
            batch_column: 'id',
            sub_batch_size: 2,
            pause_ms: 1000,
            connection: connection,
            sub_batch_exception: StandardError
          )
        end

        it 'raises the expected error type' do
          expect { job_instance.perform }.to raise_error(StandardError)
        end
      end

      it 'instruments the batch operation' do
        expect(job_instance.batch_metrics.affected_rows).to be_empty

        expect(job_instance.batch_metrics).to receive(:instrument_operation).with(:update).twice.and_call_original

        perform_job

        expect(job_instance.batch_metrics.affected_rows[:update]).to contain_exactly(2, 2)
      end
    end
  end
end
