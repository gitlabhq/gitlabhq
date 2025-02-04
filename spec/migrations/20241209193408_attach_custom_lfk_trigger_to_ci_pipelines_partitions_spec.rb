# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AttachCustomLfkTriggerToCiPipelinesPartitions, feature_category: :continuous_integration do
  let(:connection) { described_class.new.connection }
  let(:new_partition) { '_test_partition_01' }
  let(:dynamic_partitions_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }
  let(:old_function_name) { 'insert_into_loose_foreign_keys_deleted_records' }
  let(:new_function_name) { 'insert_into_loose_foreign_keys_deleted_records_override_table' }

  RSpec.shared_examples 'migration tests' do |table_name, schema, trigger_existed|
    it 'attaches the new loose foreign key partitions function has a trigger handler to the table' do
      reversible_migration do |migration|
        migration.before -> {
          installed_triggers = lfk_triggers_on_table(connection, table_name, schema)

          expected_triggers = if trigger_existed
                                [
                                  {
                                    trigger_name: "#{table_name}_loose_fk_trigger",
                                    arguments_count: 0,
                                    function_name: old_function_name
                                  }
                                ]
                              else
                                []
                              end

          expect(installed_triggers).to eq(expected_triggers)
        }

        migration.after -> {
          installed_triggers = lfk_triggers_on_table(connection, table_name, schema)

          expect(installed_triggers).to eq(
            [
              {
                trigger_name: "#{table_name}_loose_fk_trigger",
                arguments_count: 1,
                function_name: new_function_name
              }
            ]
          )
        }
      end
    end
  end

  context 'with existing partitioned tables' do
    include_examples 'migration tests', 'p_ci_pipelines', 'public', true
  end

  context 'with existing partitions' do
    include_examples 'migration tests', 'ci_pipelines', 'public', true
  end

  context 'with new partitions' do
    before do
      connection.execute("DROP TABLE IF EXISTS #{dynamic_partitions_schema}.#{new_partition} CASCADE")
      connection.execute(<<~SQL)
          CREATE TABLE #{dynamic_partitions_schema}.#{new_partition} PARTITION OF p_ci_pipelines
          FOR VALUES IN (99)
      SQL
    end

    after do
      connection.execute("DROP TABLE IF EXISTS #{dynamic_partitions_schema}.#{new_partition} CASCADE")
    end

    include_examples(
      'migration tests',
      '_test_partition_01',
      Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA,
      false
    )
  end

  def lfk_triggers_on_table(connection, table_name, schema)
    items = connection.select_rows(<<~SQL.squish)
      SELECT tgname,
          tgnargs as arguments_count,
          proc.proname AS function
      FROM pg_catalog.pg_trigger trgr
        INNER JOIN pg_catalog.pg_class rel
          ON trgr.tgrelid = rel.oid
        INNER JOIN pg_catalog.pg_proc proc
          ON proc.oid = trgr.tgfoid
        INNER JOIN pg_catalog.pg_namespace nsp
          ON nsp.oid = rel.relnamespace
      WHERE nsp.nspname = #{connection.quote(schema)}
        AND rel.relname = #{connection.quote(table_name)}
        AND tgname ILIKE '%_loose_fk_trigger'
    SQL

    items.map { |item| { trigger_name: item[0], arguments_count: item[1], function_name: item[2] } }
  end
end
