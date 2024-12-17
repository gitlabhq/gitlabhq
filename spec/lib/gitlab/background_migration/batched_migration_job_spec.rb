# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchedMigrationJob, feature_category: :database do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  describe '.generic_instance' do
    it 'defines generic instance with only some of the attributes set' do
      generic_instance = described_class.generic_instance(
        batch_table: 'projects', batch_column: 'id',
        job_arguments: %w[x y], connection: connection
      )

      expect(generic_instance.send(:batch_table)).to eq('projects')
      expect(generic_instance.send(:batch_column)).to eq('id')
      expect(generic_instance.instance_variable_get(:@job_arguments)).to eq(%w[x y])
      expect(generic_instance.send(:connection)).to eq(connection)

      %i[start_id end_id sub_batch_size pause_ms].each do |attr|
        expect(generic_instance.send(attr)).to eq(0)
      end
    end
  end

  describe '.job_arguments' do
    let(:job_class) do
      Class.new(described_class) do
        job_arguments :value_a, :value_b
      end
    end

    subject(:job_instance) do
      job_class.new(
        start_id: 1,
        end_id: 10,
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
      expect(job_class.job_arguments_count).to eq(2)
    end

    context 'when no job arguments are defined' do
      let(:job_class) do
        Class.new(described_class)
      end

      it 'job_arguments_count is 0' do
        expect(job_class.job_arguments_count).to eq(0)
      end
    end
  end

  describe '.operation_name' do
    subject(:perform_job) { job_instance.perform }

    let(:job_instance) do
      job_class.new(
        start_id: 1,
        end_id: 10,
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
        Class.new(described_class) do
          def perform
            each_sub_batch do |sub_batch|
              sub_batch.update_all('to_column = from_column')
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
      end

      after do
        connection.drop_table(:_test_table)
        connection.drop_table(:_test_insert_table)
      end

      it 'raises an exception' do
        expect { perform_job }.to raise_error(RuntimeError, /Operation name is required/)
      end
    end
  end

  describe '.scope_to' do
    subject(:job_instance) do
      job_class.new(
        start_id: 1,
        end_id: 10,
        batch_table: '_test_table',
        batch_column: 'id',
        sub_batch_size: 2,
        pause_ms: 1000,
        job_arguments: %w[a b],
        connection: connection
      )
    end

    context 'when additional scoping is defined' do
      let(:job_class) do
        Class.new(described_class) do
          job_arguments :value_a, :value_b
          scope_to ->(r) { "#{r}-#{value_a}-#{value_b}".upcase }
        end
      end

      it 'applies additional scope to the provided relation' do
        expect(job_instance.filter_batch('relation')).to eq('RELATION-A-B')
      end
    end

    context 'when there is no additional scoping defined' do
      let(:job_class) do
        Class.new(described_class) do
        end
      end

      it 'returns provided relation as is' do
        expect(job_instance.filter_batch('relation')).to eq('relation')
      end
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
          feature_category :delivery
        end
      end

      it 'returns the provided value' do
        expect(job_class.feature_category).to eq(:delivery)
      end
    end
  end

  describe 'descendants', :eager_load do
    it 'have the same method signature for #perform' do
      expected_arity = described_class.instance_method(:perform).arity
      offences = described_class.descendants.select { |klass| klass.instance_method(:perform).arity != expected_arity }

      expect(offences).to be_empty, "expected no descendants of #{described_class} to accept arguments for " \
        "'#perform', but some do: #{offences.join(', ')}"
    end

    it 'do not use .batching_scope' do
      offences = described_class.descendants.select { |klass| klass.respond_to?(:batching_scope) }

      expect(offences).to be_empty, "expected no descendants of #{described_class} to define '.batching_scope', " \
        "but some do: #{offences.join(', ')}"
    end
  end

  describe '#perform' do
    let(:connection) { Gitlab::Database.database_base_models[:main].connection }

    let(:job_class) { Class.new(described_class) }

    let(:job_instance) do
      job_class.new(
        start_id: 1,
        end_id: 10,
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

    context 'when the subclass uses sub-batching' do
      let(:job_class) do
        Class.new(described_class) do
          operation_name :update

          def perform(*job_arguments)
            each_sub_batch(
              batching_arguments: { order_hint: :updated_at },
              batching_scope: ->(relation) { relation.where.not(bar: nil) }
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

      context 'with additional scoping' do
        let(:job_class) do
          Class.new(described_class) do
            scope_to ->(r) { r.where('mod(id, 2) = 0') }
            operation_name :update

            def perform(*job_arguments)
              each_sub_batch(
                batching_arguments: { order_hint: :updated_at },
                batching_scope: ->(relation) { relation.where.not(bar: nil) }
              ) do |sub_batch|
                sub_batch.update_all('to_column = from_column')
              end
            end
          end
        end

        it 'respects #filter_batch' do
          expect { perform_job }.to change { test_table.where(to_column: nil).count }.from(4).to(2)

          expect(test_table.order(:id).pluck(:to_column)).to contain_exactly(nil, 10, nil, 20)
        end
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

      context 'when using a sub batch exception for timeouts' do
        let(:job_class) do
          Class.new(described_class) do
            operation_name :update

            def perform(*_)
              each_sub_batch { raise ActiveRecord::StatementTimeout } # rubocop:disable Lint/UnreachableLoop
            end
          end
        end

        let(:job_instance) do
          job_class.new(
            start_id: 1,
            end_id: 10,
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

      context 'when batching_arguments are given' do
        it 'forwards them for batching' do
          expect(job_instance).to receive(:base_relation).and_return(test_table)

          expect(test_table).to receive(:each_batch).with(column: 'id', of: 2, order_hint: :updated_at)

          perform_job
        end
      end
    end

    context 'when the subclass uses distinct each batch' do
      let(:job_instance) do
        job_class.new(
          start_id: 1,
          end_id: 100,
          batch_table: '_test_table',
          batch_column: 'from_column',
          sub_batch_size: 2,
          pause_ms: 10,
          connection: connection
        )
      end

      let(:job_class) do
        Class.new(described_class) do
          operation_name :insert

          def perform(*job_arguments)
            distinct_each_batch do |sub_batch|
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

      context 'when used in combination with scope_to' do
        let(:job_class) do
          Class.new(described_class) do
            scope_to ->(r) { r.where.not(from_column: 10) }
            operation_name :insert

            def perform(*job_arguments)
              distinct_each_batch do |sub_batch|
              end
            end
          end
        end

        it 'raises an error' do
          expect { perform_job }.to raise_error RuntimeError,
            /distinct_each_batch can not be used when additional filters are defined with scope_to/
        end
      end
    end
  end
end
