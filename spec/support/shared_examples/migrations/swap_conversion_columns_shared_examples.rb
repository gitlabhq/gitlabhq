# frozen_string_literal: true

COLUMN_OPTIONS_TO_REMAIN =
  %i[
    null
    serial?
    collation
    default
    default_function
  ].freeze

SQL_TYPE_OPTIONS_TO_REMAIN =
  %i[
    precision
    scale
  ].freeze

SQL_TYPE_OPTIONS_TO_CHANGE =
  %i[
    type
    sql_type
    limit
  ].freeze

RSpec.shared_examples 'swap conversion columns' do |table_name:, from:, to:, before_type: nil, after_type: nil|
  it 'correctly swaps conversion columns' do
    before_from_column = before_to_column = before_indexes = before_foreign_keys = nil
    after_from_column = after_to_column = after_indexes = after_foreign_keys = nil

    expect_column_type_is_changed_but_others_remain_unchanged = -> do
      # SQL type is changed
      SQL_TYPE_OPTIONS_TO_CHANGE.each do |sql_type_option|
        expect(
          after_from_column.sql_type_metadata.public_send(sql_type_option)
        ).to eq(
          before_to_column.sql_type_metadata.public_send(sql_type_option)
        )

        expect(
          after_to_column.sql_type_metadata.public_send(sql_type_option)
        ).to eq(
          before_from_column.sql_type_metadata.public_send(sql_type_option)
        )
      end

      # column metadata remains unchanged
      COLUMN_OPTIONS_TO_REMAIN.each do |column_option|
        expect(
          after_from_column.public_send(column_option)
        ).to eq(
          before_from_column.public_send(column_option)
        )

        expect(
          after_to_column.public_send(column_option)
        ).to eq(
          before_to_column.public_send(column_option)
        )
      end

      SQL_TYPE_OPTIONS_TO_REMAIN.each do |sql_type_option|
        expect(
          after_from_column.sql_type_metadata.public_send(sql_type_option)
        ).to eq(
          before_from_column.sql_type_metadata.public_send(sql_type_option)
        )

        expect(
          after_to_column.sql_type_metadata.public_send(sql_type_option)
        ).to eq(
          before_to_column.sql_type_metadata.public_send(sql_type_option)
        )
      end

      # indexes remain unchanged
      expect(before_indexes).to eq(after_indexes)

      # foreign keys remain unchanged
      expect(before_foreign_keys).to eq(after_foreign_keys)
    end

    find_column_by = ->(name) do
      active_record_base.connection.columns(table_name).find { |c| c.name == name.to_s }
    end

    find_indexes = -> do
      active_record_base.connection.indexes(table_name)
    end

    find_foreign_keys = -> do
      Gitlab::Database::PostgresForeignKey.by_constrained_table_name(table_name)
    end

    reversible_migration do |migration|
      migration.before -> {
        before_from_column = find_column_by.call(from)
        before_to_column = find_column_by.call(to)
        before_indexes = find_indexes
        before_foreign_keys = find_foreign_keys

        next if after_from_column.nil?

        # For migrate down
        expect(before_from_column.sql_type_metadata.sql_type).to eq(before_type) if before_type
        expect_column_type_is_changed_but_others_remain_unchanged.call
      }

      migration.after -> {
        after_from_column = find_column_by.call(from)
        after_to_column = find_column_by.call(to)
        after_indexes = find_indexes
        after_foreign_keys = find_foreign_keys

        expect(after_from_column.sql_type_metadata.sql_type).to eq(after_type) if after_type
        expect_column_type_is_changed_but_others_remain_unchanged.call
      }
    end
  end
end
