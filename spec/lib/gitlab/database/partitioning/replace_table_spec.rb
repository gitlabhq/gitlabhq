# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::ReplaceTable, '#perform' do
  include Database::TableSchemaHelpers

  subject(:replace_table) do
    described_class.new(connection, original_table, replacement_table, archived_table, 'id').perform
  end

  let(:original_table) { '_test_original_table' }
  let(:replacement_table) { '_test_replacement_table' }
  let(:archived_table) { '_test_archived_table' }

  let(:original_sequence) { "#{original_table}_id_seq" }

  let(:original_primary_key) { "#{original_table}_pkey" }
  let(:replacement_primary_key) { "#{replacement_table}_pkey" }
  let(:archived_primary_key) { "#{archived_table}_pkey" }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE #{original_table} (
        id serial NOT NULL PRIMARY KEY,
        original_column text NOT NULL,
        created_at timestamptz NOT NULL);

      CREATE TABLE #{replacement_table} (
        id int NOT NULL,
        replacement_column text NOT NULL,
        created_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at))
        PARTITION BY RANGE (created_at);
    SQL
  end

  it 'replaces the current table, archiving the old' do
    expect_table_to_be_replaced { replace_table }
  end

  it 'transfers the primary key sequence to the replacement table' do
    expect(sequence_owned_by(original_table, 'id')).to eq(original_sequence)
    expect(default_expression_for(original_table, 'id')).to eq("nextval('#{original_sequence}'::regclass)")

    expect(sequence_owned_by(replacement_table, 'id')).to be_nil
    expect(default_expression_for(replacement_table, 'id')).to be_nil

    expect_table_to_be_replaced { replace_table }

    expect(sequence_owned_by(original_table, 'id')).to eq(original_sequence)
    expect(default_expression_for(original_table, 'id')).to eq("nextval('#{original_sequence}'::regclass)")
    expect(sequence_owned_by(archived_table, 'id')).to be_nil
    expect(default_expression_for(archived_table, 'id')).to be_nil
  end

  it 'renames the primary key constraints to match the new table names' do
    expect_primary_keys_after_tables([original_table, replacement_table])

    expect_table_to_be_replaced { replace_table }

    expect_primary_keys_after_tables([original_table, archived_table])
  end

  context 'when the table has partitions' do
    before do
      connection.execute(<<~SQL)
        CREATE TABLE gitlab_partitions_dynamic.#{replacement_table}_202001 PARTITION OF #{replacement_table}
        FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

        CREATE TABLE gitlab_partitions_dynamic.#{replacement_table}_202002 PARTITION OF #{replacement_table}
        FOR VALUES FROM ('2020-02-01') TO ('2020-03-01');
      SQL
    end

    it 'renames the partitions to match the new table name' do
      expect(partitions_for_parent_table(original_table).count).to eq(0)
      expect(partitions_for_parent_table(replacement_table).count).to eq(2)

      expect_table_to_be_replaced { replace_table }

      expect(partitions_for_parent_table(archived_table).count).to eq(0)

      partitions = partitions_for_parent_table(original_table).all

      expect(partitions.size).to eq(2)

      expect(partitions[0]).to have_attributes(
        identifier: "gitlab_partitions_dynamic.#{original_table}_202001",
        condition: "FOR VALUES FROM ('2020-01-01 00:00:00+00') TO ('2020-02-01 00:00:00+00')")

      expect(partitions[1]).to have_attributes(
        identifier: "gitlab_partitions_dynamic.#{original_table}_202002",
        condition: "FOR VALUES FROM ('2020-02-01 00:00:00+00') TO ('2020-03-01 00:00:00+00')")
    end

    it 'renames the primary key constraints to match the new partition names' do
      original_partitions = ["#{replacement_table}_202001", "#{replacement_table}_202002"]
      expect_primary_keys_after_tables(original_partitions, schema: 'gitlab_partitions_dynamic')

      expect_table_to_be_replaced { replace_table }

      renamed_partitions = ["#{original_table}_202001", "#{original_table}_202002"]
      expect_primary_keys_after_tables(renamed_partitions, schema: 'gitlab_partitions_dynamic')
    end
  end

  def partitions_for_parent_table(table)
    Gitlab::Database::PostgresPartition.for_parent_table(table)
  end

  def expect_table_to_be_replaced(&block)
    super(original_table: original_table, replacement_table: replacement_table, archived_table: archived_table, &block)
  end
end
