# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::DetachEligibility, feature_category: :database do
  let(:connection) { ActiveRecord::Base.connection }
  let(:referenced_table) { :_test_gitlab_main_referenced_parent }
  let(:referencing_table) { :_test_gitlab_main_referencing_parent }
  let(:dynamic_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }

  let(:referenced_table_ddl) do
    <<~SQL
      #{partitioned_parent_ddl}

      CREATE TABLE #{dynamic_schema}.#{referenced_table}_100
        PARTITION OF #{referenced_table} FOR VALUES IN (100);

      CREATE TABLE #{dynamic_schema}.#{referenced_table}_101
        PARTITION OF #{referenced_table} FOR VALUES IN (101);
    SQL
  end

  let(:partition) do
    Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
      referenced_table, [100], partition_name: "#{referenced_table}_100"
    )
  end

  # nil until #detachable? has run, so every example asserting on it calls that first
  let(:blocker) { check.blocker }

  subject(:check) { described_class.new(partition, connection: connection) }

  before do
    connection.execute(referenced_table_ddl)
  end

  shared_examples 'a detachable partition' do
    it 'is detachable, and records no blocker' do
      expect(check.detachable?).to be(true)
      expect(check.blocker).to be_nil
    end
  end

  context 'when nothing references the parent table' do
    it_behaves_like 'a detachable partition'
  end

  context 'when the parent table is not list partitioned on a single column' do
    let(:referenced_table_ddl) do
      <<~SQL
        CREATE TABLE #{referenced_table} (
          created_at timestamptz NOT NULL,
          id bigserial NOT NULL,
          PRIMARY KEY (created_at, id)
        ) PARTITION BY RANGE (created_at);

        CREATE TABLE #{dynamic_schema}.#{referenced_table}_100
          PARTITION OF #{referenced_table} FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

        CREATE UNIQUE INDEX idx_test_referenced_created_at ON #{referenced_table} (created_at);

        CREATE TABLE #{referencing_table} (
          id bigserial PRIMARY KEY NOT NULL,
          referenced_at timestamptz NOT NULL,
          CONSTRAINT fk_test_referencing FOREIGN KEY (referenced_at)
            REFERENCES #{referenced_table} (created_at)
        );
      SQL
    end

    it 'warns that the partition key is unsupported' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:unsupported_partition_key)
      expect(blocker.level).to eq(:warn)
    end
  end

  context 'when the partition lives outside the dynamic partitions schema' do
    # ci_runners is list partitioned on runner_type, but keeps its partitions in public
    let(:referenced_table_ddl) do
      <<~SQL
        #{partitioned_parent_ddl}

        CREATE TABLE #{referenced_table}_100
          PARTITION OF #{referenced_table} FOR VALUES IN (100);
      SQL
    end

    before do
      create_partitioned_referencing_table
    end

    it 'warns that the partition ids are unsupported' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:unsupported_partition_ids)
      expect(blocker.level).to eq(:warn)
    end
  end

  context 'when another parent owns a partition of the same name' do
    let(:other_parent_table) { :_test_gitlab_main_other_parent }

    let(:referenced_table_ddl) do
      <<~SQL
        #{partitioned_parent_ddl}
        #{partitioned_parent_ddl(other_parent_table)}

        CREATE TABLE #{dynamic_schema}.#{referenced_table}_100
          PARTITION OF #{other_parent_table} FOR VALUES IN (100);
      SQL
    end

    before do
      create_partitioned_referencing_table
      create_referencing_partition(100)
    end

    it "does not read the other parent's partition ids" do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:unsupported_partition_ids)
      expect(blocker.level).to eq(:warn)
    end
  end

  context 'when a referencing table has a DEFAULT partition' do
    before do
      create_partitioned_referencing_table
      create_default_referencing_partition
    end

    it 'warns that the referencing table has a default partition' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:referencing_table_has_default_partition)
      expect(blocker.level).to eq(:warn)
      expect(blocker.details).to include(referencing_table: "public.#{referencing_table}")
    end
  end

  context 'when a plain table references the parent table' do
    before do
      create_plain_referencing_table
    end

    it 'warns that the referencing table cannot be pruned' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:referencing_table_cannot_prune)
      expect(blocker.level).to eq(:warn)
      expect(blocker.details).to include(
        referencing_table: "public.#{referencing_table}",
        foreign_key_name: 'fk_test_referencing'
      )
    end
  end

  context 'when a partitioned table references the parent table on a different key' do
    before do
      connection.execute(<<~SQL)
        CREATE UNIQUE INDEX idx_test_referenced_id ON #{referenced_table} (partition_id, id);

        CREATE TABLE #{referencing_table} (
          other_key bigint NOT NULL,
          partition_id bigint NOT NULL,
          referenced_id bigint NOT NULL,
          PRIMARY KEY (other_key, partition_id, referenced_id),
          CONSTRAINT fk_test_referencing FOREIGN KEY (partition_id, referenced_id)
            REFERENCES #{referenced_table} (partition_id, id)
        ) PARTITION BY LIST (other_key);
      SQL
    end

    it 'warns that the referencing table cannot be pruned' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:referencing_table_cannot_prune)
      expect(blocker.level).to eq(:warn)
    end
  end

  context 'when an attached referencing partition holds a non-inherited foreign key' do
    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{referencing_table} (
          partition_id bigint NOT NULL,
          id bigserial NOT NULL,
          referenced_id bigint NOT NULL,
          PRIMARY KEY (partition_id, id)
        ) PARTITION BY LIST (partition_id);
      SQL

      create_referencing_partition(100)

      connection.execute(<<~SQL)
        ALTER TABLE #{dynamic_schema}.#{referencing_table}_100
          ADD CONSTRAINT fk_test_referencing FOREIGN KEY (partition_id, referenced_id)
          REFERENCES #{referenced_table} (partition_id, id);
      SQL
    end

    it 'warns that the referencing table cannot be pruned' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:referencing_table_cannot_prune)
      expect(blocker.level).to eq(:warn)
    end
  end

  context 'when a partitioned table references the parent table on the same key' do
    before do
      create_partitioned_referencing_table
      create_referencing_partition(100)
      create_referencing_partition(101)
    end

    it 'informs that the counterpart partition is present' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:counterpart_partition_present)
      expect(blocker.level).to eq(:info)
      expect(blocker.details).to include(partition_id: 100)
    end

    context 'when the counterpart partition has been dropped' do
      before do
        connection.execute("DROP TABLE #{dynamic_schema}.#{referencing_table}_100")
      end

      it_behaves_like 'a detachable partition'

      context 'when another referencing partition has been detached' do
        before do
          connection.execute(
            "ALTER TABLE #{referencing_table} DETACH PARTITION #{dynamic_schema}.#{referencing_table}_101"
          )
        end

        it 'informs that a referencing partition is detached' do
          expect(check.detachable?).to be(false)
          expect(blocker.reason).to eq(:detached_referencing_partition)
          expect(blocker.level).to eq(:info)
          expect(blocker.details).to include(
            referencing_table: "#{dynamic_schema}.#{referencing_table}_101"
          )
        end

        context 'when its foreign keys have been stripped' do
          before do
            # DetachedPartitionDropper strips the foreign keys of a detached partition before dropping it
            identifier = "#{dynamic_schema}.#{referencing_table}_101"

            Gitlab::Database::PostgresForeignKey
              .by_constrained_table_identifier(identifier)
              .not_inherited
              .each { |fk| connection.execute("ALTER TABLE #{identifier} DROP CONSTRAINT #{fk.name}") }
          end

          it_behaves_like 'a detachable partition'
        end

        context 'when the referencing table also has a DEFAULT partition' do
          before do
            create_default_referencing_partition
          end

          # Confirms order of precedence of the checks
          it 'warns about the default partition instead of the detached one' do
            expect(check.detachable?).to be(false)
            expect(blocker.reason).to eq(:referencing_table_has_default_partition)
            expect(blocker.level).to eq(:warn)
          end
        end
      end
    end
  end

  context 'when the partition covers several ids' do
    let(:partition) do
      Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
        referenced_table, [102, 103], partition_name: "#{referenced_table}_multi"
      )
    end

    let(:referenced_table_ddl) do
      <<~SQL
        #{partitioned_parent_ddl}

        CREATE TABLE #{dynamic_schema}.#{referenced_table}_multi
          PARTITION OF #{referenced_table} FOR VALUES IN (102, 103);
      SQL
    end

    before do
      create_partitioned_referencing_table
      create_referencing_partition(103)
    end

    it 'names the blocking partition id' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:counterpart_partition_present)
      expect(blocker.details).to include(partition_id: 103)
    end

    context 'when every partition id has had its counterpart dropped' do
      before do
        connection.execute("DROP TABLE #{dynamic_schema}.#{referencing_table}_103")
      end

      it_behaves_like 'a detachable partition'
    end
  end

  context 'when a second table also references the parent table' do
    let(:other_referencing_table) { :_test_gitlab_main_other_referencing_parent }

    before do
      create_partitioned_referencing_table
      create_referencing_partition(101)

      create_partitioned_referencing_table(other_referencing_table)
      create_referencing_partition(100, other_referencing_table)
    end

    it 'names the referencing table that blocks it' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:counterpart_partition_present)
      expect(blocker.details).to include(
        referencing_table: "public.#{other_referencing_table}",
        partition_id: 100
      )
    end
  end

  context 'when the referencing table is partitioned on an integer key' do
    # Postgres renders an integer bound as FOR VALUES IN (100) and a bigint one as FOR VALUES IN ('100')
    before do
      create_partitioned_referencing_table(key_type: 'integer')
      create_referencing_partition(100)
    end

    it 'finds the counterpart partition' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:counterpart_partition_present)
      expect(blocker.details).to include(partition_id: 100)
    end
  end

  context 'when a referencing partition lives outside the dynamic partitions schema' do
    before do
      create_partitioned_referencing_table

      connection.execute(<<~SQL)
        CREATE TABLE #{referencing_table}_100
          PARTITION OF #{referencing_table} FOR VALUES IN (100);
      SQL
    end

    it 'treats it as the counterpart, not an unprunable table' do
      expect(check.detachable?).to be(false)
      expect(blocker.reason).to eq(:counterpart_partition_present)
      expect(blocker.details).to include(partition_id: 100)
    end
  end

  context 'when the check runs against another connection' do
    subject(:check) { described_class.new(partition, connection: Ci::ApplicationRecord.connection) }

    before do
      skip_if_shared_database(:ci)

      create_partitioned_referencing_table
    end

    # The referencing table only exists on main, so reading the ci catalog finds no foreign key
    it 'reads the catalog of the connection it was given' do
      expect(check.detachable?).to be(true)
    end
  end

  private

  def partitioned_parent_ddl(name = referenced_table)
    <<~SQL
      CREATE TABLE #{name} (
        partition_id bigint NOT NULL,
        id bigserial NOT NULL,
        PRIMARY KEY (partition_id, id)
      ) PARTITION BY LIST (partition_id);
    SQL
  end

  def create_partitioned_referencing_table(name = referencing_table, key_type: 'bigint')
    connection.execute(<<~SQL)
      CREATE TABLE #{name} (
        partition_id #{key_type} NOT NULL,
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

  def create_referencing_partition(partition_id, name = referencing_table)
    connection.execute(<<~SQL)
      CREATE TABLE #{dynamic_schema}.#{name}_#{partition_id}
        PARTITION OF #{name} FOR VALUES IN (#{partition_id});
    SQL
  end

  def create_default_referencing_partition
    connection.execute(<<~SQL)
      CREATE TABLE #{dynamic_schema}.#{referencing_table}_default
        PARTITION OF #{referencing_table} DEFAULT;
    SQL
  end
end
