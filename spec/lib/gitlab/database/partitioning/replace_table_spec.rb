# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::ReplaceTable, '#perform' do
  include TableSchemaHelpers

  subject(:replace_table) { described_class.new(original_table, replacement_table, archived_table, 'id').perform }

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

      CREATE TABLE #{replacement_table}_202001 PARTITION OF #{replacement_table}
      FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');
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
    expect(primary_key_constraint_name(original_table)).to eq(original_primary_key)
    expect(primary_key_constraint_name(replacement_table)).to eq(replacement_primary_key)

    expect_table_to_be_replaced { replace_table }

    expect(primary_key_constraint_name(original_table)).to eq(original_primary_key)
    expect(primary_key_constraint_name(archived_table)).to eq(archived_primary_key)
  end

  def expect_table_to_be_replaced(&block)
    super(original_table: original_table, replacement_table: replacement_table, archived_table: archived_table, &block)
  end
end
