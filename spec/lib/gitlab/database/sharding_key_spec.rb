# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables missing sharding_key', feature_category: :cell do
  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_sharding_key) do
    [
      'abuse_report_assignees', # https://gitlab.com/gitlab-org/gitlab/-/issues/432365
      'sbom_occurrences_vulnerabilities' # https://gitlab.com/gitlab-org/gitlab/-/issues/432900
    ]
  end

  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_not_null) do
    [
      'labels.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/434356
      'labels.group_id' # https://gitlab.com/gitlab-org/gitlab/-/issues/434356
    ]
  end

  let(:starting_from_milestone) { 16.6 }

  let(:allowed_sharding_key_referenced_tables) { %w[projects namespaces organizations] }

  it 'requires a sharding_key for all cell-local tables, after milestone 16.6', :aggregate_failures do
    tables_missing_sharding_key(starting_from_milestone: starting_from_milestone).each do |table_name|
      expect(allowed_to_be_missing_sharding_key).to include(table_name), error_message(table_name)
    end
  end

  it 'ensures all sharding_key columns exist and reference projects, namespaces or organizations',
    :aggregate_failures do
    all_tables_to_sharding_key.each do |table_name, sharding_key|
      sharding_key.each do |column_name, referenced_table_name|
        expect(column_exists?(table_name, column_name)).to eq(true),
          "Could not find sharding key column #{table_name}.#{column_name}"
        expect(referenced_table_name).to be_in(allowed_sharding_key_referenced_tables)
      end
    end
  end

  it 'ensures all sharding_key columns are not nullable or have a not null check constraint',
    :aggregate_failures do
    all_tables_to_sharding_key.each do |table_name, sharding_key|
      sharding_key.each do |column_name, _|
        not_nullable = not_nullable?(table_name, column_name)
        has_null_check_constraint = has_null_check_constraint?(table_name, column_name)

        if allowed_to_be_missing_not_null.include?("#{table_name}.#{column_name}")
          expect(not_nullable || has_null_check_constraint).to eq(false),
            "You must remove `#{table_name}.#{column_name}` from allowed_to_be_missing_not_null" \
            "since it now has a valid constraint."
        else
          expect(not_nullable || has_null_check_constraint).to eq(true),
            "Missing a not null constraint for `#{table_name}.#{column_name}` . " \
            "All sharding keys must be not nullable or have a NOT NULL check constraint"
        end
      end
    end
  end

  it 'only allows `allowed_to_be_missing_sharding_key` to include tables that are missing a sharding_key',
    :aggregate_failures do
    allowed_to_be_missing_sharding_key.each do |exempted_table|
      expect(tables_missing_sharding_key(starting_from_milestone: starting_from_milestone)).to include(exempted_table),
        "`#{exempted_table}` is not missing a `sharding_key`. " \
        "You must remove this table from the `allowed_to_be_missing_sharding_key` list."
    end
  end

  private

  def error_message(table_name)
    <<~HEREDOC
      The table `#{table_name}` is missing a `sharding_key` in the `db/docs` YML file.
      Starting from GitLab #{starting_from_milestone}, we expect all new tables to define a `sharding_key`.

      To choose an appropriate sharding_key for this table please refer
      to our guidelines at https://docs.gitlab.com/ee/development/database/multiple_databases.html#defining-a-sharding-key-for-all-cell-local-tables, or consult with the Tenant Scale group.
    HEREDOC
  end

  def tables_missing_sharding_key(starting_from_milestone:)
    ::Gitlab::Database::Dictionary.entries.select do |entry|
      entry.sharding_key.blank? &&
        entry.milestone.to_f >= starting_from_milestone &&
        ::Gitlab::Database::GitlabSchema.cell_local?(entry.gitlab_schema)
    end.map(&:table_name)
  end

  def all_tables_to_sharding_key
    entries_with_sharding_key = ::Gitlab::Database::Dictionary.entries.select do |entry|
      entry.sharding_key.present? &&
        ::Gitlab::Database::GitlabSchema.cell_local?(entry.gitlab_schema)
    end

    entries_with_sharding_key.to_h do |entry|
      [entry.table_name, entry.sharding_key]
    end
  end

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
    AND pg_get_constraintdef(pg_constraint.oid) ILIKE '%#{column_name} IS NOT NULL%'
    SQL

    result = ApplicationRecord.connection.execute(sql)

    result.count > 0
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
