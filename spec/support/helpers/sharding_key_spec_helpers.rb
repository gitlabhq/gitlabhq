# frozen_string_literal: true

module ShardingKeySpecHelpers
  def not_nullable?(table_name, column_name)
    sql = <<~SQL
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND
    table_name = '#{table_name}' AND
    column_name = '#{column_name}' AND
    is_nullable = 'NO'
    SQL

    result = ApplicationRecord.connection.execute(sql)

    result.count > 0
  end

  def has_null_check_constraint?(table_name, column_name)
    # This is a heuristic query to look for all check constraints on the table and see if any of them contain a clause
    # column IS NOT NULL. This is to match tables that will have multiple sharding keys where either of them can be not
    # null. Such cases may look like:
    #    (project_id IS NOT NULL) OR (group_id IS NOT NULL)
    # It's possible that this will sometimes incorrectly find a check constraint that isn't exactly as strict as we want
    # but it should be pretty unlikely.
    sql = <<~SQL
    SELECT 1
    FROM pg_constraint
    INNER JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
    WHERE pg_class.relname = '#{table_name}'
    AND contype = 'c'
    AND (
      pg_get_constraintdef(pg_constraint.oid) ILIKE '%#{column_name} IS NOT NULL%'
      OR
      pg_get_constraintdef(pg_constraint.oid)  ~ '.*num_nonnulls.*#{column_name}.*(= 1|> 0).*'
    )
    SQL

    result = ApplicationRecord.connection.execute(sql)

    result.count > 0
  end

  def has_multi_column_null_check_constraint?(table_name, column_names)
    # This regex searches for constraints that ensure at least one of a set of columns is NOT NULL.
    # It assumes the constraint was created using the #add_multi_column_not_null_constraint helper, which also
    # sorts the list of columns. The constraint for `events` does not follow this convention hence the exception.
    regex = {
      events: '\\ACHECK \\(\\(\\(group_id IS NOT NULL\\) OR \\(project_id IS NOT NULL\\) ' \
        'OR \\(personal_namespace_id IS NOT NULL\\)\\)\\)\\Z'
    }.fetch(
      table_name.to_sym,
      "\\ACHECK \\(\\(num_nonnulls\\(#{column_names.sort.join(', ')}\\) (> [0-9]{1,}|>?= [1-9]{1,})\\)\\)\\Z"
    )

    sql = <<~SQL
    SELECT 1
    FROM pg_constraint
    INNER JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
    WHERE pg_class.relname = '#{table_name}'
    AND contype = 'c'
    AND pg_get_constraintdef(pg_constraint.oid) ~ '#{regex}'
    SQL

    result = ApplicationRecord.connection.execute(sql)

    result.count > 0
  end

  def referenced_foreign_keys(to_table_name)
    ::Gitlab::Database::PostgresForeignKey.by_referenced_table_name(to_table_name)
  end

  def referenced_loose_foreign_keys(to_table_name)
    ::Gitlab::Database::LooseForeignKeys.definitions.select do |d|
      d.to_table == to_table_name
    end
  end

  def has_foreign_key?(from_table_name, column_name, to_table_name: nil, foreign_key_name: nil)
    where_clause = {
      constrained_table_name: from_table_name,
      constrained_columns: [column_name]
    }

    where_clause[:referenced_table_name] = to_table_name if to_table_name
    if foreign_key_name
      where_clause[:name] = foreign_key_name
      where_clause.delete(:constrained_columns)
    end

    fk = ::Gitlab::Database::PostgresForeignKey.where(where_clause).first

    lfk = ::Gitlab::Database::LooseForeignKeys.definitions.find do |d|
      d.from_table == from_table_name &&
        (to_table_name.nil? || d.to_table == to_table_name) &&
        d.options[:column] == column_name
    end

    fk.present? || lfk.present?
  end

  def column_exists?(table_name, column_name)
    sql = <<~SQL
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND
    table_name = '#{table_name}' AND
    column_name = '#{column_name}';
    SQL

    result = ApplicationRecord.connection.execute(sql)

    result.count > 0
  end
end
