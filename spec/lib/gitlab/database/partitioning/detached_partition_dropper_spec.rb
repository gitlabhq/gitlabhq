# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::DetachedPartitionDropper do
  include Database::TableSchemaHelpers

  let(:connection) { ActiveRecord::Base.connection }

  def expect_partition_present(name)
    aggregate_failures do
      expect(table_oid(name)).not_to be_nil
      expect(Postgresql::DetachedPartition.find_by(table_name: name)).not_to be_nil
    end
  end

  def expect_partition_removed(name)
    aggregate_failures do
      expect(table_oid(name)).to be_nil
      expect(Postgresql::DetachedPartition.find_by(table_name: name)).to be_nil
    end
  end

  before do
    connection.execute(<<~SQL)
      CREATE TABLE parent_table (
         id bigserial not null,
         created_at timestamptz not null,
         primary key (id, created_at)
       ) PARTITION BY RANGE(created_at)
    SQL
  end

  def create_partition(name:, table: 'parent_table', from:, to:, attached:, drop_after:)
    from = from.beginning_of_month
    to = to.beginning_of_month
    full_name = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{name}"
    connection.execute(<<~SQL)
      CREATE TABLE #{full_name}
      PARTITION OF #{table}
      FOR VALUES FROM ('#{from.strftime('%Y-%m-%d')}') TO ('#{to.strftime('%Y-%m-%d')}')
    SQL

    unless attached
      connection.execute(<<~SQL)
        ALTER TABLE #{table} DETACH PARTITION #{full_name}
      SQL
    end

    Postgresql::DetachedPartition.create!(table_name: name,
                                          drop_after: drop_after)
  end

  describe '#perform' do
    context 'when the partition should not be dropped yet' do
      it 'does not drop the partition' do
        create_partition(name: 'test_partition',
                         from: 2.months.ago, to: 1.month.ago,
                         attached: false,
                         drop_after: 1.day.from_now)

        subject.perform

        expect_partition_present('test_partition')
      end
    end

    context 'with a partition to drop' do
      before do
        create_partition(name: 'test_partition',
                         from: 2.months.ago,
                         to: 1.month.ago.beginning_of_month,
                         attached: false,
                         drop_after: 1.second.ago)
      end

      it 'drops the partition' do
        subject.perform

        expect(table_oid('test_partition')).to be_nil
      end

      context 'when the drop_detached_partitions feature flag is disabled' do
        before do
          stub_feature_flags(drop_detached_partitions: false)
        end
        it 'does not drop the partition' do
          subject.perform

          expect(table_oid('test_partition')).not_to be_nil
        end
      end

      context 'when another process drops the table while the first waits for a lock' do
        it 'skips the table' do
          # Rspec's receive_method_chain does not support .and_wrap_original, so we need to nest here.
          expect(Postgresql::DetachedPartition).to receive(:lock).and_wrap_original do |lock_meth|
            locked = lock_meth.call
            expect(locked).to receive(:find_by).and_wrap_original do |find_meth, *find_args|
              # Another process drops the table then deletes this entry
              Postgresql::DetachedPartition.where(*find_args).delete_all
              find_meth.call(*find_args)
            end

            locked
          end

          expect(subject).not_to receive(:drop_one)

          subject.perform
        end
      end
    end

    context 'when the partition to drop is still attached to its table' do
      before do
        create_partition(name: 'test_partition',
                         from: 2.months.ago,
                         to: 1.month.ago.beginning_of_month,
                         attached: true,
                         drop_after: 1.second.ago)
      end

      it 'does not drop the partition, but does remove the DetachedPartition entry' do
        subject.perform
        aggregate_failures do
          expect(table_oid('test_partition')).not_to be_nil
          expect(Postgresql::DetachedPartition.find_by(table_name: 'test_partition')).to be_nil
        end
      end

      it 'removes the detached_partition entry' do
        detached_partition = Postgresql::DetachedPartition.find_by!(table_name: 'test_partition')

        subject.perform

        expect(Postgresql::DetachedPartition.exists?(id: detached_partition.id)).to be_falsey
      end
    end

    context 'with multiple partitions to drop' do
      before do
        create_partition(name: 'partition_1',
                         from: 3.months.ago,
                         to: 2.months.ago,
                         attached: false,
                         drop_after: 1.second.ago)

        create_partition(name: 'partition_2',
                         from: 2.months.ago,
                         to: 1.month.ago,
                         attached: false,
                         drop_after: 1.second.ago)
      end

      it 'drops both partitions' do
        subject.perform

        expect_partition_removed('partition_1')
        expect_partition_removed('partition_2')
      end

      context 'when the first drop returns an error' do
        it 'still drops the second partition' do
          expect(subject).to receive(:drop_one).ordered.and_raise('injected error')
          expect(subject).to receive(:drop_one).ordered.and_call_original

          subject.perform

          # We don't know which partition we tried to drop first, so the tests here have to work with either one
          expect(Postgresql::DetachedPartition.count).to eq(1)
          errored_partition_name = Postgresql::DetachedPartition.first!.table_name

          dropped_partition_name = (%w[partition_1 partition_2] - [errored_partition_name]).first
          expect_partition_present(errored_partition_name)
          expect_partition_removed(dropped_partition_name)
        end
      end
    end
  end
end
