# frozen_string_literal: true

module PartitioningHelpers
  def expect_table_partitioned_by(table, columns, part_type: :range)
    columns_with_part_type = columns.map { |c| [part_type.to_s, c] }
    actual_columns = find_partitioned_columns(table)

    expect(columns_with_part_type).to match_array(actual_columns)
  end

  def expect_range_partition_of(partition_name, table_name, min_value, max_value)
    definition = find_partition_definition(partition_name)

    expect(definition).not_to be_nil
    expect(definition['base_table']).to eq(table_name.to_s)
    expect(definition['condition']).to eq("FOR VALUES FROM (#{min_value}) TO (#{max_value})")
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

  def find_partition_definition(partition)
    connection.select_one(<<~SQL)
      select
        parent_class.relname as base_table,
        pg_get_expr(pg_class.relpartbound, inhrelid) as condition
      from pg_class
      inner join pg_inherits i on pg_class.oid = inhrelid
      inner join pg_class parent_class on parent_class.oid = inhparent
      where pg_class.relname = '#{partition}' and pg_class.relispartition;
    SQL
  end
end
