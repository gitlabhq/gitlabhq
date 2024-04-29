# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::DetachedPartitionDropper do
  include Database::TableSchemaHelpers

  subject(:dropper) { described_class.new }

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
      CREATE TABLE _test_referenced_table (
        id bigserial primary key not null
      )
    SQL
    connection.execute(<<~SQL)

      CREATE TABLE _test_parent_table (
         id bigserial not null,
         referenced_id bigint not null,
         created_at timestamptz not null,
         primary key (id, created_at),
        constraint fk_referenced foreign key (referenced_id) references _test_referenced_table(id)
       ) PARTITION BY RANGE(created_at)
    SQL
  end

  def create_partition(name:, from:, to:, attached:, drop_after:, table: :_test_parent_table)
    from = from.beginning_of_month.to_date
    to = to.beginning_of_month.to_date
    full_name = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{name}"
    connection.execute(<<~SQL)
      CREATE TABLE #{full_name}
      PARTITION OF #{table}
      FOR VALUES FROM ('#{from.iso8601}') TO ('#{to.iso8601}')
    SQL

    unless attached
      connection.execute(<<~SQL)
        ALTER TABLE #{table} DETACH PARTITION #{full_name}
      SQL
    end

    Postgresql::DetachedPartition.create!(table_name: name, drop_after: drop_after)
  end

  describe '#perform' do
    context 'when the partition should not be dropped yet' do
      it 'does not drop the partition' do
        create_partition(
          name: :_test_partition,
          from: 2.months.ago,
          to: 1.month.ago,
          attached: false,
          drop_after: 1.day.from_now
        )

        dropper.perform

        expect_partition_present(:_test_partition)
      end
    end

    context 'with a partition to drop' do
      before do
        create_partition(
          name: :_test_partition,
          from: 2.months.ago,
          to: 1.month.ago.beginning_of_month,
          attached: false,
          drop_after: 1.second.ago
        )
      end

      it 'drops the partition' do
        dropper.perform

        expect(table_oid(:_test_partition)).to be_nil
      end

      context 'removing foreign keys' do
        it 'removes foreign keys from the table before dropping it' do
          expect(dropper).to receive(:drop_detached_partition).and_wrap_original do |drop_method, partition|
            expect(partition.table_name).to eq('_test_partition')
            expect(foreign_key_exists_by_name(partition.table_name, 'fk_referenced', schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)).to be_falsey

            drop_method.call(partition)
          end

          expect(foreign_key_exists_by_name(:_test_partition, 'fk_referenced', schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)).to be_truthy

          dropper.perform
        end

        it 'does not remove foreign keys from the parent table' do
          expect { dropper.perform }.not_to change { foreign_key_exists_by_name('_test_parent_table', 'fk_referenced') }.from(true)
        end

        context 'when another process drops the foreign key' do
          it 'skips dropping that foreign key' do
            expect(dropper).to receive(:drop_foreign_key_if_present).and_wrap_original do |drop_meth, *args|
              connection.execute('alter table gitlab_partitions_dynamic._test_partition drop constraint fk_referenced;')
              drop_meth.call(*args)
            end

            dropper.perform

            expect_partition_removed(:_test_partition)
          end
        end

        context 'when another process drops the partition' do
          it 'skips dropping the foreign key' do
            expect(dropper).to receive(:drop_foreign_key_if_present).and_wrap_original do |drop_meth, *args|
              connection.execute('drop table gitlab_partitions_dynamic._test_partition')
              Postgresql::DetachedPartition.where(table_name: :_test_partition).delete_all
            end

            expect(Gitlab::AppLogger).not_to receive(:error)
            dropper.perform
          end
        end
      end

      context 'when another process drops the table while the first waits for a lock' do
        it 'skips the table' do
          # First call to .lock is for removing foreign keys
          expect(Postgresql::DetachedPartition).to receive(:lock).once.ordered.and_call_original
          # Rspec's receive_method_chain does not support .and_wrap_original, so we need to nest here.
          expect(Postgresql::DetachedPartition).to receive(:lock).once.ordered.and_wrap_original do |lock_meth|
            locked = lock_meth.call
            expect(locked).to receive(:find_by).and_wrap_original do |find_meth, *find_args|
              # Another process drops the table then deletes this entry
              Postgresql::DetachedPartition.where(*find_args).delete_all
              find_meth.call(*find_args)
            end

            locked
          end

          expect(dropper).not_to receive(:drop_one)

          dropper.perform
        end
      end
    end

    context 'when the partition to drop is still attached to its table' do
      before do
        create_partition(
          name: :_test_partition,
          from: 2.months.ago,
          to: 1.month.ago.beginning_of_month,
          attached: true,
          drop_after: 1.second.ago
        )
      end

      it 'does not drop the partition, but does remove the DetachedPartition entry' do
        dropper.perform
        aggregate_failures do
          expect(table_oid(:_test_partition)).not_to be_nil
          expect(Postgresql::DetachedPartition.find_by(table_name: :_test_partition)).to be_nil
        end
      end

      context 'when another process removes the entry before this process' do
        it 'does nothing' do
          expect(Postgresql::DetachedPartition).to receive(:lock).and_wrap_original do |lock_meth|
            Postgresql::DetachedPartition.delete_all
            lock_meth.call
          end

          expect(Gitlab::AppLogger).not_to receive(:error)

          dropper.perform

          expect(table_oid(:_test_partition)).not_to be_nil
        end
      end
    end

    context 'with multiple partitions to drop' do
      before do
        create_partition(
          name: :_test_partition_1,
          from: 3.months.ago,
          to: 2.months.ago,
          attached: false,
          drop_after: 1.second.ago
        )

        create_partition(
          name: :_test_partition_2,
          from: 2.months.ago,
          to: 1.month.ago,
          attached: false,
          drop_after: 1.second.ago
        )
      end

      it 'drops both partitions' do
        dropper.perform

        expect_partition_removed(:_test_partition_1)
        expect_partition_removed(:_test_partition_2)
      end

      context 'when the first drop returns an error' do
        it 'still drops the second partition' do
          expect(dropper).to receive(:drop_detached_partition).ordered.and_raise('injected error')
          expect(dropper).to receive(:drop_detached_partition).ordered.and_call_original

          dropper.perform

          # We don't know which partition we tried to drop first, so the tests here have to work with either one
          expect(Postgresql::DetachedPartition.count).to eq(1)
          errored_partition_name = Postgresql::DetachedPartition.first!.table_name

          dropped_partition_name = (%w[_test_partition_1 _test_partition_2] - [errored_partition_name]).first
          expect_partition_present(errored_partition_name)
          expect_partition_removed(dropped_partition_name)
        end
      end
    end
  end
end
