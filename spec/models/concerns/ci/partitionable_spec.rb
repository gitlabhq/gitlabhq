# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable do
  let(:ci_model) { Class.new(Ci::ApplicationRecord) }

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
    before do
      allow(ActiveSupport::DescendantsTracker).to receive(:store_inherited)
      stub_const("#{described_class}::Testing::PARTITIONABLE_MODELS", [ci_model.name])

      ci_model.include(described_class)
      ci_model.partitionable scope: ->(r) { 1 },
        through: { table: :_test_table_name, flag: :some_flag }
    end

    it { expect(ci_model.routing_table_name).to eq(:_test_table_name) }

    it { expect(ci_model.routing_table_name_flag).to eq(:some_flag) }

    it { expect(ci_model.ancestors).to include(described_class::Switch) }
  end

  context 'with partitioned options' do
    before do
      stub_const("#{described_class}::Testing::PARTITIONABLE_MODELS", [ci_model.name])

      ci_model.include(described_class)
      ci_model.partitionable scope: ->(r) { 1 }, partitioned: partitioned
    end

    context 'when partitioned is true' do
      let(:partitioned) { true }

      it { expect(ci_model.ancestors).to include(PartitionedTable) }
      it { expect(ci_model.partitioning_strategy).to be_a(Gitlab::Database::Partitioning::CiSlidingListStrategy) }
      it { expect(ci_model.partitioning_strategy.partitioning_key).to eq(:partition_id) }
    end

    context 'when partitioned is false' do
      let(:partitioned) { false }

      it { expect(ci_model.ancestors).not_to include(PartitionedTable) }
      it { expect(ci_model).not_to respond_to(:partitioning_strategy) }
    end
  end
end
