# frozen_string_literal: true

module Quality
  # Reports whether the given tables hold rows once development fixtures have run, and how much
  # variation those rows carry. Used by the `run-dev-fixtures` CI job to flag new tables that
  # nothing seeds, which would otherwise leave migrations touching them untested by
  # `db:migrate:multi-version-upgrade`.
  class FixtureCoverage
    Finding = Struct.new(:table, :rows, :nullable_columns, :columns_never_null, keyword_init: true) do
      def unseeded?
        rows == 0
      end

      # One row cannot hold both a null and a value for the same column, so a later NOT NULL
      # migration has nothing to trip on.
      def single_row?
        rows == 1
      end

      def no_null_variation?
        !unseeded? && nullable_columns > 0 && columns_never_null == nullable_columns
      end

      def summary
        if unseeded?
          return "no rows after seeding. Add a fixture in db/fixtures/development/ so that " \
            "migrations touching it are exercised by db:migrate:multi-version-upgrade"
        end

        notes = []
        notes << "only one row, so a later NOT NULL migration has no null to trip on" if single_row?
        notes << "none of its #{nullable_columns} nullable columns ever holds a null" if no_null_variation?

        ["#{rows} row(s)", *notes].join(" - ")
      end
    end

    def initialize(tables, connection:)
      @tables = tables
      @connection = connection
    end

    def findings
      tables.select { |table| connection.table_exists?(table) }.map { |table| examine(table) }
    end

    private

    attr_reader :tables, :connection

    def examine(table)
      nullable = nullable_columns(table)
      counts = column_counts(table, nullable)
      rows = counts.fetch('row_count').to_i

      Finding.new(
        table: table,
        rows: rows,
        nullable_columns: nullable.size,
        columns_never_null: nullable.each_index.count { |index| counts["c#{index}"].to_i == rows }
      )
    end

    def nullable_columns(table)
      connection.columns(table).select(&:null).map(&:name)
    end

    # `count(column)` ignores nulls, so a column whose non-null count equals the row count never
    # holds one. Gathered in a single query to stay cheap on wide tables. The unbounded `count(*)`
    # is safe because this only ever runs over tables a merge request just added, in a test database.
    def column_counts(table, nullable)
      selects = ['count(*) AS row_count']
      nullable.each_with_index do |column, index|
        selects << "count(#{connection.quote_column_name(column)}) AS c#{index}"
      end

      connection.select_one("SELECT #{selects.join(', ')} FROM #{connection.quote_table_name(table)}")
    end
  end
end
