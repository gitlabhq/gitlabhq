# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::DetachEligibility, feature_category: :database do
  let(:connection) { ActiveRecord::Base.connection }
  let(:referenced_table) { :_test_gitlab_main_referenced_parent }
  let(:referencing_table) { :_test_gitlab_main_referencing_parent }
  let(:dynamic_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }

  let(:partition) do
    Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
      referenced_table, [100], partition_name: "#{referenced_table}_100"
    )
  end

  let(:check) { described_class.new(partition, connection: connection) }

  subject(:blocker) do
    check.detachable?
    check.blocker # populated only after #detachable? has run
  end

  before do
    connection.execute(<<~SQL)
      CREATE TABLE #{referenced_table} (
        partition_id bigint NOT NULL,
        id bigserial NOT NULL,
        PRIMARY KEY (partition_id, id)
      ) PARTITION BY LIST (partition_id);

      CREATE TABLE #{dynamic_schema}.#{referenced_table}_100
        PARTITION OF #{referenced_table} FOR VALUES IN (100);
    SQL
  end

  context 'when nothing references the parent table' do
    it 'is detachable, and records no blocker' do
      expect(check.detachable?).to be(true)
      expect(check.blocker).to be_nil
    end
  end

  context 'when a table references the parent table' do
    shared_examples 'a partition blocked by its referencing table' do
      it 'is not detachable' do
        expect(check.detachable?).to be(false)
      end

      it 'names the foreign key that blocks it' do
        expect(blocker.reason).to eq(:referencing_foreign_key)
        expect(blocker.level).to eq(:warn)
        expect(blocker.details).to eq(
          referencing_table: "public.#{referencing_table}",
          foreign_key_name: 'fk_test_referencing'
        )
      end
    end

    context 'and the referencing table is partitioned' do
      before do
        create_partitioned_referencing_table
      end

      it_behaves_like 'a partition blocked by its referencing table'
    end

    context 'and the referencing table is non-partitioned' do
      before do
        create_plain_referencing_table
      end

      it_behaves_like 'a partition blocked by its referencing table'
    end
  end

  context 'when the check runs against another connection' do
    let(:check) { described_class.new(partition, connection: Ci::ApplicationRecord.connection) }

    before do
      skip_if_shared_database(:ci)

      create_partitioned_referencing_table
    end

    # The referencing table only exists on main, so reading the ci catalog finds no foreign key
    it 'reads the catalog of the connection it was given' do
      expect(check.detachable?).to be(true)
    end
  end

  def create_partitioned_referencing_table
    connection.execute(<<~SQL)
      CREATE TABLE #{referencing_table} (
        partition_id bigint NOT NULL,
        id bigserial NOT NULL,
        referenced_id bigint NOT NULL,
        PRIMARY KEY (partition_id, id),
        CONSTRAINT fk_test_referencing FOREIGN KEY (partition_id, referenced_id)
          REFERENCES #{referenced_table} (partition_id, id)
      ) PARTITION BY LIST (partition_id);
    SQL
  end

  def create_plain_referencing_table
    connection.execute(<<~SQL)
      CREATE TABLE #{referencing_table} (
        id bigserial PRIMARY KEY NOT NULL,
        partition_id bigint NOT NULL,
        referenced_id bigint NOT NULL,
        CONSTRAINT fk_test_referencing FOREIGN KEY (partition_id, referenced_id)
          REFERENCES #{referenced_table} (partition_id, id)
      );
    SQL
  end
end
