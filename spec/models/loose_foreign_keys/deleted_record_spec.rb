# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::DeletedRecord, type: :model, feature_category: :database do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:table) { 'public.projects' }

  describe 'class methods' do
    let_it_be(:deleted_record_1) { described_class.create!(fully_qualified_table_name: table, primary_key_value: 5, cleanup_attempts: 2) }
    let_it_be(:deleted_record_2) { described_class.create!(fully_qualified_table_name: table, primary_key_value: 1, cleanup_attempts: 0) }
    let_it_be(:deleted_record_3) { described_class.create!(fully_qualified_table_name: 'public.other_table', primary_key_value: 3) }
    let_it_be(:deleted_record_4) { described_class.create!(fully_qualified_table_name: table, primary_key_value: 1, cleanup_attempts: 1) } # duplicate

    let(:records) { described_class.load_batch_for_table(table, 10) }

    describe '.load_batch_for_table' do
      it 'loads records and orders them by creation date' do
        expect(records).to eq([deleted_record_1, deleted_record_2, deleted_record_4])
      end

      it 'supports configurable batch size' do
        records = described_class.load_batch_for_table(table, 2)

        expect(records).to eq([deleted_record_1, deleted_record_2])
      end

      it 'returns the partition number in each returned record' do
        records = described_class.load_batch_for_table(table, 4)

        expect(records).to all(have_attributes(partition: (a_value > 0)))
      end
    end

    describe '.mark_records_processed' do
      it 'updates all records' do
        described_class.mark_records_processed(records)

        expect(described_class.status_pending.count).to eq(1)
        expect(described_class.status_processed.count).to eq(3)
      end
    end

    describe '.reschedule' do
      it 'reschedules all records' do
        time = Time.zone.parse('2022-01-01').utc
        update_count = described_class.reschedule(records, time)

        expect(update_count).to eq(records.size)

        records.each(&:reload)

        expect(records).to all(have_attributes(
          cleanup_attempts: 0,
          consume_after: time
        ))
      end
    end

    describe '.increment_attempts' do
      it 'increaments the cleanup_attempts column' do
        described_class.increment_attempts(records)

        expect(deleted_record_1.reload.cleanup_attempts).to eq(3)
        expect(deleted_record_2.reload.cleanup_attempts).to eq(1)
        expect(deleted_record_4.reload.cleanup_attempts).to eq(2)
      end
    end
  end

  describe 'sliding_list partitioning' do
    let(:connection) { described_class.connection }
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    describe 'next_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition has records' do
        before do
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1, status: :processed)
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2, status: :pending)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          described_class.create!(
            fully_qualified_table_name: 'public.table',
            primary_key_value: 1,
            created_at: (described_class::PARTITION_DURATION + 1.day).ago)

          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition contains unprocessed records' do
        before do
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1, status: :processed)
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2, status: :pending)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the partition contains only processed records' do
        before do
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1, status: :processed)
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2, status: :processed)
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
        described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1)

        # after traveling forward a day
        travel(described_class::PARTITION_DURATION + 1.second)

        # a new partition is created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1, 2])

        # and we can insert to the new partition
        expect { described_class.create!(fully_qualified_table_name: table, primary_key_value: 5) }.not_to raise_error

        # after processing old records
        described_class.for_partition(1).update_all(status: :processed)

        partition_manager.sync_partitions

        # the old one is removed
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([2])

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end
end
