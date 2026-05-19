# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::DynamicHelpers, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:dynamic_schema) { :gitlab_partitions_dynamic }
  let(:table_name) { :_test_partition }
  let(:parent_table_name) { :_test_partitioned_table }
  let(:partition_values) { [100, 101] }
  let(:table_identifier) { "#{dynamic_schema}.#{table_name}" }

  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    connection.execute(<<~SQL)
      CREATE TABLE #{parent_table_name} (
        id bigint NOT NULL,
        partition_id bigint NOT NULL
      ) PARTITION BY LIST (partition_id);

      CREATE TABLE #{table_name} PARTITION OF #{parent_table_name}
        FOR VALUES IN (#{partition_values.join(', ')});
    SQL
  end

  describe '#move_table_to_dynamic_schema' do
    it 'moves the table into the dynamic schema' do
      expect(connection.table_exists?(table_name)).to be(true)

      migration.move_table_to_dynamic_schema(table_name)

      expect(connection.table_exists?(table_name)).to be(false)
      expect(connection.table_exists?(table_identifier)).to be(true)
    end
  end

  describe '#move_table_from_dynamic_schema' do
    context 'when the table exists in the dynamic schema' do
      before do
        migration.move_table_to_dynamic_schema(table_name)
      end

      it 'moves the table back to the current schema' do
        expect(connection.table_exists?(table_identifier)).to be(true)

        migration.move_table_from_dynamic_schema(
          table_name, partition_values: partition_values, parent_table_name: parent_table_name
        )

        expect(connection.table_exists?(table_name)).to be(true)
        expect(connection.table_exists?(table_identifier)).to be(false)
      end
    end

    context 'when the table does not exist in the dynamic schema' do
      before do
        migration.move_table_to_dynamic_schema(table_name)

        connection.execute(<<~SQL)
          ALTER TABLE #{parent_table_name} DETACH PARTITION #{table_identifier};
          DROP TABLE IF EXISTS #{table_identifier};
        SQL

        partition_values.each do |value|
          connection.execute(<<~SQL)
            CREATE TABLE IF NOT EXISTS #{dynamic_schema}.#{table_name}_#{value}
              PARTITION OF #{parent_table_name} FOR VALUES IN (#{value});
          SQL
        end
      end

      it 'removes dynamic partitions and recreates the table in the current schema' do
        expect(connection.table_exists?(table_identifier)).to be(false)

        migration.move_table_from_dynamic_schema(
          table_name, partition_values: partition_values, parent_table_name: parent_table_name
        )

        expect(connection.table_exists?(table_name)).to be(true)

        partition_values.each do |value|
          expect(connection.table_exists?("#{dynamic_schema}.#{table_name}_#{value}")).to be(false)
        end
      end
    end
  end
end
