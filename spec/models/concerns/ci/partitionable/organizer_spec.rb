# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable::Organizer, feature_category: :continuous_integration do
  describe '.create_database_partition?' do
    subject(:create_database_partition) { described_class.create_database_partition?(database_partition) }

    let(:parent_table_name) { 'p_ci_pipeline_variables' }
    let(:partition_name) { 'ci_pipeline_variables_102' }
    let(:schema) { 'gitlab_partitions_dynamic' }
    let(:database_partition) do
      Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
        parent_table_name,
        [Ci::Pipeline::NEXT_PARTITION_VALUE],
        partition_name: partition_name,
        schema: schema
      )
    end

    context 'when partition size is greater than the current partition size' do
      it { is_expected.to eq(false) }
    end

    context 'when partition size is less than the current partition size' do
      before do
        allow(database_partition).to receive_message_chain(:values,
          :max).and_return(Ci::Pipeline::INITIAL_PARTITION_VALUE)
      end

      it { is_expected.to eq(true) }
    end
  end
end
