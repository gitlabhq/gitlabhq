# frozen_string_literal: true

module Database
  module PartitioningHelpers
    def expect_table_partitioned_by(table, columns, part_type: :range)
      columns_with_part_type = columns.map { |c| [part_type.to_s, c] }
      actual_columns = find_partitioned_columns(table)

      expect(columns_with_part_type).to match_array(actual_columns)
    end

    def expect_range_partition_of(partition_name, table_name, min_value, max_value)
      definition = find_partition_definition(partition_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)

      expect(definition).not_to be_nil
      expect(definition['base_table']).to eq(table_name.to_s)
      expect(definition['condition']).to eq("FOR VALUES FROM (#{min_value}) TO (#{max_value})")
    end

    def expect_list_partition_of(partition_name, table_name, partition, schema: :public)
      definition = find_partition_definition(partition_name, schema: schema)

      expect(definition).not_to be_nil
      expect(definition['base_table']).to eq(table_name.to_s)
      expect(definition['condition']).to eq("FOR VALUES IN (#{partition})")
    end

    def expect_total_partitions(table_name, count, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)
      partitions = find_partitions(table_name, schema: schema)

      expect(partitions.size).to eq(count)
    end

    def expect_range_partitions_for(table_name, partitions)
      partitions.each do |suffix, (min_value, max_value)|
        partition_name = "#{table_name}_#{suffix}"
        expect_range_partition_of(partition_name, table_name, min_value, max_value)
      end

      expect_total_partitions(table_name, partitions.size, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)
    end

    def expect_hash_partition_of(partition_name, table_name, modulus, remainder)
      definition = find_partition_definition(partition_name, schema: Gitlab::Database::STATIC_PARTITIONS_SCHEMA)

      expect(definition).not_to be_nil
      expect(definition['base_table']).to eq(table_name.to_s)
      expect(definition['condition']).to eq("FOR VALUES WITH (modulus #{modulus}, remainder #{remainder})")
    end

    def expect_list_partitions_for(table_name, partitions, partition_name_format: nil, schema: :public)
      partition_name_format ||= "%{table_name}_%{partition_name}"

      partitions.each do |partition_name, partition|
        partition_name = format(partition_name_format, table_name: table_name, partition_name: partition_name)
        expect_list_partition_of(partition_name, table_name, partition, schema: schema)
      end

      expect_total_partitions(table_name, partitions.size, schema: schema)
    end

    private

    def find_partitioned_columns(table)
      connection.select_rows(<<~SQL)
        select
          case partstrat
          when 'l' then 'list'
          when 'r' then 'range'
          when 'h' then 'hash'
          end as partstrat,
          cols.column_name
        from (
          select partrelid, partstrat, unnest(partattrs) as col_pos
          from pg_partitioned_table
        ) pg_part
        inner join pg_class
        on pg_part.partrelid = pg_class.oid
        inner join information_schema.columns cols
        on cols.table_name = pg_class.relname
        and cols.ordinal_position = pg_part.col_pos
        where pg_class.relname = '#{table}';
      SQL
    end

    def find_partition_definition(partition, schema:)
      connection.select_one(<<~SQL)
        select
          parent_class.relname as base_table,
          pg_get_expr(pg_class.relpartbound, inhrelid) as condition
        from pg_class
        inner join pg_inherits i on pg_class.oid = inhrelid
        inner join pg_class parent_class on parent_class.oid = inhparent
        inner join pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        where pg_namespace.nspname = '#{schema}'
          and pg_class.relname = '#{partition}'
          and pg_class.relispartition
      SQL
    end

    def find_partitions(partition, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA, conn: connection)
      conn.select_rows(<<~SQL)
        select
          pg_class.relname
        from pg_class
        inner join pg_inherits i on pg_class.oid = inhrelid
        inner join pg_class parent_class on parent_class.oid = inhparent
        inner join pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        where pg_namespace.nspname = '#{schema}'
          and parent_class.relname = '#{partition}'
          and pg_class.relispartition
      SQL
    end
  end
end
