# frozen_string_literal: true

module Database
  module TableSchemaHelpers
    def connection
      # We use ActiveRecord::Base.connection here because this is mainly used for database migrations
      # where we override the connection on ActiveRecord::Base.connection
      ActiveRecord::Base.connection # rubocop:disable Database/MultipleDatabases
    end

    def expect_table_to_be_replaced(original_table:, replacement_table:, archived_table:)
      original_oid = table_oid(original_table)
      replacement_oid = table_oid(replacement_table)

      yield

      expect(table_oid(original_table)).to eq(replacement_oid)
      expect(table_oid(archived_table)).to eq(original_oid)
      expect(table_oid(replacement_table)).to be_nil
    end

    def expect_table_columns_to_match(expected_column_attributes, table_name)
      expect(connection.table_exists?(table_name)).to eq(true)

      actual_columns = connection.columns(table_name)
      expect(actual_columns.size).to eq(column_attributes.size)

      column_attributes.each_with_index do |attributes, i|
        actual_column = actual_columns[i]

        attributes.each do |name, value|
          actual_value = actual_column.public_send(name)
          message = "expected #{actual_column.name}.#{name} to be #{value}, but got #{actual_value}"

          expect(actual_value).to eq(value), message
        end
      end
    end

    def expect_index_to_exist(name, schema: nil)
      expect(index_exists_by_name(name, schema: schema)).to eq(true)
    end

    def expect_index_not_to_exist(name, schema: nil)
      expect(index_exists_by_name(name, schema: schema)).to be_nil
    end

    def expect_foreign_key_to_exist(table_name, name, schema: nil)
      expect(foreign_key_exists_by_name(table_name, name, schema: schema)).to eq(true)
    end

    def expect_foreign_key_not_to_exist(table_name, name, schema: nil)
      expect(foreign_key_exists_by_name(table_name, name, schema: schema)).to be_nil
    end

    def expect_check_constraint(table_name, name, definition, schema: nil)
      expect(check_constraint_definition(table_name, name, schema: schema)).to eq("CHECK ((#{definition}))")
    end

    def expect_primary_keys_after_tables(tables, schema: nil)
      tables.each do |table|
        primary_key = primary_key_constraint_name(table, schema: schema)

        expect(primary_key).to eq("#{table}_pkey")
      end
    end

    def table_oid(name)
      connection.select_value(<<~SQL)
        SELECT oid
        FROM pg_catalog.pg_class
        WHERE relname = '#{name}'
      SQL
    end

    def table_type(name)
      connection.select_value(<<~SQL)
        SELECT
          CASE class.relkind
          WHEN 'r' THEN 'normal'
          WHEN 'p' THEN 'partitioned'
          ELSE 'other'
          END as table_type
        FROM pg_catalog.pg_class class
        WHERE class.relname = '#{name}'
      SQL
    end

    def sequence_owned_by(table_name, column_name)
      connection.select_value(<<~SQL)
        SELECT
          sequence.relname as name
        FROM pg_catalog.pg_class as sequence
        INNER JOIN pg_catalog.pg_depend depend
          ON depend.objid = sequence.oid
        INNER JOIN pg_catalog.pg_class class
          ON class.oid = depend.refobjid
        INNER JOIN pg_catalog.pg_attribute attribute
          ON attribute.attnum = depend.refobjsubid
          AND attribute.attrelid = depend.refobjid
        WHERE class.relname = '#{table_name}'
          AND attribute.attname = '#{column_name}'
      SQL
    end

    def default_expression_for(table_name, column_name)
      connection.select_value(<<~SQL)
        SELECT
          pg_get_expr(attrdef.adbin, attrdef.adrelid) AS default_value
        FROM pg_catalog.pg_attribute attribute
        INNER JOIN pg_catalog.pg_attrdef attrdef
          ON attribute.attrelid = attrdef.adrelid
          AND attribute.attnum = attrdef.adnum
        WHERE attribute.attrelid = '#{table_name}'::regclass
          AND attribute.attname = '#{column_name}'
      SQL
    end

    def primary_key_constraint_name(table_name, schema: nil)
      table_name = schema ? "#{schema}.#{table_name}" : table_name

      connection.select_value(<<~SQL)
        SELECT
          conname AS constraint_name
        FROM pg_catalog.pg_constraint
        WHERE pg_constraint.conrelid = '#{table_name}'::regclass
          AND pg_constraint.contype = 'p'
      SQL
    end

    def index_exists_by_name(index, schema: nil)
      schema = schema ? "'#{schema}'" : 'current_schema'

      connection.select_value(<<~SQL)
        SELECT true
        FROM pg_catalog.pg_index i
        INNER JOIN pg_catalog.pg_class c
          ON c.oid = i.indexrelid
        INNER JOIN pg_catalog.pg_namespace n
          ON c.relnamespace = n.oid
        WHERE c.relname = '#{index}'
          AND n.nspname = #{schema}
      SQL
    end

    def foreign_key_exists_by_name(table_name, foreign_key_name, schema: nil)
      table_name = schema ? "#{schema}.#{table_name}" : table_name

      connection.select_value(<<~SQL)
        SELECT true
        FROM pg_catalog.pg_constraint
        WHERE pg_constraint.conrelid = '#{table_name}'::regclass
          AND pg_constraint.contype = 'f'
          AND pg_constraint.conname = '#{foreign_key_name}'
      SQL
    end

    def foreign_key_by_name(source, name)
      connection.foreign_keys(source).find do |key|
        key.name == name.to_s
      end
    end

    def index_by_name(table, name, partitioned_table: nil)
      if partitioned_table
        partitioned_index = index_by_name(partitioned_table, name)
        return unless partitioned_index

        connection.indexes(table).find do |key|
          key.columns == partitioned_index.columns
        end
      else
        connection.indexes(table).find do |key|
          key.name == name.to_s
        end
      end
    end

    def check_constraint_definition(table_name, constraint_name, schema: nil)
      table_name = schema ? "#{schema}.#{table_name}" : table_name

      connection.select_value(<<~SQL)
        SELECT
          pg_get_constraintdef(oid) AS constraint_definition
        FROM pg_catalog.pg_constraint
        WHERE pg_constraint.conrelid = '#{table_name}'::regclass
          AND pg_constraint.contype = 'c'
          AND pg_constraint.conname = '#{constraint_name}'
      SQL
    end
  end
end
