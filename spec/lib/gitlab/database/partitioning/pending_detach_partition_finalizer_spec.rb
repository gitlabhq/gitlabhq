# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PendingDetachPartitionFinalizer, feature_category: :database do
  include Database::PartitioningHelpers
  include Database::TableSchemaHelpers

  subject(:finalizer) { described_class.new }

  let(:connection) { ActiveRecord::Base.connection }
  let(:schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }
  let(:referenced_table) { :_test_finalizer_referenced }
  let(:parent_table) { :_test_finalizer_referencing }

  # Mirrors p_ci_job_definition_instances: a partitioned table whose foreign key references another
  # partitioned table on the same key
  before do
    connection.execute(<<~SQL)
      CREATE TABLE #{referenced_table} (
        partition_id bigint NOT NULL,
        id bigserial NOT NULL,
        PRIMARY KEY (partition_id, id)
      ) PARTITION BY LIST (partition_id);

      CREATE TABLE #{schema}.#{referenced_table}_100 PARTITION OF #{referenced_table} FOR VALUES IN (100);
      CREATE TABLE #{schema}.#{referenced_table}_101 PARTITION OF #{referenced_table} FOR VALUES IN (101);

      CREATE TABLE #{parent_table} (
        partition_id bigint NOT NULL,
        id bigserial NOT NULL,
        referenced_id bigint NOT NULL,
        PRIMARY KEY (partition_id, id),
        CONSTRAINT fk_test_finalizer FOREIGN KEY (partition_id, referenced_id)
          REFERENCES #{referenced_table} (partition_id, id) ON DELETE CASCADE
      ) PARTITION BY LIST (partition_id);

      CREATE TABLE #{schema}.#{parent_table}_100 PARTITION OF #{parent_table} FOR VALUES IN (100);
      CREATE TABLE #{schema}.#{parent_table}_101 PARTITION OF #{parent_table} FOR VALUES IN (101);
    SQL
  end

  def pending?(name)
    Gitlab::Database::PostgresPartition.for_identifier("#{schema}.#{name}").pending_detach.exists?
  end

  def attached?(name)
    Gitlab::Database::PostgresPartition.for_identifier("#{schema}.#{name}").exists?
  end

  def pg_partition(name)
    Gitlab::Database::PostgresPartition.for_identifier("#{schema}.#{name}").first
  end

  def schedule_drop(name)
    Postgresql::DetachedPartition.create!(table_name: name, drop_after: 1.week.from_now)
  end

  describe '#perform' do
    context 'when a pending partition has a scheduled drop' do
      before do
        mark_pending_detach("#{parent_table}_100")
        schedule_drop("#{parent_table}_100")
      end

      it 'finalizes only that partition and keeps its table for the dropper' do
        finalizer.perform

        # A fully detached partition is absent from the view but its table still exists
        expect(attached?("#{parent_table}_100")).to be(false)
        expect(table_oid("#{parent_table}_100")).not_to be_nil
        expect(attached?("#{parent_table}_101")).to be(true)
      end
    end

    context 'when a pending partition has no scheduled drop' do
      before do
        mark_pending_detach("#{parent_table}_100")
      end

      it 'leaves it pending and warns' do
        allow(Gitlab::AppLogger).to receive(:warn)
        expect(Gitlab::AppLogger).to receive(:warn).with(hash_including(
          'message' => 'Skipped finalizing a pending detach partition without a scheduled drop',
          'partition_name' => "#{parent_table}_100"
        ))

        finalizer.perform

        expect(pending?("#{parent_table}_100")).to be(true)
      end
    end

    context 'when finalizing one partition fails' do
      before do
        mark_pending_detach("#{parent_table}_100")
        mark_pending_detach("#{referenced_table}_101")
        schedule_drop("#{parent_table}_100")
        schedule_drop("#{referenced_table}_101")

        allow(finalizer).to receive(:finalize).and_call_original
        allow(finalizer).to receive(:finalize)
          .with(having_attributes(name: "#{parent_table}_100"))
          .and_raise(ActiveRecord::StatementInvalid, 'boom')
      end

      it 'logs the error and finalizes the others' do
        allow(Gitlab::AppLogger).to receive(:error)
        expect(Gitlab::AppLogger).to receive(:error).with(hash_including(
          'message' => 'Failed to finalize a pending detach partition',
          'partition_name' => "#{parent_table}_100"
        ))

        finalizer.perform

        expect(pending?("#{parent_table}_100")).to be(true)
        expect(attached?("#{referenced_table}_101")).to be(false)
      end
    end
  end

  describe '#finalize' do
    before do
      mark_pending_detach("#{parent_table}_100")
    end

    it 'locks the referenced tables, then the parent, before finalizing' do
      allow(connection).to receive(:execute).and_call_original

      expect(connection).to receive(:execute)
        .with(/LOCK TABLE "public"\."#{referenced_table}" IN SHARE ROW EXCLUSIVE MODE/).ordered.and_call_original
      expect(connection).to receive(:execute)
        .with(/LOCK TABLE ONLY "public"\."#{parent_table}" IN SHARE UPDATE EXCLUSIVE MODE/).ordered.and_call_original
      expect(connection).to receive(:execute).with(/DETACH PARTITION .* FINALIZE/m).ordered.and_call_original

      finalizer.finalize(pg_partition("#{parent_table}_100"))

      expect(attached?("#{parent_table}_100")).to be(false)
    end

    it 'logs the finalized partition' do
      allow(Gitlab::AppLogger).to receive(:info)
      expect(Gitlab::AppLogger).to receive(:info)
        .with(message: 'Finalized a pending detach partition', partition_name: "#{parent_table}_100")

      finalizer.finalize(pg_partition("#{parent_table}_100"))
    end

    context 'when the partition references no other table' do
      before do
        mark_pending_detach("#{referenced_table}_100")
      end

      it 'locks only the parent before finalizing' do
        allow(connection).to receive(:execute).and_call_original

        expect(connection).not_to receive(:execute).with(/IN SHARE ROW EXCLUSIVE MODE/)
        expect(connection).to receive(:execute)
          .with(/LOCK TABLE ONLY "public"\."#{referenced_table}" IN SHARE UPDATE EXCLUSIVE MODE/).and_call_original

        finalizer.finalize(pg_partition("#{referenced_table}_100"))

        expect(attached?("#{referenced_table}_100")).to be(false)
      end
    end

    context 'when another process finalized it while we waited for the locks' do
      let!(:stale_partition) { pg_partition("#{parent_table}_100") }

      before do
        connection.execute(<<~SQL)
          ALTER TABLE #{parent_table} DETACH PARTITION #{schema}.#{parent_table}_100 FINALIZE
        SQL
      end

      it 'skips the FINALIZE without an error' do
        expect(connection).not_to receive(:execute).with(/FINALIZE/)
        expect(Gitlab::AppLogger).not_to receive(:info)
          .with(hash_including(message: 'Finalized a pending detach partition'))

        expect { finalizer.finalize(stale_partition) }.not_to raise_error
      end
    end

    context 'when ci_finalize_pending_detach_partitions_daily is disabled' do
      before do
        stub_feature_flags(ci_finalize_pending_detach_partitions_daily: false)
      end

      it 'finalizes without taking the locks first' do
        allow(connection).to receive(:execute).and_call_original
        expect(connection).not_to receive(:execute).with(/LOCK TABLE/)

        finalizer.finalize(pg_partition("#{parent_table}_100"))

        expect(attached?("#{parent_table}_100")).to be(false)
      end
    end
  end
end
