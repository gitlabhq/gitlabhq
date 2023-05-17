# frozen_string_literal: true

module Database
  module DatabaseHelpers
    # In order to directly work with views using factories,
    # we can swapout the view for a table of identical structure.
    def swapout_view_for_table(view, connection:, schema: nil)
      table_name = [schema, "_test_#{view}_copy"].compact.join('.')

      connection.execute(<<~SQL.squish)
        CREATE TABLE #{table_name} (LIKE #{view});
        DROP VIEW #{view};
        ALTER TABLE #{table_name} RENAME TO #{view};
      SQL
    end

    # Set statement timeout temporarily.
    # Useful when testing query timeouts.
    #
    # Note that this method cannot restore the timeout if a query
    # was canceled due to e.g. a statement timeout.
    # Refrain from using this transaction in these situations.
    #
    # @param timeout - Statement timeout in seconds
    #
    # Example:
    #
    #   with_statement_timeout(0.1) do
    #     model.select('pg_sleep(0.11)')
    #   end
    def with_statement_timeout(timeout, connection:)
      # Force a positive value and a minimum of 1ms for very small values.
      timeout = (timeout * 1000).abs.ceil

      raise ArgumentError, 'Using a timeout of `0` means to disable statement timeout.' if timeout == 0

      previous_timeout = connection.select_value('SHOW statement_timeout')

      connection.execute(format(%(SET LOCAL statement_timeout = '%s'), timeout))

      yield
    ensure
      begin
        connection.execute(format(%(SET LOCAL statement_timeout = '%s'), previous_timeout))
      rescue ActiveRecord::StatementInvalid
        # After a transaction was canceled/aborted due to e.g. a statement
        # timeout commands are ignored and will raise in PG::InFailedSqlTransaction.
        # We can safely ignore this error because the statement timeout was set
        # for the currrent transaction which will be closed anyway.
      end
    end
  end
end
