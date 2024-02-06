# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable do
  let(:ci_model) { Class.new(Ci::ApplicationRecord) }

  around do |ex|
    Gitlab::Database::SharedModel.using_connection(ci_model.connection) do
      ex.run
    end
  end

  describe 'partitionable models inclusion' do
    subject { ci_model.include(described_class) }

    it 'raises an exception' do
      expect { subject }
        .to raise_error(/must be included in PARTITIONABLE_MODELS/)
    end

    context 'when is included in the models list' do
      before do
        stub_const("#{described_class}::Testing::PARTITIONABLE_MODELS", [ci_model.name])
      end

      it 'does not raise exceptions' do
        expect { subject }.not_to raise_error
      end
    end
  end

  context 'with through options' do
    let(:disable_partitionable_switch) { nil }

    before do
      stub_env('DISABLE_PARTITIONABLE_SWITCH', disable_partitionable_switch)

      allow(ActiveSupport::DescendantsTracker).to receive(:store_inherited)
      stub_const("#{described_class}::Testing::PARTITIONABLE_MODELS", [ci_model.name])

      ci_model.include(described_class)
      ci_model.partitionable scope: ->(r) { 1 },
        through: { table: :_test_table_name, flag: :some_flag }
    end

    it { expect(ci_model.routing_table_name).to eq(:_test_table_name) }

    it { expect(ci_model.routing_table_name_flag).to eq(:some_flag) }

    it { expect(ci_model.ancestors).to include(described_class::Switch) }

    context 'when DISABLE_PARTITIONABLE_SWITCH is set' do
      let(:disable_partitionable_switch) { true }

      it { expect(ci_model.ancestors).not_to include(described_class::Switch) }
    end
  end

  context 'with partitioned options' do
    before do
      stub_const("#{described_class}::Testing::PARTITIONABLE_MODELS", [ci_model.name])

      ci_model.include(described_class)
      ci_model.partitionable scope: ->(r) { 1 }, partitioned: partitioned
    end

    context 'when partitioned is true' do
      let(:partitioned) { true }
      let(:partitioning_strategy) { ci_model.partitioning_strategy }

      it { expect(ci_model.ancestors).to include(PartitionedTable) }
      it { expect(partitioning_strategy).to be_a(Gitlab::Database::Partitioning::CiSlidingListStrategy) }
      it { expect(partitioning_strategy.partitioning_key).to eq(:partition_id) }

      describe 'next_partition_if callback' do
        let(:active_partition) { partitioning_strategy.active_partition }

        let(:table_options) do
          {
            primary_key: [:id, :partition_id],
            options: 'PARTITION BY LIST (partition_id)',
            if_not_exists: false
          }
        end

        before do
          ci_model.connection.create_table(:_test_table_name, **table_options) do |t|
            t.bigserial :id, null: false
            t.bigint :partition_id, null: false
          end

          ci_model.table_name = :_test_table_name
        end

        subject(:value) { partitioning_strategy.next_partition_if.call(active_partition) }

        context 'without any existing partitions' do
          it { is_expected.to eq(true) }
        end

        context 'with initial partition attached' do
          before do
            ci_model.connection.execute(<<~SQL)
              CREATE TABLE IF NOT EXISTS _test_table_name_100 PARTITION OF _test_table_name FOR VALUES IN (100);
            SQL
          end

          it { is_expected.to eq(true) }
        end

        context 'with an existing partition for partition_id = 101' do
          before do
            ci_model.connection.execute(<<~SQL)
              CREATE TABLE IF NOT EXISTS _test_table_name_101 PARTITION OF _test_table_name FOR VALUES IN (101);
            SQL
          end

          it { is_expected.to eq(false) }
        end

        context 'with an existing partition for partition_id in 100, 101' do
          before do
            ci_model.connection.execute(<<~SQL)
              CREATE TABLE IF NOT EXISTS _test_table_name_101 PARTITION OF _test_table_name FOR VALUES IN (100, 101);
            SQL
          end

          it { is_expected.to eq(false) }
        end
      end
    end

    context 'when partitioned is false' do
      let(:partitioned) { false }

      it { expect(ci_model.ancestors).not_to include(PartitionedTable) }
      it { expect(ci_model).not_to respond_to(:partitioning_strategy) }
    end
  end

  describe '.in_partition' do
    before do
      stub_const("#{described_class}::Testing::PARTITIONABLE_MODELS", [ci_model.name])
      ci_model.table_name = :p_ci_builds
      ci_model.include(described_class)
    end

    subject(:scope_values) { ci_model.in_partition(value).where_values_hash }

    context 'with integer parameters' do
      let(:value) { 101 }

      it 'adds a partition_id filter' do
        expect(scope_values).to include('partition_id' => 101)
      end
    end

    context 'with partitionable records' do
      let(:value) { build_stubbed(:ci_pipeline, partition_id: 101) }

      it 'adds a partition_id filter' do
        expect(scope_values).to include('partition_id' => 101)
      end
    end
  end
end
