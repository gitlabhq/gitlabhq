# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchedMigrationJob do
  describe '#perform' do
    let(:connection) { Gitlab::Database.database_base_models[:main].connection }

    let(:job_class) { Class.new(described_class) }

    let(:job_instance) do
      job_class.new(start_id: 1, end_id: 10,
                    batch_table: '_test_table',
                    batch_column: 'id',
                    sub_batch_size: 2,
                    pause_ms: 1000,
                    connection: connection)
    end

    subject(:perform_job) { job_instance.perform }

    it 'raises an error if not overridden' do
      expect { perform_job }.to raise_error(NotImplementedError, /must implement perform/)
    end

    context 'when the subclass uses sub-batching' do
      let(:job_class) do
        Class.new(described_class) do
          def perform(*job_arguments)
            each_sub_batch(
              operation_name: :update,
              batching_arguments: { order_hint: :updated_at },
              batching_scope: -> (relation) { relation.where.not(bar: nil) }
            ) do |sub_batch|
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
      end

      after do
        connection.drop_table(:_test_table)
      end

      it 'calls the operation for each sub-batch' do
        expect { perform_job }.to change { test_table.where(to_column: nil).count }.from(4).to(1)

        expect(test_table.order(:id).pluck(:to_column)).to contain_exactly(5, 10, nil, 20)
      end

      it 'instruments the batch operation' do
        expect(job_instance.batch_metrics.affected_rows).to be_empty

        expect(job_instance.batch_metrics).to receive(:instrument_operation).with(:update).twice.and_call_original

        perform_job

        expect(job_instance.batch_metrics.affected_rows[:update]).to contain_exactly(2, 1)
      end

      it 'pauses after each sub-batch' do
        expect(job_instance).to receive(:sleep).with(1.0).twice

        perform_job
      end

      context 'when batching_arguments are given' do
        it 'forwards them for batching' do
          expect(job_instance).to receive(:parent_batch_relation).and_return(test_table)

          expect(test_table).to receive(:each_batch).with(column: 'id', of: 2, order_hint: :updated_at)

          perform_job
        end
      end
    end

    context 'when the subclass uses distinct each batch' do
      let(:job_instance) do
        job_class.new(start_id: 1,
                      end_id: 100,
                      batch_table: '_test_table',
                      batch_column: 'from_column',
                      sub_batch_size: 2,
                      pause_ms: 10,
                      connection: connection)
      end

      let(:job_class) do
        Class.new(described_class) do
          def perform(*job_arguments)
            distinct_each_batch(operation_name: :insert) do |sub_batch|
              sub_batch.pluck(:from_column).each do |value|
                connection.execute("INSERT INTO _test_insert_table VALUES (#{value})")
              end

              sub_batch.size
            end
          end
        end
      end

      let(:test_table) { table(:_test_table) }
      let(:test_insert_table) { table(:_test_insert_table) }

      before do
        allow(job_instance).to receive(:sleep)

        connection.create_table :_test_table do |t|
          t.timestamps_with_timezone null: false
          t.integer :from_column, null: false
        end

        connection.create_table :_test_insert_table, id: false do |t|
          t.integer :to_column
          t.index :to_column, unique: true
        end

        test_table.create!(id: 1, from_column: 5)
        test_table.create!(id: 2, from_column: 10)
        test_table.create!(id: 3, from_column: 10)
        test_table.create!(id: 4, from_column: 5)
        test_table.create!(id: 5, from_column: 15)
      end

      after do
        connection.drop_table(:_test_table)
        connection.drop_table(:_test_insert_table)
      end

      it 'calls the operation for each distinct batch' do
        expect { perform_job }.to change { test_insert_table.pluck(:to_column) }.from([]).to([5, 10, 15])
      end

      it 'stores the affected rows' do
        perform_job

        expect(job_instance.batch_metrics.affected_rows[:insert]).to contain_exactly(2, 1)
      end
    end
  end
end
