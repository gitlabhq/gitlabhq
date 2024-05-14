# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable::Organizer, feature_category: :continuous_integration do
  describe '.new_partition_required?' do
    subject(:new_partition_required) { described_class.new_partition_required?(partition_id) }

    let(:partition_id) { Ci::Pipeline::INITIAL_PARTITION_VALUE }

    context 'with ci_partitioning_first_records disabled' do
      before do
        stub_feature_flags(ci_partitioning_first_records: false)
      end

      it 'does not create Ci::Partition record' do
        expect { new_partition_required }.not_to change { Ci::Partition.count }
      end
    end

    context 'when first record does not exist' do
      before do
        described_class.clear_memoization(:insert_first_partitions)
      end

      it 'creates Ci::Partition records' do
        expect { new_partition_required }.to change { Ci::Partition.count }.by(3)
      end
    end

    context 'when first records exist' do
      before do
        create_list(:ci_partition, 3)
      end

      it 'does not create Ci::Partition record' do
        expect { new_partition_required }.not_to change { Ci::Partition.count }
      end
    end

    context 'when partition size is greater than the current partition size' do
      let(:partition_id) { Ci::Pipeline::SECOND_PARTITION_VALUE.next }

      it { is_expected.to eq(false) }
    end

    context 'when partition size is less than the current partition size' do
      let(:partition_id) { Ci::Pipeline::INITIAL_PARTITION_VALUE - 1 }

      it { is_expected.to eq(true) }
    end
  end
end
