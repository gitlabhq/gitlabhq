# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchedGitRefUpdates::Deletion, feature_category: :gitaly do
  describe '.mark_records_processed' do
    let_it_be(:deletion_1) { described_class.create!(project_id: 5, ref: 'refs/test/1') }
    let_it_be(:deletion_2) { described_class.create!(project_id: 1, ref: 'refs/test/2') }
    let_it_be(:deletion_3) { described_class.create!(project_id: 3, ref: 'refs/test/3') }
    let_it_be(:deletion_4) { described_class.create!(project_id: 1, ref: 'refs/test/4') }
    let_it_be(:deletion_5) { described_class.create!(project_id: 4, ref: 'refs/test/5', status: :processed) }

    it 'updates all records' do
      expect(described_class.status_pending.count).to eq(4)
      expect(described_class.status_processed.count).to eq(1)

      deletions = described_class.for_project(1).select_ref_and_identity
      described_class.mark_records_processed(deletions)

      deletions.each do |deletion|
        expect(deletion.reload.status).to eq("processed")
      end

      expect(described_class.status_pending.count).to eq(2)
      expect(described_class.status_processed.count).to eq(3)
    end
  end

  describe 'sliding_list partitioning' do
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    describe 'next_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition has records' do
        before do
          described_class.create!(project_id: 1, ref: 'refs/test/1', status: :processed)
          described_class.create!(project_id: 2, ref: 'refs/test/2', status: :pending)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          described_class.create!(
            project_id: 1,
            ref: 'refs/test/1',
            created_at: (described_class::PARTITION_DURATION + 1.day).ago)

          described_class.create!(project_id: 2, ref: 'refs/test/2')
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition contains unprocessed records' do
        before do
          described_class.create!(project_id: 1, ref: 'refs/test/1')
          described_class.create!(project_id: 2, ref: 'refs/test/2', status: :processed)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the partition contains only processed records' do
        before do
          described_class.create!(project_id: 1, ref: 'refs/test/1', status: :processed)
          described_class.create!(project_id: 2, ref: 'refs/test/2', status: :processed)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'the behavior of the strategy' do
      it 'moves records to new partitions as time passes', :freeze_time do
        # We start with partition 1
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # it's not a day old yet so no new partitions are created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # add one record so the next partition will be created
        described_class.create!(project_id: 1, ref: 'refs/test/1')

        # after traveling forward a day
        travel(described_class::PARTITION_DURATION + 1.second)

        # a new partition is created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to contain_exactly(1, 2)

        # and we can insert to the new partition
        described_class.create!(project_id: 2, ref: 'refs/test/2')

        # after processing old records
        described_class.mark_records_processed(described_class.for_partition(1).select_ref_and_identity)

        partition_manager.sync_partitions

        # the old one is removed
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([2])

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end
end
